# 04 — Features and screens

Build **all of these**. Looks are free. Jobs are not.

## Features (depth)

| Feature | Depth required |
|---|---|
| Language picker | All Sarvam Indic + English. Tile speaks its own name. |
| OTP | Mock `123456`. Badge on screen. |
| Pehchan-shaped profile | Seeded lookup. Store on `artisans/{uid}`. |
| Aadhaar face | Mock camera + badge. |
| Capture | Camera + gallery. Frame guide. |
| Studio | Original \| studio. Six bundled BGs. Quality gate. |
| Live cataloger | Gemini Live asks slots. JSON stored. Confirm by ear. |
| Costing | Hours, materials, source, effort (Live or follow-up). |
| Three-band price | Floor / recommended / aspirational + override. |
| Trend line | From `public_trends`. Show `n`. Seed if `n<20`. |
| Advisor | One sentence from **this** artisan’s docs. Silence allowed. |
| Approve + sign | Freeze listing. HMAC. QR. |
| Share | OS share / Web Share. Not WhatsApp-only. |
| Adapters | GeM / ONDC / IH shaped JSON. Label mocked. |
| Inventory | My listings list. |
| Money | Sales for this artisan. Spoken first. |
| Trade Record | Five bars. Never “credit score”. Unlocks only. |
| Web `/market` | Show catalog of published listings. No cart. |
| Public card | `/v/{id}` QR target. |

## App screens (canonical names)

Use these route/screen names in Flutter.

| ID | Screen | Stage |
|---|---|---|
| `language` | Language | 1 |
| `otp` | Phone OTP | 1 |
| `onboarding` | Namaste / Pehchan / mock Aadhaar / consent | 1 |
| `home` | Today + new product + advisor line | 6 |
| `capture` | Camera / upload + first hold-to-talk | 2 |
| `studio` | Original vs studio + BG presets | 2+ |
| `live_catalog` | Gemini Live Q&A | 2–3 |
| `intelligence` | Draft card + trend + price preview + opportunity | 3 |
| `costing` | If a slot still missing after Live | 3 |
| `pricing` | Three bands + override + net-to-you | 3 |
| `approval` | Hear card, badges, approve | 4 |
| `distribute` | QR, share, mocked adapters | 5 |
| `shop` | Inventory | 5–6 |
| `money` | Sales + Trade Record | 6 |
| `insights` | Advisor history + cluster trends | 6 |
| `settings` | Language, speak-screens, export | — |

**App must not have:** `market`, cart, checkout.

Bottom nav (map to mockup): Home (`home`) · Insights (`insights`) · Channels (`distribute` / share) · Review (`shop`) · Verify (`approval` for current draft).

## Web screens (canonical routes)

| Route | Job |
|---|---|
| `/` | Artisan home (if logged in) or landing → login |
| `/language` `/otp` `/onboarding` | Same jobs as app |
| `/capture` `/studio` `/live` `/intelligence` `/pricing` `/approval` `/distribute` | Same jobs |
| `/shop` `/money` `/insights` `/settings` | Same jobs |
| **`/market`** | **Show catalog (web-only)** |
| `/v/:listingId` | Public card, no auth (`app/v/[listingId]` in Next.js) |

Web look ≠ app look. Same Firestore listing id space.

## Voice commands (tiny grammar)

`theek hai` / `haan` · `galat` / `nahin` · `phir se` · `peeche` · `photo dobara` · `daam <number>`

Live cataloger speech is free-form **answers**, not commands.
