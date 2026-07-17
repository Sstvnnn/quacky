
select postgis_full_version();

select count(*) as ping_columns from information_schema.columns
  where table_name = 'earthquake_pings';

select count(*) as quake_columns from information_schema.columns
  where table_name = 'confirmed_quakes';

select count(*) as device_columns from information_schema.columns
  where table_name = 'active_devices';




do $$
declare
  v_device_ids uuid[] := array[
    gen_random_uuid(),
    gen_random_uuid(),
    gen_random_uuid(),
    gen_random_uuid(),
    gen_random_uuid()
  ];
  v_confirmed_before int;
  v_confirmed_after  int;
begin
  select count(*) into v_confirmed_before from confirmed_quakes;


  insert into earthquake_pings (device_id, location, confidence)
  values
    (v_device_ids[1], ST_SetSRID(ST_MakePoint(106.8000, -6.2000), 4326)::geography, 0.92),
    (v_device_ids[2], ST_SetSRID(ST_MakePoint(106.8001, -6.2001), 4326)::geography, 0.88),
    (v_device_ids[3], ST_SetSRID(ST_MakePoint(106.8002, -6.1999), 4326)::geography, 0.95),
    (v_device_ids[4], ST_SetSRID(ST_MakePoint(106.7999, -6.2002), 4326)::geography, 0.90),
    (v_device_ids[5], ST_SetSRID(ST_MakePoint(106.8001, -6.2000), 4326)::geography, 0.87);

  select count(*) into v_confirmed_after from confirmed_quakes;

  raise notice '──────────────────────────────────────────';
  raise notice 'TEST: 5 nearby pings → consensus trigger';
  raise notice 'Confirmed before: %, after: %', v_confirmed_before, v_confirmed_after;

  if v_confirmed_after > v_confirmed_before then
    raise notice '✅ PASS — consensus triggered!';
  else
    raise notice '❌ FAIL — no confirmed quake created';
    raise notice 'Possible cause: FK constraint on device_id → auth.users';
    raise notice 'Try: alter table earthquake_pings drop constraint earthquake_pings_device_id_fkey;';
  end if;

  raise notice '──────────────────────────────────────────';
end;
$$;

select
  id,
  ST_Y(epicenter::geometry) as lat,
  ST_X(epicenter::geometry) as lon,
  device_count,
  avg_confidence,
  created_at
from confirmed_quakes
order by created_at desc
limit 5;


do $$
declare
  v_confirmed_before int;
  v_confirmed_after  int;
begin
  select count(*) into v_confirmed_before from confirmed_quakes;

  insert into earthquake_pings (device_id, location, confidence)
  values
    (gen_random_uuid(), ST_SetSRID(ST_MakePoint(106.8000, -6.2000), 4326)::geography, 0.93),
    (gen_random_uuid(), ST_SetSRID(ST_MakePoint(106.8001, -6.2001), 4326)::geography, 0.89),
    (gen_random_uuid(), ST_SetSRID(ST_MakePoint(106.8002, -6.1999), 4326)::geography, 0.91),
    (gen_random_uuid(), ST_SetSRID(ST_MakePoint(106.7999, -6.2002), 4326)::geography, 0.88),
    (gen_random_uuid(), ST_SetSRID(ST_MakePoint(106.8001, -6.2000), 4326)::geography, 0.94);

  select count(*) into v_confirmed_after from confirmed_quakes;

  raise notice '──────────────────────────────────────────';
  raise notice 'TEST: Deduplication (same area within 30s)';
  raise notice 'Confirmed before: %, after: %', v_confirmed_before, v_confirmed_after;

  if v_confirmed_after = v_confirmed_before then
    raise notice '✅ PASS — deduplication worked!';
  else
    raise notice '❌ FAIL — duplicate quake created';
  end if;

  raise notice '──────────────────────────────────────────';
end;
$$;


do $$
declare
  v_confirmed_before int;
  v_confirmed_after  int;
begin
  delete from confirmed_quakes;

  select count(*) into v_confirmed_before from confirmed_quakes;

  insert into earthquake_pings (device_id, location, confidence)
  values
    (gen_random_uuid(), ST_SetSRID(ST_MakePoint(112.7500, -7.2500), 4326)::geography, 0.90),
    (gen_random_uuid(), ST_SetSRID(ST_MakePoint(112.7501, -7.2501), 4326)::geography, 0.88),
    (gen_random_uuid(), ST_SetSRID(ST_MakePoint(112.7502, -7.2499), 4326)::geography, 0.91);

  select count(*) into v_confirmed_after from confirmed_quakes;

  raise notice '──────────────────────────────────────────';
  raise notice 'TEST: 3 pings only (below threshold of 5)';
  raise notice 'Confirmed before: %, after: %', v_confirmed_before, v_confirmed_after;

  if v_confirmed_after = v_confirmed_before then
    raise notice '✅ PASS — correctly did not trigger';
  else
    raise notice '❌ FAIL — incorrectly triggered with < 5 pings';
  end if;

  raise notice '──────────────────────────────────────────';
end;
$$;

select cleanup_old_pings() as pings_cleaned;

