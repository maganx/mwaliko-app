-- Mwaliko SaaS: akaunti za wateja, salio la mialiko (credits), malipo na bei inayobadilika.
-- 1 credit = mwalikwa 1 (njia zote: SMS, WhatsApp, email). Kumtumia tena mwalikwa yule yule hakumtozi tena.

-- ---------------------------------------------------------------------------
-- Bei (safu moja tu). Badilisha hapa bila kubadilisha app.
-- ---------------------------------------------------------------------------
create table public.pricing (
  id              int primary key default 1 check (id = 1),
  currency        text not null default 'TZS',
  price_per_guest int  not null default 3000 check (price_per_guest > 0),
  min_purchase    int  not null default 10 check (min_purchase > 0),
  packages        int[] not null default '{10,50,100,200,500}',
  -- Namba ya kulipia (Lipa Namba / till) inayoonyeshwa kwa mteja wakati wa malipo ya mkono
  payment_instructions text not null default 'Lipa kwa M-Pesa Lipa Namba 000000 (Mwaliko), kisha weka namba ya muamala.',
  updated_at      timestamptz not null default now()
);
insert into public.pricing (id) values (1) on conflict (id) do nothing;

alter table public.pricing enable row level security;
create policy "pricing: read" on public.pricing for select to anon, authenticated using (true);

-- ---------------------------------------------------------------------------
-- Wasifu wa mteja (profile)
-- ---------------------------------------------------------------------------
create table public.profiles (
  id            uuid primary key references auth.users (id) on delete cascade,
  full_name     text,
  business_name text,
  phone         text,
  role          text not null default 'customer' check (role in ('customer', 'admin')),
  created_at    timestamptz not null default now()
);

alter table public.profiles enable row level security;
create policy "profiles: own read" on public.profiles for select using (id = auth.uid());
create policy "profiles: own update" on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());
-- Mteja hawezi kujibadilishia "role"
revoke update on public.profiles from authenticated;
grant update (full_name, business_name, phone) on public.profiles to authenticated;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

create policy "profiles: admin read" on public.profiles for select using (public.is_admin());

-- ---------------------------------------------------------------------------
-- Salio (wallet) na historia (ledger)
-- ---------------------------------------------------------------------------
create table public.wallets (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  credits    int not null default 0 check (credits >= 0),
  updated_at timestamptz not null default now()
);

alter table public.wallets enable row level security;
create policy "wallets: own read" on public.wallets for select using (user_id = auth.uid());

create table public.payments (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid() references auth.users (id) on delete cascade,
  credits      int  not null check (credits > 0),
  amount       int  not null check (amount > 0),
  currency     text not null default 'TZS',
  method       text not null,              -- mpesa, mixx, airtel, halopesa, card, bank
  phone        text,
  reference    text,                       -- namba ya muamala kutoka kwa mteja au gateway
  provider     text not null default 'manual',
  status       text not null default 'pending' check (status in ('pending', 'paid', 'failed', 'cancelled')),
  created_at   timestamptz not null default now(),
  paid_at      timestamptz
);

create index payments_user_idx on public.payments (user_id, created_at desc);
create index payments_status_idx on public.payments (status, created_at);

alter table public.payments enable row level security;
create policy "payments: own read" on public.payments for select using (user_id = auth.uid());
create policy "payments: admin read" on public.payments for select using (public.is_admin());

create table public.credit_transactions (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users (id) on delete cascade,
  kind       text not null check (kind in ('purchase', 'usage', 'bonus', 'refund', 'adjustment')),
  credits    int  not null,               -- + kuongeza, - kutumia
  amount     int,                         -- TZS (kwa manunuzi)
  event_id   uuid references public.events (id) on delete set null,
  payment_id uuid references public.payments (id) on delete set null,
  note       text,
  created_at timestamptz not null default now()
);

create index credit_tx_user_idx on public.credit_transactions (user_id, created_at desc);

alter table public.credit_transactions enable row level security;
create policy "credit_tx: own read" on public.credit_transactions for select using (user_id = auth.uid());

-- Mwalikwa ametozwa lini (ili kumtumia tena kusimtoze mara ya pili)
alter table public.guests add column charged_at timestamptz;

-- App haiwezi kuandika charged_at, rsvp_token wala event_id ya mwalikwa aliyepo; ni functions za server tu.
revoke insert, update on public.guests from authenticated;
grant insert (event_id, name, phone, email, seats, category) on public.guests to authenticated;
grant update (name, phone, email, seats, category, rsvp_status, rsvp_seats, rsvp_note, card_path, checked_in_at)
  on public.guests to authenticated;

-- Ukibadilisha simu au email ya mwalikwa aliyetozwa, ni mtu mpya: atatozwa tena akitumiwa.
create or replace function public.guests_reset_charge()
returns trigger language plpgsql as $$
begin
  if old.charged_at is not null
     and (new.phone is distinct from old.phone or new.email is distinct from old.email) then
    new.charged_at := null;
  end if;
  return new;
end;
$$;

