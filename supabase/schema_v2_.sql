

alter table public.doctors
  add column if not exists on_leave boolean not null default false;



alter table public.appointments
  add column if not exists started_at   timestamptz,
  add column if not exists completed_at timestamptz;



alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles
  add constraint profiles_role_check check (role in ('patient', 'doctor', 'admin'));



create table if not exists public.appointment_ratings (
  id             uuid primary key default gen_random_uuid(),
  appointment_id uuid not null unique references public.appointments (id) on delete cascade,
  patient_id     uuid not null references public.profiles (id) on delete cascade,
  doctor_id      uuid not null references public.doctors (id) on delete cascade,
  rating         int  not null check (rating between 1 and 5),
  comment        text,
  created_at     timestamptz not null default now()
);

alter table public.appointment_ratings enable row level security;

drop policy if exists "ratings: patient reads own" on public.appointment_ratings;
create policy "ratings: patient reads own"
  on public.appointment_ratings for select to authenticated
  using (patient_id = auth.uid());

drop policy if exists "ratings: doctor reads own" on public.appointment_ratings;
create policy "ratings: doctor reads own"
  on public.appointment_ratings for select to authenticated
  using (
    exists (
      select 1 from public.doctors d
      where d.id = appointment_ratings.doctor_id and d.user_id = auth.uid()
    )
  );



create or replace function public.set_doctor_leave(p_doctor_id uuid, p_on_leave boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.doctors
     set on_leave = p_on_leave
   where id = p_doctor_id and user_id = auth.uid();

  if not found then
    raise exception 'Only the assigned doctor can change this';
  end if;
end;
$$;


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

  select on_leave into v_on_leave from public.doctors where id = p_doctor_id;
  if coalesce(v_on_leave, false) then
    raise exception 'This doctor is currently on leave. Please choose another doctor.';
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



create or replace function public.call_next_patient(
  p_doctor_id uuid,
  p_date      date default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_date  date := coalesce(p_date, (now() at time zone 'Asia/Karachi')::date);
  v_next  public.appointments;
  v_found boolean;
begin
  if not exists (
    select 1 from public.doctors
    where id = p_doctor_id and user_id = auth.uid()
  ) then
    raise exception 'Only the assigned doctor can manage this queue';
  end if;

  perform pg_advisory_xact_lock(hashtext(p_doctor_id::text || v_date::text));

  update public.appointments
     set status = 'completed', completed_at = now()
   where doctor_id = p_doctor_id
     and appointment_date = v_date
     and status = 'in_progress';

  select * into v_next
    from public.appointments
   where doctor_id = p_doctor_id
     and appointment_date = v_date
     and status = 'waiting'
   order by token_number
   limit 1;
  v_found := found;

  if v_found then
    update public.appointments
       set status = 'in_progress', started_at = now()
     where id = v_next.id;
  end if;

  insert into public.queue_status (doctor_id, queue_date, now_serving)
  values (p_doctor_id, v_date, case when v_found then v_next.token_number else 0 end)
  on conflict (doctor_id, queue_date) do update
    set now_serving = case when v_found then excluded.now_serving
                           else public.queue_status.now_serving end,
        updated_at  = now();
end;
$$;



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

  select on_leave into v_on_leave from public.doctors where id = v_old.doctor_id;
  if coalesce(v_on_leave, false) then
    raise exception 'This doctor is currently on leave. Please choose another doctor.';
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


  update public.queue_status
     set updated_at = now()
   where doctor_id = v_old.doctor_id and queue_date = v_old.appointment_date;

  return to_json(v_row);
end;
$$;



create or replace function public.submit_rating(
  p_appointment_id uuid,
  p_rating         int,
  p_comment        text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid    uuid := auth.uid();
  v_appt   public.appointments;
begin
  if p_rating < 1 or p_rating > 5 then
    raise exception 'Rating must be between 1 and 5';
  end if;

  select * into v_appt from public.appointments
   where id = p_appointment_id and patient_id = v_uid and status = 'completed';
  if not found then
    raise exception 'Only completed appointments can be rated';
  end if;

  insert into public.appointment_ratings (appointment_id, patient_id, doctor_id, rating, comment)
  values (p_appointment_id, v_uid, v_appt.doctor_id, p_rating, nullif(trim(coalesce(p_comment, '')), ''))
  on conflict (appointment_id) do update
    set rating = excluded.rating, comment = excluded.comment;
end;
$$;



create or replace function public.doctor_stats_today()
returns json
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_doctor_id uuid;
  v_today     date := (now() at time zone 'Asia/Karachi')::date;
  v_result    json;
begin
  select id into v_doctor_id from public.doctors where user_id = auth.uid();
  if v_doctor_id is null then
    raise exception 'This account is not linked to a doctor';
  end if;

  select json_build_object(
    'patients_completed', count(*) filter (where status = 'completed'),
    'patients_waiting',   count(*) filter (where status = 'waiting'),
    'avg_wait_minutes',
      round(coalesce(extract(epoch from
        avg(started_at - created_at) filter (where started_at is not null)
      ) / 60.0, 0)::numeric, 1),
    'avg_consult_minutes',
      round(coalesce(extract(epoch from
        avg(completed_at - started_at) filter (where completed_at is not null and started_at is not null)
      ) / 60.0, 0)::numeric, 1),
    'avg_rating',
      (select round(coalesce(avg(rating), 0)::numeric, 1)
         from public.appointment_ratings where doctor_id = v_doctor_id)
  ) into v_result
  from public.appointments
  where doctor_id = v_doctor_id and appointment_date = v_today;

  return v_result;
end;
$$;



create or replace function public.hospital_stats_today()
returns json
language plpgsql
stable
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
                  count(a.*) filter (where a.appointment_date = v_today) as patients_today,
                  count(a.*) filter (where a.appointment_date = v_today
                                        and a.status = 'completed')      as completed_today
             from public.doctors d
             left join public.appointments a on a.doctor_id = d.id
            group by d.id, d.full_name, d.department, d.on_leave
         ) doc
      )
  ) into v_result;

  return v_result;
end;
$$;



revoke all on function public.set_doctor_leave(uuid, boolean)      from public, anon;
revoke all on function public.reschedule_appointment(uuid, date)   from public, anon;
revoke all on function public.submit_rating(uuid, int, text)       from public, anon;
revoke all on function public.doctor_stats_today()                 from public, anon;
revoke all on function public.hospital_stats_today()                from public, anon;
grant execute on function public.set_doctor_leave(uuid, boolean)      to authenticated;
grant execute on function public.reschedule_appointment(uuid, date)   to authenticated;
grant execute on function public.submit_rating(uuid, int, text)       to authenticated;
grant execute on function public.doctor_stats_today()                 to authenticated;
grant execute on function public.hospital_stats_today()               to authenticated;



create or replace function public.link_admin_account(p_email text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid;
begin
  select id into v_uid from public.profiles where email = p_email;
  if v_uid is null then
    raise exception 'No user with that email. Sign up in the app first.';
  end if;
  update public.profiles set role = 'admin' where id = v_uid;
end;
$$;

revoke all on function public.link_admin_account(text) from public, anon, authenticated;
