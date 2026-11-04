-- Majaribio ya salio na malipo. Endesha baada ya supabase_stub.sql na migrations.
\set ON_ERROR_STOP on
set client_min_messages = warning;

insert into auth.users (id, email, raw_user_meta_data) values
  ('00000000-0000-0000-0000-00000000000a', 'mteja@example.com', '{"full_name":"Asha","business_name":"Asha Events"}'),
  ('00000000-0000-0000-0000-0000000000ad', 'admin@example.com', '{}');
update public.profiles set role = 'admin' where id = '00000000-0000-0000-0000-0000000000ad';

do $$ begin
  assert (select business_name from public.profiles where id = '00000000-0000-0000-0000-00000000000a') = 'Asha Events', 'profile';
  assert (select credits from public.wallets where user_id = '00000000-0000-0000-0000-00000000000a') = 0, 'wallet';
end $$;

-- Mteja
set role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000000a', false);

-- kima cha chini 10
do $$ begin
  perform public.request_credit_purchase(9, 'mpesa');
  raise exception 'should have failed';
exception when others then
  assert sqlerrm like 'min_purchase:10%', sqlerrm;
end $$;

-- 200 mialiko = 600,000
select amount from public.request_credit_purchase(200, 'mpesa', '255712345678', 'QWE123');
do $$ begin
  assert (select amount from public.payments order by created_at desc limit 1) = 600000, 'bei';
end $$;

-- mteja hawezi kuthibitisha malipo yake mwenyewe
do $$ begin
  perform public.confirm_payment((select id from public.payments limit 1));
  raise exception 'should have failed';
exception when others then
  assert sqlerrm = 'admin_only', sqlerrm;
end $$;

-- mteja hawezi kujifanya admin
do $$ begin
  update public.profiles set role = 'admin' where id = auth.uid();
  raise exception 'should have failed';
exception when insufficient_privilege then null;
end $$;

-- Admin anathibitisha
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000000ad', false);
select status from public.confirm_payment((select id from public.payments limit 1));

-- Mteja: salio 200, tukio na waalikwa 3
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000000a', false);
do $$ begin
  assert (select credits from public.wallets) = 200, 'salio baada ya kununua';
end $$;

insert into public.events (id, title, event_date) values
  ('00000000-0000-0000-0000-0000000000e1', 'Harusi', now() + interval '30 days');
insert into public.guests (event_id, name, phone) values
  ('00000000-0000-0000-0000-0000000000e1', 'A', '255700000001'),
  ('00000000-0000-0000-0000-0000000000e1', 'B', '255700000002'),
  ('00000000-0000-0000-0000-0000000000e1', 'C', '255700000003');

-- mteja hawezi kujiwekea charged_at (kukwepa malipo)
do $$ begin
  update public.guests set charged_at = now();
  raise exception 'should have failed';
exception when insufficient_privilege then null;
end $$;

-- kutuma kwa 3: salio 197
do $$ declare n int; begin
  n := public.consume_credits('00000000-0000-0000-0000-0000000000e1',
         array(select id from public.guests where event_id = '00000000-0000-0000-0000-0000000000e1'));
  assert n = 3, 'charged ' || n;
  assert (select credits from public.wallets) = 197, 'salio 197';
end $$;

-- kutuma tena: bure
do $$ declare n int; begin
  n := public.consume_credits('00000000-0000-0000-0000-0000000000e1',
         array(select id from public.guests where event_id = '00000000-0000-0000-0000-0000000000e1'));
  assert n = 0, 'resend charged ' || n;
  assert (select credits from public.wallets) = 197, 'salio bado 197';
end $$;

-- kubadilisha simu = mtu mpya, anatozwa tena
update public.guests set phone = '255799999999' where name = 'A';
do $$ declare n int; begin
  n := public.consume_credits('00000000-0000-0000-0000-0000000000e1',
         array(select id from public.guests where event_id = '00000000-0000-0000-0000-0000000000e1'));
  assert n = 1, 'phone change charged ' || n;
  assert (select credits from public.wallets) = 196, 'salio 196';
  assert (select sum(credits) from public.credit_transactions) = 196, 'ledger inalingana na salio';
end $$;

-- salio halitoshi
reset role;
update public.wallets set credits = 1 where user_id = '00000000-0000-0000-0000-00000000000a';
update public.guests set charged_at = null;
set role authenticated;
do $$ begin
  perform public.consume_credits('00000000-0000-0000-0000-0000000000e1',
         array(select id from public.guests where event_id = '00000000-0000-0000-0000-0000000000e1'));
  raise exception 'should have failed';
exception when others then
  assert sqlerrm = 'insufficient_credits:3:1', sqlerrm;
end $$;
do $$ begin
  assert (select credits from public.wallets) = 1, 'salio halikukatwa';
  assert (select count(*) from public.guests where charged_at is not null) = 0, 'hakuna aliyetozwa';
end $$;

-- mtu mwingine hawezi kutumia tukio lisilo lake
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000000ad', false);
do $$ begin
  perform public.consume_credits('00000000-0000-0000-0000-0000000000e1', array[]::uuid[]);
  raise exception 'should have failed';
exception when others then
  assert sqlerrm = 'event_not_found', sqlerrm;
end $$;

-- RSVP ya umma bado inafanya kazi
reset role;
do $$ declare t text; r json; begin
  select rsvp_token into t from public.guests where name = 'B';
  set local role anon;
  r := public.rsvp_respond(t, 'attending', 1);
  assert r ->> 'rsvp_status' = 'attending', 'rsvp';
end $$;

\echo 'MAJARIBIO YOTE YA SALIO YAMEPITA'
