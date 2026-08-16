-- Authenticated campus catalog + own-row engagement.
-- anon has no table access. Students cannot write events or organizations.

revoke all on table public.profiles from anon, authenticated, public;
revoke all on table public.organizations from anon, authenticated, public;
revoke all on table public.events from anon, authenticated, public;
revoke all on table public.org_follows from anon, authenticated, public;
revoke all on table public.event_saves from anon, authenticated, public;

grant select, update on table public.profiles to authenticated;
grant select on table public.organizations to authenticated;
grant select on table public.events to authenticated;
grant select, insert, delete on table public.org_follows to authenticated;
grant select, insert, delete on table public.event_saves to authenticated;

create policy "profiles_select_own"
  on public.profiles
  for select
  to authenticated
  using (id = auth.uid());

create policy "profiles_update_own"
  on public.profiles
  for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

create policy "organizations_select_authenticated"
  on public.organizations
  for select
  to authenticated
  using (true);

create policy "events_select_authenticated"
  on public.events
  for select
  to authenticated
  using (true);

create policy "org_follows_select_own"
  on public.org_follows
  for select
  to authenticated
  using (user_id = auth.uid());

create policy "org_follows_insert_own"
  on public.org_follows
  for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "org_follows_delete_own"
  on public.org_follows
  for delete
  to authenticated
  using (user_id = auth.uid());

create policy "event_saves_select_own"
  on public.event_saves
  for select
  to authenticated
  using (user_id = auth.uid());

create policy "event_saves_insert_own"
  on public.event_saves
  for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "event_saves_delete_own"
  on public.event_saves
  for delete
  to authenticated
  using (user_id = auth.uid());
