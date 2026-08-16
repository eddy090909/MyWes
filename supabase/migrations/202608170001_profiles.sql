-- public.profiles is keyed by auth.users.id.
-- Provisioning is trigger-only. authenticated clients cannot insert rows.

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null unique,
  full_name text,
  class_year integer,
  interests text[] not null default '{}'::text[],
  onboarding_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_email_wesleyan_check
    check (email ~* '^[^@]+@wesleyan\.edu$'),
  constraint profiles_class_year_check
    check (class_year is null or (class_year >= 2020 and class_year <= 2040))
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

-- Creates a stub profile after Auth inserts auth.users.
-- This is provisioning only, not a signup-domain gate.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.email is null or btrim(new.email) = '' then
    raise exception 'Cannot provision a profile without an email';
  end if;

  insert into public.profiles (id, email)
  values (new.id, lower(btrim(new.email)));

  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();

alter table public.profiles enable row level security;
grant execute on function public.handle_new_user() to supabase_auth_admin;
revoke execute on function public.handle_new_user() from authenticated, anon, public;
