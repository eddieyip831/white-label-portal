alter table public.roles
add column if not exists tenant_id uuid references public.tenants(id);

update public.roles
set tenant_id = (select id from public.tenants limit 1)
where tenant_id is null;

alter table public.permissions
add column if not exists tenant_id uuid references public.tenants(id);

update public.permissions
set tenant_id = (select id from public.tenants limit 1)
where tenant_id is null;

alter table public.modules
add column if not exists tenant_id uuid references public.tenants(id);

update public.modules
set tenant_id = (select id from public.tenants limit 1)
where tenant_id is null;

create table if not exists public.user_profile (
  id uuid primary key references auth.users(id) on delete cascade,
  tenant_id uuid references public.tenants(id),
  full_name text,
  attributes jsonb default '{}'::jsonb,
  tier_id uuid references public.tiers(id),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

insert into public.user_profile (id, tenant_id)
select id, (select id from public.tenants limit 1)
from auth.users
on conflict (id) do nothing;

    select to_regclass('public.tier_permissions');
