
create or replace function public.insert_ping(
  p_lat        double precision,
  p_lon        double precision,
  p_confidence float
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_confidence < 0 or p_confidence > 1 then
    raise exception 'confidence must be between 0 and 1, got %', p_confidence;
  end if;

  insert into earthquake_pings (device_id, location, confidence)
  values (
    auth.uid(),
    ST_SetSRID(ST_MakePoint(p_lon, p_lat), 4326)::geography,
    p_confidence
  );
end;
$$;
