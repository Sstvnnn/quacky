
create table public.confirmed_quakes (
  id             uuid primary key default gen_random_uuid(),
  epicenter      geography(point, 4326),
  radius_meters  int not null default 5000,
  device_count   int not null,
  avg_confidence float not null,
  created_at     timestamptz not null default now()
);

create index confirmed_quakes_geo_idx
  on public.confirmed_quakes using gist (epicenter);

create index confirmed_quakes_time_idx
  on public.confirmed_quakes (created_at desc);


alter table public.confirmed_quakes enable row level security;

create policy "authenticated can read confirmed quakes"
  on public.confirmed_quakes
  for select
  to authenticated
  using (true);


alter publication supabase_realtime add table public.confirmed_quakes;
