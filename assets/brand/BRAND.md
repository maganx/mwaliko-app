# U'r Invente

**Mialiko inayofika, wageni wanaofika.**
*Invites that arrive. Guests who show up.*

U'r Invente ni app ya **Tembo Cloud** ya kutuma kadi za mwaliko kwa wageni kupitia SMS, WhatsApp na barua pepe, na kufuatilia nani amepokea, amekubali au amekataa. Wateja ni wenye sherehe na waandaaji wa matukio (harusi, send-off, kitchen party, mikutano) nchini Tanzania.

Mtindo: **Aqua glass + orange**. Asili ya aqua yenye gradient, kadi za glass (nyeupe nusu-uwazi yenye blur), na orange kwa kila kitendo muhimu.

## Jina

- Andika **U'r Invente** daima: "U" kubwa, apostrofi, "r" ndogo, nafasi, "Invente".
- Usiandike "Ur Invente", "U'R INVENTE" au "YourInvente".
- Kwenye nembo kamili, chini kuna **BY TEMBO CLOUD**.

## Nembo

- **Alama** (`mark.svg`): herufi **U** nene ya orange (#FF7200), na nyota ya sherehe ya `aqua-deep`. U ni "you", mgeni; nyota ni sherehe.
- **Logo kamili** (`logo.svg`): alama + "U'r" kwa `ink` + "Invente" kwa `orange`. Kwa asili nyeupe, aqua au glass.
- **Logo ya giza** (`logo-dark.svg`): kwa asili ya `ink` au dark mode.
- **App icon** (`app-icon.svg`, `app-icon.png` 1024px): asili ya aqua, kioo cha glass katikati, U ya orange. Usiongeze maandishi.
- Acha nafasi kuzunguka nembo angalau sawa na upana wa nyota. Usizungushe, usinyooshe, usibadilishe rangi.

## Rangi

- **Asili ya skrini**: gradient ya `aqua-light` → `aqua` → `lagoon` (135°), na duara 2-3 za `aqua-deep` nyuma ya kadi.
- **Kadi, inputs, tab bar**: `glass` + blur 16-22px + mpaka `glass-border` + `shadow-glass`. Orodha ndefu tumia `glass-strong` ili isomeke.
- **Kitufe kikuu**: `orange` (#FF7200) solid, bila gradient; pressed = `orange-deep`, maandishi `on-orange`, kivuli `shadow-orange`. Kitufe kimoja tu cha orange kwa skrini.
- **Maandishi**: `ink` kwa makuu, `muted` kwa ya pili, `orange-text` kwa viungo vidogo.
- **Hali za mgeni**: Amekubali = `success` juu ya `success-bg`; Inasubiri = `orange-text` juu ya `pending-bg`; Imeshindwa = `danger`.
- Wine, plum na dhahabu za muundo wa zamani hazitumiki tena.

## Herufi

- **Plus Jakarta Sans** 800/700: vichwa, jina la tukio, namba kubwa (128 wamekubali, salio).
- **Inter** 500-700: maandishi mengine yote na vitufe.
- Flutter: `google_fonts` (GoogleFonts.plusJakartaSans, GoogleFonts.inter).

## Glass kwenye Flutter

`ClipRRect` + `BackdropFilter(filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18))` + `Container` yenye rangi `glass` na `Border.all(color: glass-border)`. Weka asili ya gradient kwenye `Scaffold` (backgroundColor transparent juu ya `Container` yenye gradient).

## Sauti ya maandishi

- Kiswahili kwanza, rahisi na cha kirafiki.
- Vitendo moja kwa moja: "Tuma mialiko", "Ongeza mgeni", "Lipia salio".
- Mfano wa SMS: "Habari Amina! Umealikwa kwenye harusi ya Neema & Juma, 14 Des 2026, Mlimani City. Fungua kadi yako: …"
- Makosa yaseme la kufanya: "Salio halitoshi kutuma SMS 200. Ongeza TSh 600,000 kuendelea."

## Tagline

1. Mialiko inayofika, wageni wanaofika. *(kuu)*
2. Kadi yako, mgeni wako, kwa sekunde.
3. Your invite, delivered.
