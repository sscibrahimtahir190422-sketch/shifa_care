

create table public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  full_name   text not null default 'Patient',
  email       text,
  role        text not null default 'patient' check (role in ('patient', 'doctor')),
  created_at  timestamptz not null default now()
);

create table public.doctors (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid unique references public.profiles (id) on delete set null,
  full_name        text not null,
  specialty        text not null,
  department       text not null,
  room             text not null,
  avg_minutes      int  not null default 10 check (avg_minutes > 0),
  experience_years int  not null default 5
);

create table public.appointments (
  id               uuid primary key default gen_random_uuid(),
  patient_id       uuid not null references public.profiles (id) on delete cascade,
  patient_name     text not null,
  doctor_id        uuid not null references public.doctors (id) on delete cascade,
  appointment_date date not null,
  token_number     int  not null,
  status           text not null default 'waiting'
                   check (status in ('waiting', 'in_progress', 'completed', 'cancelled')),
  reason           text,
  created_at       timestamptz not null default now(),
  unique (doctor_id, appointment_date, token_number)
);

create index appointments_patient_idx on public.appointments (patient_id);
create index appointments_queue_idx   on public.appointments (doctor_id, appointment_date);


create table public.queue_status (
  doctor_id   uuid not null references public.doctors (id) on delete cascade,
  queue_date  date not null,
  now_serving int  not null default 0,
  last_token  int  not null default 0,
  updated_at  timestamptz not null default now(),
  primary key (doctor_id, queue_date)
);


create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', 'Patient'),
    new.email
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();



alter table public.profiles     enable row level security;
alter table public.doctors      enable row level security;
alter table public.appointments enable row level security;
alter table public.queue_status enable row level security;

create policy "profiles: read own"
  on public.profiles for select to authenticated
  using (id = auth.uid());

create policy "doctors: read all"
  on public.doctors for select to authenticated
  using (true);

create policy "queue_status: read all"
  on public.queue_status for select to authenticated
  using (true);

create policy "appointments: patient reads own"
  on public.appointments for select to authenticated
  using (patient_id = auth.uid());

create policy "appointments: doctor reads own queue"
  on public.appointments for select to authenticated
  using (
    exists (
      select 1 from public.doctors d
      where d.id = appointments.doctor_id and d.user_id = auth.uid()
    )
  );


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
  v_uid   uuid := auth.uid();
  v_today date := (now() at time zone 'Asia/Karachi')::date;
  v_name  text;
  v_token int;
  v_row   public.appointments;
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

create or replace function public.cancel_appointment(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_doctor uuid;
  v_date   date;
begin
  update public.appointments
     set status = 'cancelled'
   where id = p_id and patient_id = auth.uid() and status = 'waiting'
  returning doctor_id, appointment_date into v_doctor, v_date;

  if not found then
    raise exception 'This appointment can no longer be cancelled';
  end if;


  update public.queue_status
     set updated_at = now()
   where doctor_id = v_doctor and queue_date = v_date;
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
     set status = 'completed'
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
    update public.appointments set status = 'in_progress' where id = v_next.id;
  end if;

  insert into public.queue_status (doctor_id, queue_date, now_serving)
  values (p_doctor_id, v_date, case when v_found then v_next.token_number else 0 end)
  on conflict (doctor_id, queue_date) do update
    set now_serving = case when v_found then excluded.now_serving
                           else public.queue_status.now_serving end,
        updated_at  = now();
end;
$$;


create or replace function public.patients_ahead(p_appointment_id uuid)
returns int
language sql
stable
security definer
set search_path = public
as $$
  select count(*)::int
    from public.appointments other
    join public.appointments mine
      on mine.id = p_appointment_id and mine.patient_id = auth.uid()
   where other.doctor_id = mine.doctor_id
     and other.appointment_date = mine.appointment_date
     and other.token_number < mine.token_number
     and other.status in ('waiting', 'in_progress');
$$;


create or replace function public.active_queue_size(p_doctor_id uuid, p_date date)
returns int
language sql
stable
security definer
set search_path = public
as $$
  select count(*)::int
    from public.appointments
   where doctor_id = p_doctor_id
     and appointment_date = p_date
     and status in ('waiting', 'in_progress');
$$;


revoke all on function public.book_appointment(uuid, date, text) from public, anon;
revoke all on function public.cancel_appointment(uuid)           from public, anon;
revoke all on function public.call_next_patient(uuid, date)      from public, anon;
revoke all on function public.patients_ahead(uuid)               from public, anon;
revoke all on function public.active_queue_size(uuid, date)      from public, anon;
grant execute on function public.book_appointment(uuid, date, text) to authenticated;
grant execute on function public.cancel_appointment(uuid)           to authenticated;
grant execute on function public.call_next_patient(uuid, date)      to authenticated;
grant execute on function public.patients_ahead(uuid)               to authenticated;
grant execute on function public.active_queue_size(uuid, date)      to authenticated;



alter publication supabase_realtime add table public.appointments;
alter publication supabase_realtime add table public.queue_status;



insert into public.doctors (full_name, specialty, department, room, avg_minutes, experience_years) values
  ('Dr. Ayesha Malik', 'Consultant Cardiologist',  'Cardiology',  'Room C-12', 12, 14),
  ('Dr. Hassan Raza',  'General Physician',        'Medicine',    'Room M-05', 10,  9),
  ('Dr. Sana Iqbal',   'Consultant Paediatrician', 'Paediatrics', 'Room P-03', 15, 11),
  ('Dr. Omar Farooq',  'Orthopaedic Surgeon',      'Orthopaedics','Room O-21', 12, 16),
  ('Dr. Nadia Karim',  'Dermatologist',            'Dermatology', 'Room D-08', 10,  8),
  ('Dr. Bilal Ahmed',  'ENT Specialist',           'ENT',         'Room E-14', 10,  7);



create or replace function public.link_doctor_account(p_email text, p_doctor_name text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid;
  v_doc uuid;
begin
  select id into v_uid from public.profiles where email = p_email;
  if v_uid is null then
    raise exception 'No user with that email. Sign up in the app first.';
  end if;

  select id into v_doc from public.doctors where full_name = p_doctor_name;
  if v_doc is null then
    raise exception 'No doctor named %', p_doctor_name;
  end if;

  update public.profiles set role = 'doctor' where id = v_uid;
  update public.doctors  set user_id = v_uid where id = v_doc;
end;
$$;

