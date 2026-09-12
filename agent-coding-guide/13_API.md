# 13 — FastAPI

Package: `apps/api` · run via Docker or `uvicorn kalasetu_api.main:app --app-dir src`.

## Env

See repo `.env.example`. Required for real features:

- `SARVAM_API_KEY`
- `GEMINI_API_KEY`
- `OTP_PROVIDER=mock`
- Firebase Admin credentials
- `PUBLIC_BASE_URL` (ngrok or domain for QR)

## Endpoints to implement (names are the contract)

| Method | Path | Auth | Does |
|---|---|---|---|
| GET | `/health` | no | `{ok: true}` |
| POST | `/v1/auth/otp` | no | mock or 2factor |
| POST | `/v1/auth/verify` | no | returns `token` + Firebase custom token |
| POST | `/v1/images/enhance` | yes | quality studio JPEG + deltaE |
| POST | `/v1/speech/stt` | yes | Sarvam |
| POST | `/v1/speech/tts` | yes | Sarvam |
| POST | `/v1/speech/live/turn` | yes | Web Live turn: audio in, JSON+tts out |
| POST | `/v1/listings/{id}/price` | yes | three bands from fields + seed/comparables |
| POST | `/v1/listings/{id}/sign` | yes | HMAC, QR png, publishedListings copy |
| GET | `/v/{id}` | no | public card JSON or HTML |
| POST | `/v1/trends/recompute` | admin | rebuild `public_trends/current` |

Keep OpenAPI in `packages/contracts/openapi.yaml` in sync when you add a path.

## Pricing math (do not replace with a black box)

```
floor = material_cost_inr (or seed) + hours * cluster_wage * effort_factor + overhead
recommended = clamp(floor * 1.4, band_low, band_high)
aspirational = band_high * (1 + gi_premium + scarcity)
```

`cluster_wage` from `seed/wages.csv` keyed by cluster/craft. Band from `seed/comparables.csv` or Firestore comparables. Provenance on each number.

## Enhance

See `09_IMAGE_PIPELINE.md`. This is the quality bottleneck. Prefer ISNet/BiRefNet weights on the server, CPU ok for demo latency if <5s.

## Admin

Use Firebase Admin to:

- Mint custom tokens
- Write `publishedListings` on sign
- Recompute trends
- Never expose Admin to clients
