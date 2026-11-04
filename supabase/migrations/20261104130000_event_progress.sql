-- Hatua za mwaliko kwa mpangilio: app inahitaji kujua kama mialiko imekwisha kutumwa (hatua ya 3).
-- "invited" = waalikwa waliotozwa salio, yaani waliotumiwa kwa angalau njia moja.
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
  count(g.id) filter (where g.checked_in_at is not null)        as checked_in,
  count(g.id) filter (where g.charged_at is not null)           as invited
from public.events e
left join public.guests g on g.event_id = e.id
group by e.id;
