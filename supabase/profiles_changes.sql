alter table public.profiles
  add column if not exists role text not null default 'user',
  add column if not exists location_source text,
  add column if not exists location_note text;

insert into public.profiles (id, display_name, role, has_completed_simulation, status)
select id, 'SAR Team Alpha', 'sar', true, 'safe'
from auth.users
where email = 'sar@quaky.app'
on conflict (id) do update
  set role = 'sar', has_completed_simulation = true;