-- Mwaliko: schema ya mwanzo (matukio, waalikwa, utumaji, RSVP)

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Matukio (events)
-- ---------------------------------------------------------------------------
create table public.events (
  id            uuid primary key default gen_random_uuid(),
  owner_id      uuid not null default auth.uid() references auth.users (id) on delete cascade,
  title         text not null,
  event_type    text not null default 'harusi',  -- harusi, sendoff, kitchen_party, birthday, graduation, corporate, other
  host_names    text,                            -- mf. "Familia ya Bw. na Bi. Juma"
  event_date    timestamptz not null,
  venue         text,
  venue_map_url text,
  dress_code    text,
  contact_phone text,
  message       text,                            -- maneno ya mwaliko
  card_config   jsonb not null default '{}'::jsonb, -- design iliyochaguliwa (template au custom)
  created_at    timestamptz not null default now()
);

create index events_owner_idx on public.events (owner_id, event_date desc);

-- ---------------------------------------------------------------------------
-- Waalikwa (guests)
-- ---------------------------------------------------------------------------
create table public.guests (
  id            uuid primary key default gen_random_uuid(),
  event_id      uuid not null references public.events (id) on delete cascade,
  name          text not null,
  phone         text,          -- muundo wa kimataifa bila "+", mf. 255712345678
  email         text,
  seats         int  not null default 1 check (seats between 1 and 20),
  category      text,          -- mf. VIP, Familia, Marafiki
  rsvp_status   text not null default 'pending'
                check (rsvp_status in ('pending', 'attending', 'declined', 'maybe')),
  rsvp_seats    int,
  rsvp_note     text,
  rsvp_at       timestamptz,
  rsvp_token    text not null unique default encode(gen_random_bytes(12), 'hex'),
  card_path     text,          -- njia ya kadi yake binafsi kwenye storage (bucket "cards")
  checked_in_at timestamptz,
  created_at    timestamptz not null default now()
);

create index guests_event_idx on public.guests (event_id, name);

-- ---------------------------------------------------------------------------
-- Utumaji (deliveries): kila jaribio la kutuma kwa kila njia
-- ---------------------------------------------------------------------------
create table public.deliveries (
  id                  uuid primary key default gen_random_uuid(),
  event_id            uuid not null references public.events (id) on delete cascade,
  guest_id            uuid not null references public.guests (id) on delete cascade,
  channel             text not null check (channel in ('sms', 'whatsapp', 'email')),
  status              text not null default 'queued'
                      check (status in ('queued', 'sent', 'delivered', 'read', 'failed')),
  provider_message_id text,
  error               text,
  created_at          timestamptz not null default now()
);

create index deliveries_event_idx on public.deliveries (event_id, created_at desc);
create index deliveries_provider_idx on public.deliveries (provider_message_id);

-- ---------------------------------------------------------------------------
-- Row Level Security: mwenye tukio peke yake ndiye anaona data yake
-- ---------------------------------------------------------------------------
alter table public.events enable row level security;
alter table public.guests enable row level security;
alter table public.deliveries enable row level security;

create policy "events: owner all" on public.events
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create policy "guests: owner all" on public.guests
  for all using (
    exists (select 1 from public.events e where e.id = event_id and e.owner_id = auth.uid())
  ) with check (
    exists (select 1 from public.events e where e.id = event_id and e.owner_id = auth.uid())
  );

create policy "deliveries: owner read" on public.deliveries
  for select using (
    exists (select 1 from public.events e where e.id = event_id and e.owner_id = auth.uid())
  );

-- ---------------------------------------------------------------------------
-- RSVP ya umma: mwalikwa anatumia token yake tu (hakuna login)
-- ---------------------------------------------------------------------------
create or replace function public.rsvp_lookup(p_token text)
returns json
language sql
security definer
set search_path = public
as $$
  select json_build_object(
    'guest_name',   g.name,
    'seats',        g.seats,
    'rsvp_status',  g.rsvp_status,
    'rsvp_seats',   g.rsvp_seats,
    'card_path',    g.card_path,
    'event_title',  e.title,
    'host_names',   e.host_names,
    'event_date',   e.event_date,
    'venue',        e.venue,
    'venue_map_url',e.venue_map_url,
    'dress_code',   e.dress_code,
    'contact_phone',e.contact_phone,
    'message',      e.message
  )
  from public.guests g
  join public.events e on e.id = g.event_id
  where g.rsvp_token = p_token;
$$;

create or replace function public.rsvp_respond(
  p_token  text,
  p_status text,
  p_seats  int default null,
  p_note   text default null
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_guest public.guests;
begin
  if p_status not in ('attending', 'declined', 'maybe') then
    raise exception 'status si sahihi: %', p_status;
  end if;

  update public.guests
     set rsvp_status = p_status,
         rsvp_seats  = case when p_status = 'declined' then 0
                            else least(coalesce(p_seats, seats), seats) end,
         rsvp_note   = left(p_note, 500),
         rsvp_at     = now()
   where rsvp_token = p_token
  returning * into v_guest;

  if v_guest.id is null then
    raise exception 'mwaliko haukupatikana';
  end if;

  return json_build_object('ok', true, 'rsvp_status', v_guest.rsvp_status, 'rsvp_seats', v_guest.rsvp_seats);
end;
$$;

revoke all on function public.rsvp_lookup(text) from public;
revoke all on function public.rsvp_respond(text, text, int, text) from public;
grant execute on function public.rsvp_lookup(text) to anon, authenticated;
grant execute on function public.rsvp_respond(text, text, int, text) to anon, authenticated;

-- Takwimu za tukio kwa skrini ya app
create or replace view public.event_stats
with (security_invoker = true) as
select
  e.id as event_id,
  count(g.id)                                                   as guests,
  coalesce(sum(g.seats), 0)                                     as seats,
  count(g.id) filter (where g.rsvp_status = 'attending')        as attending,
  count(g.id) filter (where g.rsvp_status = 'declined')         as declined,
  count(g.id) filter (where g.rsvp_status = 'maybe')            as maybe,
  count(g.id) filter (where g.rsvp_status = 'pending')          as pending,
  count(g.id) filter (where g.checked_in_at is not null)        as checked_in
from public.events e
left join public.guests g on g.event_id = e.id
group by e.id;

-- ---------------------------------------------------------------------------
-- Storage: bucket "cards" (kadi za waalikwa na design za wateja)
-- Njia: {owner_id}/{event_id}/design.png  na  {owner_id}/{event_id}/guests/{guest_id}.png
-- Bucket ni public ili WhatsApp/email ziweze kupakua picha kwa link.
-- Njia zina UUID zisizokisiwa.
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('cards', 'cards', true)
on conflict (id) do nothing;

create policy "cards: owner select" on storage.objects
  for select to authenticated
  using (bucket_id = 'cards' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "cards: owner insert" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'cards' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "cards: owner update" on storage.objects
  for update to authenticated
  using (bucket_id = 'cards' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "cards: owner delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'cards' and (storage.foldername(name))[1] = auth.uid()::text);
