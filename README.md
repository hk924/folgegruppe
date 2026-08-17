# Følgegruppa, produksjon

Samme app som før. Eneste endring: den lagrer i din egen Supabase database
i stedet for Claudes lagring, og kjører på din egen Vercel adresse.

## 1. Supabase

1. Gå til supabase.com, logg inn, opprett et nytt gratis prosjekt.
2. Gå til SQL Editor, lim inn innholdet i `supabase_schema.sql`, kjør det.
3. Gå til Settings, API. Kopier Project URL og anon public key.
4. Åpne `index.html`, bytt ut de to linjene nær toppen:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`

## 2. Legg koden på GitHub

```
cd folgegruppe
git init
git add .
git commit -m "Følgegruppa produksjon"
gh repo create folgegruppe --public --source=. --push
```

Har du ikke `gh`, opprett et tomt repo på github.com og følg
instruksjonene den gir deg for å pushe et eksisterende repo.

## 3. Vercel

1. Gå til vercel.com, logg inn, New Project.
2. Velg repoet du nettopp pushet.
3. Ingen build innstillinger er nødvendig, det er en ren HTML fil.
   La Framework Preset stå på "Other" og trykk Deploy.
4. Du får en adresse på formen folgegruppe.vercel.app. Den kan du
   dele direkte, eller koble til et eget domene under Settings, Domains.

## Etterpå

Endringer i appen: rediger `index.html`, commit, push. Vercel deployer
automatisk på nytt hver gang du pusher til hovedgrenen.

Dataene ligger i Supabase, ikke i Vercel eller i koden, så de overlever
enhver ny deploy.
