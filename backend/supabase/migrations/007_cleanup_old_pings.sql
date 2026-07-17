
create or replace function public.cleanup_old_pings()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_deleted int;
begin
  delete from earthquake_pings
  where created_at < now() - interval '1 minute';

  get diagnostics v_deleted = row_count;
  return v_deleted;
end;
$$;

create or replace function public.cleanup_stale_heartbeats()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_deleted int;
begin
  delete from active_devices
  where last_heartbeat < now() - interval '5 minutes';

  get diagnostics v_deleted = row_count;
  return v_deleted;
end;
$$;
