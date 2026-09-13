# 06 — Data (Firestore + Storage)

Firestore region: **`asia-south1`**. Database id: `(default)` unless the human created another.

Storage: default bucket **`kalasetu-903c2.firebasestorage.app`** in **`US-EAST1`**. Spark/no-cost Storage had no Mumbai option. Documents stay in Mumbai; files live in that bucket.

## Collections

```
artisans/{uid}
  name, phone, lang, cluster, pehchan, consentAt, tradeRecord{}, createdAt

artisans/{uid}/listings/{listingId}
  status: draft | published
  originalUrl, studioUrl, bgPreset, deltaE
  fields: { }          // OPEN MAP — craft-specific keys allowed
  prices: { floor, recommended, aspirational, listed, override }
  provenance: [ ]
  signature, qrUrl, signedAt
  title_hi, title_en, desc_hi, desc_en
  updatedAt

sales/{saleId}                    // top-level, for trends
  artisanId, listingId, craft, colour, cluster, amount, confirmedAt

public_trends/{windowId}          // written by Admin SDK only
  craft, cluster, rising[], n, updatedAt, seed: bool

publishedListings/{listingId}     // denorm for /market (optional but recommended)
  // copy of public fields only (no phone)

events/{eventId}
  artisanId, listingId, kind, ts, payload
```

`fields` examples: saree may have `zari`, `pallu`; brass may have `weight_g`. Do not force one SQL-like schema.

## Who reads what

| Reader | Allowed |
|---|---|
| Artisan client | Own `artisans/{uid}/**` |
| Web `/market` | `publishedListings` where `status==published` (or equivalent public collection) |
| Web `/v/{id}` | That public listing only |
| Trend job | All `sales` via **Admin SDK** → write `public_trends` |
| Advisor | Own listings + own sales only |

## Security rules (intent)

- `request.auth.uid == uid` for artisan private data.
- `publishedListings` readable if `status == published`.
- `public_trends` readable if authenticated (or public if you must for the QR page).
- Clients **cannot** `list()` all `artisans`.

## Files

Firebase Storage paths:

```
artisans/{uid}/listings/{listingId}/original.jpg
artisans/{uid}/listings/{listingId}/studio.jpg
artisans/{uid}/listings/{listingId}/audio.opus
artisans/{uid}/listings/{listingId}/qr.png
```

## Indexes

Expect composite indexes for:

- `publishedListings`: `status` + `updatedAt`
- `sales`: `craft` + `confirmedAt`
- `sales`: `artisanId` + `confirmedAt`

Create them when the first query fails; do not skip the query.

## FastAPI Admin

Service account JSON is server-only (`GOOGLE_APPLICATION_CREDENTIALS` or Firebase Admin from env). Never ship it in Flutter or the Next.js client.
