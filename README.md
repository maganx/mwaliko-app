# Mwaliko

App ya simu (iOS na Android) ya kusimamia mialiko ya matukio: harusi, send-off, kitchen party,
mahafali, siku ya kuzaliwa na matukio ya kikazi.

- Tengeneza kadi nzuri kutoka template 12, au acha app ikutengenezee design mpya (michanganyiko 2,000+).
- Pakia design yako mwenyewe, kisha weka jina la mwalikwa na QR code mahali unapotaka.
- Kila mwalikwa anapata kadi yake binafsi (PNG) yenye jina lake na QR yake.
- Tuma kwa **SMS** (Beem Africa au Africa's Talking), **WhatsApp** (Cloud API ya Meta) na **email** (Resend),
  au shiriki kadi moja moja kupitia WhatsApp ya kawaida bila gharama ya API.
- Waalikwa wanathibitisha kuhudhuria (RSVP) kupitia link, na mlangoni QR inaskaniwa (check-in).

## Muundo

```
lib/
  core/        mipangilio, namba za simu, saa za Kiswahili, theme
  models/      EventModel, Guest, CardConfig
  data/        repositories za Supabase (matukio, waalikwa, kadi, utumaji)
  features/
    auth/      kuingia kwa email + namba ya siri (OTP)
    events/    orodha, fomu na ukurasa wa tukio
    guests/    waalikwa: mmoja mmoja, contacts, Excel/CSV, kushiriki kadi
    cards/     template, mapambo (CustomPainter), generator, studio, kutengeneza PNG
    send/      kutuma kwa SMS/WhatsApp/email na historia
    checkin/   kuskani QR mlangoni
supabase/
  migrations/  jedwali, RLS, RPC za RSVP, storage bucket "cards"
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
3. Auth > Providers > Email: washa "Email OTP". Kwenye Email Templates > Magic Link, weka `{{ .Token }}`
   ndani ya ujumbe ili mtumiaji apokee namba ya tarakimu 6.

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

## Tests

```bash
flutter analyze
flutter test
SAVE_CARDS=1 flutter test test/card_render_test.dart   # inahifadhi sampuli za kadi kwenye build/card_samples/
```

## Mambo ya kufuata baadaye

- Login kwa namba ya simu (OTP kwa SMS).
- Malipo (M-Pesa, Tigo Pesa, Airtel Money) kwa vifurushi vya SMS/WhatsApp.
- Vikumbusho vya moja kwa moja siku chache kabla ya tukio.
- Kutengeneza kadi upande wa server kwa orodha kubwa sana za waalikwa.
