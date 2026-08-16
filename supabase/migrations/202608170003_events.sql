create table public.events (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete restrict,
  title text not null,
  category text not null,
  description text not null default '',
  location text not null,
  start_at timestamptz not null,
  end_at timestamptz,
  banner_url text,
  created_at timestamptz not null default now(),
  constraint events_end_at_check check (end_at is null or end_at >= start_at)
);

create index events_start_at_idx on public.events (start_at);
create index events_org_id_idx on public.events (org_id);
create index events_category_idx on public.events (category);

alter table public.events enable row level security;
