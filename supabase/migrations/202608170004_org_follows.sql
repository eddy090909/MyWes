create table public.org_follows (
  user_id uuid not null references auth.users (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, org_id)
);

create index org_follows_org_id_idx on public.org_follows (org_id);

alter table public.org_follows enable row level security;
