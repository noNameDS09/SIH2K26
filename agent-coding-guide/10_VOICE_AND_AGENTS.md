# 10 — Voice and AI agents

## Voice stack

| Role | Vendor | App | Web |
|---|---|---|---|
| STT | Sarvam Saaras v3 (`/speech-to-text`, ≤30s REST) | Direct | FastAPI |
| TTS | Sarvam Bulbul v3 | Direct | FastAPI |
| Translate | Sarvam Translate | Direct or via API | FastAPI |
| Ask + JSON | **Gemini Live** | Direct | FastAPI holds the socket |
| Phrasing advisor sentence | Gemini text JSON (not Live) | FastAPI preferred | FastAPI |

Languages: every code Sarvam lists (hi-IN, bn-IN, ta-IN, te-IN, ml-IN, kn-IN, mr-IN, gu-IN, pa-IN, or-IN/od-IN, as-IN, ur-IN, … + en-IN). Picker shows all. STT `language_code` can be `unknown` for auto-detect.

OTP is not voice.

## Agent A — Live cataloger (required)

Not a chat UI.

System instruction (keep this meaning):

- You interview an artisan about one physical product.
- Ask **one** missing slot at a time in their language.
- Slots: craft, material, technique, time_days_or_hours, colour[], occasion, gi (yes/no/unsure), extra notes.
- Then costing: hours, material_cost_inr or unknown, material_source (own|shop|trader), effort (simple|normal|skilled).
- When you have a value, emit JSON merge. Never overwrite a confirmed slot unless they said galat.
- If they say they don’t know, store `null` and `confidence` low. Do not invent.

Output schema (store under `listing.fields` + bilingual titles/descriptions):

```json
{
  "craft": "",
  "material": "",
  "technique": "",
  "hours": null,
  "colour": [],
  "occasion": "",
  "gi": "yes|no|unsure",
  "material_cost_inr": null,
  "material_source": "",
  "effort": "",
  "title_hi": "",
  "title_en": "",
  "desc_hi": "",
  "desc_en": "",
  "extras": {}
}
```

After JSON is valid enough to show a card: Sarvam TTS reads `title_hi` + `desc_hi`. User: theek hai / galat.

**Working if:** you can complete a listing without typing, JSON is in Firestore, Hindi and English titles exist.

## Agent B — Business advisor (this user only)

Inputs: `artisans/{uid}`, their listings, their sales.

Rules (pure). Examples:

- Demand gap vs `public_trends` (they lack an attribute the cluster is requesting).
- Underpricing: realised < recommended by >10% on ≥3 sales (if no sales yet, skip).
- Stale draft: draft listing older than 24h.
- First publish: congratulate once.

Rank one. Gemini **phrases** that one object into a single sentence in `lang`. If no rule fires, **empty**. Do not fill with generic tips.

**Working if:** publishing a listing changes the Home sentence **or** Home is honestly empty.

## Agent C — Trend analyst (everybody, anonymised)

Admin job (FastAPI cron or Cloud Function, every 15–60 min is enough for demo; also run on-demand after publish):

1. Query `sales` (and if empty, `listing.published` counts by `fields.colour` / craft) for last 30 days.
2. Aggregate. If `n < 20`, set `seed: true` and copy `seed/cluster_seed.json`.
3. Write `public_trends/current`.

Clients only read `public_trends/current`.

**Working if:** two published listings from two test users (or seed) change the trend line; `n` is visible; seed is labelled.

## Provenance

Each agent write includes `provenance.source`:

- `gemini-live-catalog.v1`
- `advisor-rules.v1/<rule_id>`
- `trend-agg.v1`
- `sarvam-saaras-v3` / `sarvam-bulbul-v3`
