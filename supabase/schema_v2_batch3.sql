-- =====================================================================
-- Shifa Care: Batch 3 migration - "Fully booked today"
-- Run in the Supabase SQL Editor AFTER schema_v2_batch1.sql.
-- A doctor can stop NEW bookings for today only, while still seeing the
-- patients already in the queue. Stored as a DATE, so it can never carry
-- over and silently block tomorrow: no daily reset needed.
-- =====================================================================

alter table public.doctors
  add column if not exists fully_booked_until date;

create or replace function public.set_fully_booked_today(p_doctor_id uuid, p_value boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_today date := (now() at time zone 'Asia/Karachi')::date;
begin
  update public.doctors
     set fully_booked_until = case when p_value then v_today else null end
   where id = p_doctor_id and user_id = auth.uid();

  if not found then
    raise exception 'Only the assigned doctor can change this';
  end if;
end;
$$;

revoke all on function public.set_fully_booked_today(uuid, boolean) from public, anon;
grant execute on function public.set_fully_booked_today(uuid, boolean) to authenticated;

-- ---- book_appointment: now also blocks a "fully booked" day ----------
create or replace function public.book_appointment(
  p_doctor_id uuid,
  p_date      date,
  p_reason    text default null
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid      uuid := auth.uid();
  v_today    date := (now() at time zone 'Asia/Karachi')::date;
  v_name     text;
  v_token    int;
  v_row      public.appointments;
  v_on_leave boolean;
  v_fully_booked date;
begin
  if v_uid is null then
    raise exception 'Please sign in first';
  end if;
  if p_date < v_today then
    raise exception 'Please choose today or a future date';
  end if;
  if p_date > v_today + 30 then
    raise exception 'Bookings are open for the next 30 days only';
  end if;

  select on_leave, fully_booked_until into v_on_leave, v_fully_booked
    from public.doctors where id = p_doctor_id;
  if coalesce(v_on_leave, false) then
    raise exception 'This doctor is currently on leave. Please choose another doctor.';
  end if;
  if v_fully_booked is not null and v_fully_booked = p_date then
    raise exception 'This doctor is fully booked for that day. Please choose another day or doctor.';
  end if;

  select full_name into v_name from public.profiles where id = v_uid;

  perform pg_advisory_xact_lock(hashtext(p_doctor_id::text || p_date::text));

  if exists (
    select 1 from public.appointments
    where patient_id = v_uid
      and doctor_id = p_doctor_id
      and appointment_date = p_date
      and status in ('waiting', 'in_progress')
  ) then
    raise exception 'You already have an appointment with this doctor on that day';
  end if;

  insert into public.queue_status (doctor_id, queue_date)
  values (p_doctor_id, p_date)
  on conflict do nothing;

  update public.queue_status
     set last_token = last_token + 1, updated_at = now()
   where doctor_id = p_doctor_id and queue_date = p_date
  returning last_token into v_token;

  insert into public.appointments
    (patient_id, patient_name, doctor_id, appointment_date, token_number, reason)
  values
    (v_uid, coalesce(v_name, 'Patient'), p_doctor_id, p_date, v_token,
     nullif(trim(coalesce(p_reason, '')), ''))
  returning * into v_row;

  return to_json(v_row);
end;
$$;

-- ---- reschedule_appointment: same check -----------------------------
create or replace function public.reschedule_appointment(p_id uuid, p_new_date date)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid      uuid := auth.uid();
  v_today    date := (now() at time zone 'Asia/Karachi')::date;
  v_old      public.appointments;
  v_new_token int;
  v_row      public.appointments;
  v_on_leave boolean;
  v_fully_booked date;
begin
  if p_new_date < v_today then
    raise exception 'Please choose today or a future date';
  end if;
  if p_new_date > v_today + 30 then
    raise exception 'Bookings are open for the next 30 days only';
  end if;

  select * into v_old from public.appointments
   where id = p_id and patient_id = v_uid and status = 'waiting';
  if not found then
    raise exception 'This appointment can no longer be rescheduled';
  end if;

  select on_leave, fully_booked_until into v_on_leave, v_fully_booked
    from public.doctors where id = v_old.doctor_id;
  if coalesce(v_on_leave, false) then
    raise exception 'This doctor is currently on leave. Please choose another doctor.';
  end if;
  if v_fully_booked is not null and v_fully_booked = p_new_date then
    raise exception 'This doctor is fully booked for that day. Please choose another day or doctor.';
  end if;

  perform pg_advisory_xact_lock(hashtext(v_old.doctor_id::text || p_new_date::text));

  insert into public.queue_status (doctor_id, queue_date)
  values (v_old.doctor_id, p_new_date)
  on conflict do nothing;

  update public.queue_status
     set last_token = last_token + 1, updated_at = now()
   where doctor_id = v_old.doctor_id and queue_date = p_new_date
  returning last_token into v_new_token;

  update public.appointments
     set appointment_date = p_new_date, token_number = v_new_token
   where id = p_id
  returning * into v_row;

  -- Touch the old date's queue so anyone watching it refreshes.
  update public.queue_status
     set updated_at = now()
   where doctor_id = v_old.doctor_id and queue_date = v_old.appointment_date;

  return to_json(v_row);
end;
$$;

-- ---- hospital_stats_today: now reports fully_booked_today per doctor --
create or replace function public.hospital_stats_today()
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_today  date := (now() at time zone 'Asia/Karachi')::date;
  v_role   text;
  v_result json;
begin
  select role into v_role from public.profiles where id = auth.uid();
  if v_role is distinct from 'admin' then
    raise exception 'Only hospital administrators can view this dashboard';
  end if;

  select json_build_object(
    'total_patients_today',
      (select count(*) from public.appointments where appointment_date = v_today),
    'total_completed_today',
      (select count(*) from public.appointments
        where appointment_date = v_today and status = 'completed'),
    'avg_wait_minutes_today',
      (select round(coalesce(extract(epoch from avg(started_at - created_at)) / 60.0, 0)::numeric, 1)
         from public.appointments
        where appointment_date = v_today and started_at is not null),
    'by_department',
      (select coalesce(json_agg(dept order by patients_today desc), '[]'::json)
         from (
           select d.department,
                  count(a.*) filter (where a.appointment_date = v_today) as patients_today,
                  count(a.*) filter (where a.appointment_date = v_today
                                        and a.status = 'completed')      as completed_today,
                  round(coalesce(
                    extract(epoch from
                      avg(a.started_at - a.created_at)
                        filter (where a.appointment_date = v_today and a.started_at is not null)
                    ) / 60.0, 0)::numeric, 1) as avg_wait_minutes
             from public.doctors d
             left join public.appointments a on a.doctor_id = d.id
            group by d.department
         ) dept
      ),
    'by_doctor',
      (select coalesce(json_agg(doc order by patients_today desc), '[]'::json)
         from (
           select d.id, d.full_name, d.department, d.on_leave,
                  (d.fully_booked_until = v_today)                             as fully_booked_today,
                  count(a.*) filter (where a.appointment_date = v_today) as patients_today,
                  count(a.*) filter (where a.appointment_date = v_today
                                        and a.status = 'completed')      as completed_today
             from public.doctors d
             left join public.appointments a on a.doctor_id = d.id
            group by d.id, d.full_name, d.department, d.on_leave, d.fully_booked_until
         ) doc
      )
  ) into v_result;

  return v_result;
end;
$$;

revoke all on function public.book_appointment(uuid, date, text) from public, anon;
revoke all on function public.reschedule_appointment(uuid, date) from public, anon;
revoke all on function public.hospital_stats_today() from public, anon;
grant execute on function public.book_appointment(uuid, date, text) to authenticated;
grant execute on function public.reschedule_appointment(uuid, date) to authenticated;
grant execute on function public.hospital_stats_today() to authenticated;
