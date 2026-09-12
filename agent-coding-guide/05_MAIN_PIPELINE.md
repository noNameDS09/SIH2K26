# 05 — Main pipeline

One listing, start to finish. Both clients implement this. App is the demo path.

```
language → otp → onboarding → home
    → capture → studio
    → live_catalog (Gemini Live → JSON fields)
    → intelligence (card + trend + opportunity)
    → costing (if gaps) → pricing
    → approval (TTS confirm)
    → sign + QR
    → status: published
    → appears on web /market
    → share / mocked adapters
```

## Writes (every successful step)

| Step | Firestore |
|---|---|
| OTP ok | `artisans/{uid}` created if missing |
| Onboarding | profile fields + `lang` + `cluster` |
| Capture | Storage: `original.jpg` → `listings/{id}.originalUrl` |
| Studio | Storage: `studio.jpg` + `deltaE` + `bgPreset` |
| Live JSON | `listings/{id}.fields` merge + `provenance[]` |
| Price | `listings/{id}.prices` + provenance |
| Approve | `status: published`, `signedAt`, `signature`, `qrUrl` |
| Publish | listing readable by `/market` query |

Also append a lightweight `events/{autoId}` `{uid, listingId, kind, ts}` for advisor/trends. Trend **aggregates** still come from Admin job → `public_trends`.

## Event kinds (closed)

`media.captured` `media.enhanced` `listing.drafted` `listing.slot_repaired` `listing.confirmed` `price.computed` `price.overridden` `listing.signed` `listing.published` `insight.generated`

Do not invent parallel pipelines (e.g. “AI service” that never writes Firestore).

## Failure

| Failure | UX |
|---|---|
| No network | Keep local photo/audio. Speak “waiting for network.” Do not fake a listing. |
| Live JSON invalid | Re-ask the missing slot. Do not save empty required fields as guesses. |
| Enhance dE > 2 | Keep original. Tell the user. |
| Vendor 401 | Surface error. Do not hang. |
