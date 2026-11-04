-- Usalama (kutoka kwenye Supabase security advisor):
-- functions za trigger haziitwi kupitia API, na zile za wateja walioingia haziitwi bila kuingia.
alter function public.guests_reset_charge() set search_path = public;

revoke execute on function public.handle_new_user() from anon, authenticated;
revoke execute on function public.guests_reset_charge() from anon, authenticated;

revoke execute on function public.request_credit_purchase(int, text, text, text) from anon;
revoke execute on function public.confirm_payment(uuid, text) from anon;
revoke execute on function public.reject_payment(uuid) from anon;
revoke execute on function public.consume_credits(uuid, uuid[]) from anon;
