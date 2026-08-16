-- Before User Created Auth Hook (Postgres).
-- This is the only server-side Wesleyan-domain signup gate.
-- Do not add a BEFORE INSERT trigger or constraint on auth.users.
-- Enable in Dashboard → Authentication → Hooks → Before User Created
-- (or via supabase/config.toml for local CLI).

create or replace function public.hook_restrict_wesleyan_email(event jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  raw_email text;
  domain text;
begin
  raw_email := nullif(btrim(event->'user'->>'email'), '');

  if raw_email is null then
    return jsonb_build_object(
      'error',
      jsonb_build_object(
        'message', 'A Wesleyan University email address is required.',
        'http_code', 400
      )
    );
  end if;

  domain := lower(split_part(raw_email, '@', 2));

  if domain is distinct from 'wesleyan.edu' then
    return jsonb_build_object(
      'error',
      jsonb_build_object(
        'message', 'MyWes is only available to Wesleyan University email addresses.',
        'http_code', 403
      )
    );
  end if;

  return '{}'::jsonb;
end;
$$;

grant usage on schema public to supabase_auth_admin;
grant execute on function public.hook_restrict_wesleyan_email(jsonb) to supabase_auth_admin;
revoke execute on function public.hook_restrict_wesleyan_email(jsonb) from authenticated, anon, public;
