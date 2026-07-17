
create or replace function public.check_consensus()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_consensus_radius    constant int        := 5000;
  v_consensus_window    constant interval   := '3 seconds';
  v_consensus_threshold constant int        := 5;
  v_dedup_radius        constant int        := 5000;
  v_dedup_window        constant interval   := '30 seconds';

  v_nearby_count   int;
  v_avg_confidence float;
  v_dedup_exists   boolean;
begin
  select exists(
    select 1
    from confirmed_quakes
    where ST_DWithin(epicenter, new.location, v_dedup_radius)
      and created_at > now() - v_dedup_window
  ) into v_dedup_exists;

  if v_dedup_exists then
    return new;
  end if;

  select count(*), avg(confidence)
  into v_nearby_count, v_avg_confidence
  from earthquake_pings
  where ST_DWithin(location, new.location, v_consensus_radius)
    and created_at > now() - v_consensus_window;

  if v_nearby_count >= v_consensus_threshold then
    insert into confirmed_quakes (epicenter, radius_meters, device_count, avg_confidence)
    values (new.location, v_consensus_radius, v_nearby_count, v_avg_confidence);
  end if;

  return new;
end;
$$;

create trigger trg_check_consensus
  after insert on public.earthquake_pings
  for each row
  execute function public.check_consensus();
