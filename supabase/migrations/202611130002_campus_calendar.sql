-- Real campus events from the public Wesleyan calendar (events.wesleyan.edu).
-- The sync-campus-events Edge Function fetches the feed and calls
-- sync_campus_events() with the service role. Hand-entered rows keep
-- external_source = null and are never touched by the sync.

alter table public.organizations
  add column external_source text,
  add column external_id text,
  add constraint organizations_external_key unique (external_source, external_id);

alter table public.events
  add column external_source text,
  add column external_id text,
  add column is_all_day boolean not null default false,
  add column source_url text
    check (source_url is null or source_url like 'https://events.wesleyan.edu/%'),
  add constraint events_external_key unique (external_source, external_id);

create or replace function public.sync_campus_events(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  source constant text := 'wesleyan_calendar';
  window_start timestamptz := (payload->>'window_start')::timestamptz;
  window_end timestamptz := (payload->>'window_end')::timestamptz;
  org_rows int;
  event_rows int;
  removed_rows int;
begin
  if window_start is null or window_end is null or window_end <= window_start
     or jsonb_typeof(payload->'events') <> 'array' or jsonb_typeof(payload->'organizations') <> 'array' then
    raise exception 'invalid calendar payload' using errcode = '22023';
  end if;

  insert into organizations (name, category, description, external_source, external_id)
  select left(o->>'name', 100), left(o->>'category', 50), left(coalesce(o->>'description', ''), 500), source, o->>'external_id'
  from jsonb_array_elements(payload->'organizations') o
  where nullif(o->>'external_id', '') is not null and nullif(o->>'name', '') is not null
  on conflict (external_source, external_id) do update
    set name = excluded.name, category = excluded.category, description = excluded.description;
  get diagnostics org_rows = row_count;

  insert into events (org_id, title, category, description, location, start_at, end_at,
                      is_all_day, source_url, external_source, external_id)
  select org.id, left(e->>'title', 200), left(e->>'category', 50), left(coalesce(e->>'description', ''), 2000),
         left(coalesce(nullif(e->>'location', ''), 'Wesleyan University'), 200),
         (e->>'start_at')::timestamptz,
         case when (e->>'end_at')::timestamptz >= (e->>'start_at')::timestamptz then (e->>'end_at')::timestamptz end,
         coalesce((e->>'is_all_day')::boolean, false),
         case when e->>'source_url' like 'https://events.wesleyan.edu/%' then e->>'source_url' end,
         source, e->>'external_id'
  from jsonb_array_elements(payload->'events') e
  join organizations org on org.external_source = source and org.external_id = e->>'org_external_id'
  where nullif(e->>'external_id', '') is not null and nullif(e->>'title', '') is not null
  on conflict (external_source, external_id) do update
    set org_id = excluded.org_id, title = excluded.title, category = excluded.category,
        description = excluded.description, location = excluded.location, start_at = excluded.start_at,
        end_at = excluded.end_at, is_all_day = excluded.is_all_day, source_url = excluded.source_url;
  get diagnostics event_rows = row_count;

  -- Drop synced events that left the feed (cancelled or deleted) inside the
  -- synced window, and synced events that ended more than two weeks ago.
  delete from events ev
  where ev.external_source = source
    and ((ev.start_at >= window_start and ev.start_at < window_end
          and not exists (select 1 from jsonb_array_elements(payload->'events') e
                          where e->>'external_id' = ev.external_id))
         or coalesce(ev.end_at, ev.start_at) < now() - interval '14 days');
  get diagnostics removed_rows = row_count;

  return jsonb_build_object('organizations', org_rows, 'events', event_rows, 'removed', removed_rows);
end;
$$;

revoke all on function public.sync_campus_events(jsonb) from public, anon, authenticated;
do $$
begin
  if exists (select 1 from pg_roles where rolname = 'service_role') then
    grant execute on function public.sync_campus_events(jsonb) to service_role;
  end if;
end $$;
