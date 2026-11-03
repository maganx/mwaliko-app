# Tovuti ya U'r Invente

Tovuti ya kutangaza U'r Invente (Tembo Cloud). HTML, CSS na JS tupu, bila build.

- `index.html` · maudhui yote
- `styles.css` · rangi na mtindo (Aqua glass + orange, kutoka `assets/brand/tokens.json`)
- `config.js` · **badilisha hapa**: bei kwa mgeni, kiwango cha chini, namba ya WhatsApp, email, link za Play Store / App Store
- `assets/` · nembo (nakala kutoka `assets/brand/`)

## Kuiona kwenye kompyuta

```bash
cd website && python3 -m http.server 8080
# fungua http://localhost:8080
```

## Kuweka live (GitHub Pages)

1. Mara moja tu: GitHub → repo → **Settings → Pages → Source: GitHub Actions**.
2. Kila mabadiliko ya `website/` yakiingia `main`, workflow `.github/workflows/website.yml` inaiweka live.
3. Anwani: `https://maganx.github.io/mwaliko-app/`
4. Domain yako (mf. `urinvente.co.tz`): weka kwenye Settings → Pages → Custom domain, kisha ongeza CNAME kwenye DNS kuelekea `maganx.github.io`.
