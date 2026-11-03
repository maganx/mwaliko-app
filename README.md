# U'r Invente (Mwaliko)

**U'r Invente by Tembo Cloud**: app ya simu (iOS na Android) ya kusimamia mialiko ya matukio: harusi, send-off, kitchen party,
mahafali, siku ya kuzaliwa na matukio ya kikazi. Ni huduma ya SaaS: kila mteja anafungua akaunti yake,
ananunua salio la mialiko na kusimamia matukio yake mwenyewe.

- Tengeneza kadi nzuri kutoka template 12, au acha app ikutengenezee design mpya (michanganyiko 2,000+).
- Pakia design yako mwenyewe, kisha weka jina la mwalikwa na QR code mahali unapotaka.
- Kila mwalikwa anapata kadi yake binafsi (PNG) yenye jina lake na QR yake.
- Tuma kwa **SMS** (Beem Africa au Africa's Talking), **WhatsApp** (Cloud API ya Meta) na **email** (Resend),
  au shiriki kadi moja moja kupitia WhatsApp ya kawaida bila gharama ya API.
- Waalikwa wanathibitisha kuhudhuria (RSVP) kupitia link, na mlangoni QR inaskaniwa (check-in).
- Akaunti za wateja (email + nenosiri), salio la mialiko lililolipiwa kabla, na admin anayethibitisha malipo.

## Bei na salio

| | |
|---|---|
| Bei | **TSh 3,000 kwa mwalikwa** (tukio la watu 200 = TSh 600,000) |
| Kima cha chini | mialiko 10 (TSh 30,000) |
| Vifurushi | 10, 50, 100, 200, 500, au idadi yoyote kuanzia 10 |

- Mwaliko 1 = mwalikwa 1. Mwalikwa anatozwa **mara moja tu**, hata akitumiwa kwa SMS, WhatsApp na email zote,
  na kumtumia tena ni bure. Ukibadilisha simu au email yake, atatozwa tena atakapotumiwa.
- Mwalikwa asiye na simu/email kwa njia ulizochagua hatozwi.
- Salio linakatwa na database (`consume_credits`) kabla ujumbe haujatumwa; likipungua, hakuna kinachotumwa
  (function inarudisha HTTP 402 na app inamwonyesha mteja kitufe cha kuongeza salio).
- Bei zote ziko kwenye jedwali `pricing` (safu moja), kwa hiyo unaweza kubadilisha bei, kima cha chini,
  vifurushi na maelekezo ya malipo bila kubadilisha app:
  ```sql
  update public.pricing set price_per_guest = 2500, min_purchase = 20,
    packages = '{20,100,200,500}', payment_instructions = 'Lipa kwa Lipa Namba 123456 ...' where id = 1;
  ```

### Malipo (kwa sasa ni ya mkono)

1. Mteja anachagua kifurushi kwenye **Salio**, analipa kwa M-Pesa / Mixx by Yas / Airtel Money / HaloPesa / benki,
   kisha anaweka namba ya muamala. Ombi linaingia kwenye `payments` likiwa `pending`.
2. Admin anafungua **Akaunti > Thibitisha malipo**, analinganisha na SMS ya muamala, kisha anabonyeza
   **Thibitisha** (salio la mteja linaongezwa) au **Kataa**.
3. Kumfanya mtu admin (SQL editor ya Supabase):
   ```sql
   update public.profiles set role = 'admin'
    where id = (select id from auth.users where email = 'wewe@domain.co.tz');
   ```

Baadaye, gateway (mf. Selcom, AzamPay au ClickPesa) inaweza kuita `confirm_payment` kupitia webhook
kwa `service_role`, ili malipo yathibitishwe moja kwa moja.

## Brand

Muonekano ni **Aqua glass + orange** (angalia [assets/brand/BRAND.md](assets/brand/BRAND.md)):
asili ya gradient ya aqua, kadi za glass nyeupe nusu-uwazi, vitufe vya orange `#FF7200`, na fonti
Plus Jakarta Sans (vichwa) na Inter (maandishi). Rangi zote ziko kwenye `lib/core/brand_colors.dart`
na zinatumika kupitia `MwalikoColors` kwenye `lib/core/theme.dart`. Ikoni ya app (Android, iOS, web)
imetengenezwa kutoka `assets/brand/app-icon.png`.

## Muundo

```
lib/
  core/        mipangilio, namba za simu, fedha, saa za Kiswahili, theme
  models/      EventModel, Guest, CardConfig, bei/salio/malipo
  data/        repositories za Supabase (akaunti, salio, matukio, waalikwa, kadi, utumaji)
  widgets/     vipande vya muonekano vinavyotumika kila mahali (kadi, kichwa, salio, RSVP)
  features/
    auth/      kuingia na kujisajili (email + nenosiri)
    home/      dashibodi na menyu ya chini (Nyumbani, Matukio, Salio, Akaunti)
    wallet/    salio, kununua mialiko, historia ya malipo na matumizi
    account/   wasifu, bei, kutoka, na admin wa kuthibitisha malipo
    events/    orodha, fomu na ukurasa wa tukio
    guests/    waalikwa: mmoja mmoja, contacts, Excel/CSV, kushiriki kadi
    cards/     template, mapambo (CustomPainter), generator, studio, kutengeneza PNG
    send/      kutuma kwa SMS/WhatsApp/email na historia
    checkin/   kuskani QR mlangoni
supabase/
  migrations/  jedwali, RLS, RPC za RSVP, storage bucket "cards", akaunti, salio na malipo
  tests/       majaribio ya SQL ya salio (yanaendeshwa kwenye Postgres ya kawaida)
  functions/   send-invitations, whatsapp-webhook
rsvp_web/      ukurasa wa RSVP (HTML moja) kwa waalikwa
assets/fonts/  fonts za kadi (SIL Open Font License)
```

## Kuweka mfumo

### 1. Supabase

1. Fungua project mpya kwenye https://supabase.com.
2. Weka schema:
   ```bash
   supabase link --project-ref <PROJECT_REF>
   supabase db push
   ```
3. Auth > Providers > Email: iwe imewashwa (email + nenosiri). Ukiacha "Confirm email" ikiwa imewashwa,
   mteja mpya atapokea email ya kuthibitisha kabla ya kuingia mara ya kwanza.
4. Kila mteja anayejisajili anapata `profiles` na `wallets` (salio 0) moja kwa moja kupitia trigger.

### 2. Watoa huduma wa ujumbe

| Njia | Mtoa huduma | Unachohitaji |
|------|-------------|--------------|
| SMS | [Beem Africa](https://beem.africa) (chaguo-msingi) | API key, Secret key, Sender ID iliyosajiliwa (mf. `MWALIKO`) |
| SMS (mbadala) | [Africa's Talking](https://africastalking.com) | Username, API key, Sender ID |
| WhatsApp | [WhatsApp Cloud API](https://developers.facebook.com/docs/whatsapp/cloud-api) | Phone number ID, access token, template iliyokubaliwa |
| Email | [Resend](https://resend.com) | API key, domain iliyothibitishwa |

**Template ya WhatsApp** (Meta Business Manager > WhatsApp Manager > Message templates):

- Jina: `mwaliko_kadi`, lugha: Swahili (`sw`), aina: Utility au Marketing
- Header: Image
- Body:
  ```
  Habari {{1}}, unakaribishwa kwenye {{2}} tarehe {{3}}.
  Kadi yako ya mwaliko iko hapo juu. Thibitisha kuhudhuria hapa: {{4}}
  ```

### 3. Secrets na functions

```bash
supabase secrets set \
  SMS_PROVIDER=beem BEEM_API_KEY=... BEEM_SECRET_KEY=... BEEM_SENDER_ID=MWALIKO \
  WHATSAPP_PHONE_NUMBER_ID=... WHATSAPP_TOKEN=... WHATSAPP_TEMPLATE_NAME=mwaliko_kadi WHATSAPP_TEMPLATE_LANG=sw \
  WHATSAPP_APP_SECRET=... WHATSAPP_VERIFY_TOKEN=<neno-la-siri-lako> \
  RESEND_API_KEY=... EMAIL_FROM="Mwaliko <mialiko@domain-yako.co.tz>" \
  RSVP_BASE_URL=https://domain-yako.co.tz/rsvp/

supabase functions deploy send-invitations
supabase functions deploy whatsapp-webhook --no-verify-jwt
```

Kwa Africa's Talking badala ya Beem: `SMS_PROVIDER=africastalking AT_USERNAME=... AT_API_KEY=... AT_SENDER_ID=...`.

Kwenye Meta App Dashboard > WhatsApp > Configuration, weka webhook:
`https://<PROJECT_REF>.supabase.co/functions/v1/whatsapp-webhook` na verify token uliyoweka, kisha
jiandikishe kwa field ya `messages` ili app ione "imefika" na "imesomwa".

### 4. Ukurasa wa RSVP

Folda `rsvp_web/` ni ukurasa mmoja wa HTML. Nakili `config.example.js` kuwa `config.js`, weka URL na
publishable key ya Supabase, kisha uweke kwenye hosting yoyote ya static (Netlify, Vercel, Cloudflare Pages,
au hosting ya domain yako). Link yake ndiyo `RSVP_BASE_URL`.

### 5. Kuendesha app

```bash
cp env.example.json env.json   # weka SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, RSVP_BASE_URL
flutter pub get
flutter run --dart-define-from-file=env.json
```

Kujenga kwa ajili ya store:

```bash
flutter build appbundle --dart-define-from-file=env.json   # Google Play
flutter build ipa --dart-define-from-file=env.json         # App Store (inahitaji Mac + Xcode)
```

## Toleo la majaribio (demo)

Demo ina data ya mfano na haihitaji Supabase wala funguo zozote. Hakuna ujumbe unaotumwa kweli.

```bash
flutter run --dart-define=DEMO=true                  # kwenye simu au emulator
flutter run -d chrome --dart-define=DEMO=true        # kwenye kivinjari
flutter build web --dart-define=DEMO=true --no-web-resources-cdn   # kujenga demo ya web
```

Demo inaanza kwenye skrini ya kuingia (email na nenosiri vimeshajazwa). Mteja wa demo ni admin pia,
ili uone skrini ya kuthibitisha malipo. Kununua salio kwenye demo kunathibitishwa moja kwa moja.

## Tests

```bash
flutter analyze
flutter test
SAVE_CARDS=1 flutter test test/card_render_test.dart   # inahifadhi sampuli za kadi kwenye build/card_samples/

# SQL ya salio (Postgres 15+ ya kawaida, si lazima Supabase)
createdb mwtest
psql -d mwtest -v ON_ERROR_STOP=1 -f supabase/tests/supabase_stub.sql \
  -f supabase/migrations/20261103000000_init.sql -f supabase/migrations/20261103120000_saas_billing.sql \
  -f supabase/tests/billing_test.sql
```

## Mambo ya kufuata baadaye

- Login kwa namba ya simu (OTP kwa SMS).
- Gateway ya malipo ili salio liongezwe bila admin (Selcom, AzamPay, ClickPesa n.k.).
- Ukurasa wa admin wa kubadilisha bei ndani ya app.
- Vikumbusho vya moja kwa moja siku chache kabla ya tukio.
- Kutengeneza kadi upande wa server kwa orodha kubwa sana za waalikwa.