create trigger guests_reset_charge
  before update on public.guests
  for each row execute function public.guests_reset_charge();

-- ---------------------------------------------------------------------------
-- Mtumiaji mpya: tengeneza profile na wallet
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name, business_name, phone)
  values (
    new.id,
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'business_name',
    new.raw_user_meta_data ->> 'phone'
  )
  on conflict (id) do nothing;
  insert into public.wallets (user_id) values (new.id) on conflict (user_id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Kuomba kununua mialiko. Bei inahesabiwa hapa (server), si kwenye app.
-- ---------------------------------------------------------------------------
create or replace function public.request_credit_purchase(
  p_credits   int,
  p_method    text,
  p_phone     text default null,
  p_reference text default null
)
returns public.payments
language plpgsql security definer set search_path = public as $$
declare
  v_price public.pricing;
  v_payment public.payments;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  select * into v_price from public.pricing where id = 1;
  if p_credits is null or p_credits < v_price.min_purchase then
    raise exception 'min_purchase:%', v_price.min_purchase;
  end if;
  if p_credits > 100000 then raise exception 'too_many_credits'; end if;

  insert into public.payments (user_id, credits, amount, currency, method, phone, reference)
  values (auth.uid(), p_credits, p_credits * v_price.price_per_guest, v_price.currency, p_method, p_phone, left(p_reference, 64))
  returning * into v_payment;
  return v_payment;
end;
$$;

-- Admin anathibitisha malipo (au gateway kupitia service role) -> salio linaongezeka.
create or replace function public.confirm_payment(p_payment_id uuid, p_reference text default null)
returns public.payments
language plpgsql security definer set search_path = public as $$
declare
  v_payment public.payments;
begin
  if not public.is_admin() and coalesce(auth.role(), '') <> 'service_role' then
    raise exception 'admin_only';
  end if;

  update public.payments
     set status = 'paid', paid_at = now(), reference = coalesce(p_reference, reference)
   where id = p_payment_id and status = 'pending'
  returning * into v_payment;
  if v_payment.id is null then raise exception 'payment_not_pending'; end if;

  insert into public.wallets (user_id, credits) values (v_payment.user_id, v_payment.credits)
  on conflict (user_id) do update set credits = public.wallets.credits + excluded.credits, updated_at = now();

  insert into public.credit_transactions (user_id, kind, credits, amount, payment_id, note)
  values (v_payment.user_id, 'purchase', v_payment.credits, v_payment.amount, v_payment.id,
          'Umenunua mialiko ' || v_payment.credits);
  return v_payment;
end;
$$;

create or replace function public.reject_payment(p_payment_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'admin_only'; end if;
  update public.payments set status = 'failed' where id = p_payment_id and status = 'pending';
end;
$$;

-- ---------------------------------------------------------------------------
-- Kukata salio kabla ya kutuma. Inatoza waalikwa ambao hawajawahi kutozwa tu.
-- Inarudisha idadi iliyotozwa; inakataa kama salio halitoshi.
-- ---------------------------------------------------------------------------
create or replace function public.consume_credits(p_event_id uuid, p_guest_ids uuid[])
returns int
language plpgsql security definer set search_path = public as $$
declare
  v_owner uuid;
  v_needed int;
  v_credits int;
begin
  select owner_id into v_owner from public.events where id = p_event_id;
  if v_owner is null or v_owner <> auth.uid() then raise exception 'event_not_found'; end if;

  select count(*) into v_needed
    from public.guests
   where event_id = p_event_id and id = any (p_guest_ids) and charged_at is null;
  if v_needed = 0 then return 0; end if;

  select credits into v_credits from public.wallets where user_id = v_owner for update;
  if coalesce(v_credits, 0) < v_needed then
    raise exception 'insufficient_credits:%:%', v_needed, coalesce(v_credits, 0);
  end if;

  update public.wallets set credits = credits - v_needed, updated_at = now() where user_id = v_owner;
  update public.guests set charged_at = now()
   where event_id = p_event_id and id = any (p_guest_ids) and charged_at is null;
  insert into public.credit_transactions (user_id, kind, credits, event_id, note)
  values (v_owner, 'usage', -v_needed, p_event_id, 'Mialiko ' || v_needed || ' imetumwa');
  return v_needed;
end;
$$;

revoke all on function public.request_credit_purchase(int, text, text, text) from public;
revoke all on function public.confirm_payment(uuid, text) from public;
revoke all on function public.reject_payment(uuid) from public;
revoke all on function public.consume_credits(uuid, uuid[]) from public;
grant execute on function public.request_credit_purchase(int, text, text, text) to authenticated;
grant execute on function public.confirm_payment(uuid, text) to authenticated, service_role;
grant execute on function public.reject_payment(uuid) to authenticated;
grant execute on function public.consume_credits(uuid, uuid[]) to authenticated;

-- Kumfanya mtu admin (endesha kwenye SQL editor ya Supabase):
--   update public.profiles set role = 'admin' where id = (select id from auth.users where email = 'wewe@domain.co.tz');
