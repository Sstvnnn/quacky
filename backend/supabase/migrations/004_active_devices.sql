
create table public.active_devices (
  device_id      uuid primary key references auth.users(id) on delete cascade,
  location       geography(point, 4326) not null,
  last_heartbeat timestamptz not null default now()
);

create index active_devices_geo_idx
  on public.active_devices using gist (location);

create index active_devices_heartbeat_idx
  on public.active_devices (last_heartbeat desc);


alter table public.active_devices enable row level security;

create policy "authenticated can read active devices"
  on public.active_devices
  for select
  to authenticated
  using (true);


create or replace function public.upsert_heartbeat(
  p_lat double precision,
  p_lon double precision
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into active_devices (device_id, location, last_heartbeat)
  values (
    auth.uid(),
    ST_SetSRID(ST_MakePoint(p_lon, p_lat), 4326)::geography,
    now()
  )
  on conflict (device_id) do update
    set location       = excluded.location,
        last_heartbeat = excluded.last_heartbeat;
end;
$$;
