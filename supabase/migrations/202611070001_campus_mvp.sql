-- Campus Q&A: authenticated readership, author-only writes, no profile/email joins.
create table public.questions (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 5 and 180),
  body text not null check (char_length(btrim(body)) between 1 and 5000),
  topic text not null check (char_length(btrim(topic)) between 1 and 40),
  created_at timestamptz not null default now()
);
create table public.answers (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.questions(id) on delete cascade,
  author_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  body text not null check (char_length(btrim(body)) between 1 and 5000),
  created_at timestamptz not null default now()
);
create index questions_created_at_idx on public.questions(created_at desc, id);
create index answers_question_idx on public.answers(question_id, created_at);
alter table public.questions enable row level security;
alter table public.answers enable row level security;
revoke all on public.questions, public.answers from public, anon, authenticated;
grant select, delete on public.questions, public.answers to authenticated;
-- IDs, authorship and timestamps are assigned by the database, not the app.
grant insert(title, body, topic) on public.questions to authenticated;
grant insert(question_id, body) on public.answers to authenticated;
create policy questions_read on public.questions for select to authenticated using (true);
create policy questions_create on public.questions for insert to authenticated
  with check (author_id = (select auth.uid()));
create policy questions_delete on public.questions for delete to authenticated
  using (author_id = (select auth.uid()));
create policy answers_read on public.answers for select to authenticated using (true);
create policy answers_create on public.answers for insert to authenticated
  with check (author_id = (select auth.uid()));
create policy answers_delete on public.answers for delete to authenticated
  using (author_id = (select auth.uid()));

-- Profile identity is provisioned from Auth; students may edit only these fields.
revoke update on public.profiles from authenticated;
grant update(full_name, class_year, interests, onboarding_completed) on public.profiles to authenticated;
alter table public.profiles add constraint profiles_name_length
  check (full_name is null or char_length(full_name) <= 100);

-- Published regular dining schedule. Seven days, Sunday first. Each period is
-- {"start": minutes after midnight, "end": minutes after midnight}; end may
-- exceed 1440 for overnight service. An empty day means regularly closed.
create table public.dining_locations (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  location text not null,
  weekly_hours jsonb not null check (jsonb_typeof(weekly_hours) = 'array' and jsonb_array_length(weekly_hours) = 7),
  notes text not null default '',
  source_url text not null check (source_url like 'https://www.wesleyan.edu/dining/%'),
  verified_on date not null,
  valid_through date not null check (valid_through >= verified_on)
);
alter table public.dining_locations enable row level security;
revoke all on public.dining_locations from public, anon, authenticated;
grant select on public.dining_locations to authenticated;
create policy dining_read on public.dining_locations for select to authenticated using (true);

-- Checked against the official Hours of Operation page on 2026-11-07.
-- Regular semester hours only, deliberately expire before Thanksgiving week.
-- No fake ratings, reviews, occupancy, or invented holiday exceptions.
insert into public.dining_locations(name, location, weekly_hours, notes, source_url, verified_on, valid_through) values
('Usdan Marketplace', 'Usdan University Center, second floor',
 '[[{"start":660,"end":840},{"start":1020,"end":1200}],[{"start":480,"end":630},{"start":660,"end":840},{"start":1020,"end":1200}],[{"start":480,"end":630},{"start":660,"end":840},{"start":1020,"end":1200}],[{"start":480,"end":630},{"start":660,"end":840},{"start":1020,"end":1200}],[{"start":480,"end":630},{"start":660,"end":840},{"start":1020,"end":1200}],[{"start":480,"end":630},{"start":660,"end":840},{"start":1020,"end":1200}],[{"start":660,"end":840},{"start":1020,"end":1200}]]',
 'Regular semester hours; breaks and special events may differ.',
 'https://www.wesleyan.edu/dining/Hours%20of%20Operation.html', '2026-11-07', '2026-11-20'),
('Summerfields', 'Butterfield C',
 '[[{"start":1050,"end":1260},{"start":1290,"end":1500}],[{"start":660,"end":1260},{"start":1290,"end":1500}],[{"start":660,"end":1260},{"start":1290,"end":1500}],[{"start":660,"end":1260},{"start":1290,"end":1500}],[{"start":660,"end":1260},{"start":1290,"end":1500}],[{"start":660,"end":1260},{"start":1290,"end":1500}],[{"start":1050,"end":1260},{"start":1290,"end":1500}]]',
 'Late-night orders by 12:30 AM; service may end early. Break hours may differ.',
 'https://www.wesleyan.edu/dining/Hours%20of%20Operation.html', '2026-11-07', '2026-11-20'),
('Usdan Café', 'Usdan University Center, first floor',
 '[[],[{"start":480,"end":1200}],[{"start":480,"end":1200}],[{"start":480,"end":1200}],[{"start":480,"end":1200}],[{"start":480,"end":1200}],[]]',
 'Regular weekday schedule; special weekend openings may differ.',
 'https://www.wesleyan.edu/dining/Hours%20of%20Operation.html', '2026-11-07', '2026-11-20');
