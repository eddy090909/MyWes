create table public.event_saves (
  user_id uuid not null references auth.users (id) on delete cascade,
  event_id uuid not null references public.events (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, event_id)
);

create index event_saves_event_id_idx on public.event_saves (event_id);

alter table public.event_saves enable row level security;
