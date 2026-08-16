create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null,
  description text not null default '',
  member_count integer not null default 0,
  avatar_url text,
  banner_url text,
  contact_email text,
  instagram_handle text,
  created_at timestamptz not null default now(),
  constraint organizations_member_count_check check (member_count >= 0)
);

create index organizations_category_idx on public.organizations (category);

alter table public.organizations enable row level security;
