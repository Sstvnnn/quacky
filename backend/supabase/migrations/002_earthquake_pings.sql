
create table public.earthquake_pings (
  id         uuid primary key default gen_random_uuid(),
  device_id  uuid not null references auth.users(id) on delete cascade,
  location   geography(point, 4326) not null,
  confidence float not null check (confidence >= 0 and confidence <= 1),
  created_at timestamptz not null default now()
);

create index earthquake_pings_geo_idx
  on public.earthquake_pings using gist (location);

create index earthquake_pings_time_idx
  on public.earthquake_pings (created_at desc);


alter table public.earthquake_pings enable row level security;

create policy "authenticated can read pings"
  on public.earthquake_pings
  for select
  to authenticated
  using (true);

