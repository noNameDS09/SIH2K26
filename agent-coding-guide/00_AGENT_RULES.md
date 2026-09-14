# 00 — Agent rules

Break these and the PR is wrong even if it “works.”

## Identity

- Product: **KalaSetu**. PS **SIH26090**. MoSJE.
- You are a coding agent. Humans are not the audience of this folder.
- Restate the task in one sentence, then implement. Do not re-debate locked choices.

## Source of truth

1. `agent-coding-guide/` (this folder)
2. User message in the current turn
3. Nothing else overrides (1) unless the user explicitly changes a lock in this turn

Pitch files (`PROJECT_CONTEXT.md`, `sih-understanding/`, old ADRs) are **not** instructions.

## Do

- Put new product code in `apps/api`, `apps/mobile`, `apps/web` only.
- Show `{source, confidence, ts}` on every AI value (price, transcript, slot, trend, advisor line).
- Label mocks on screen: `Mock — for SIH demo` (Aadhaar, live GeM/ONDC/IH).
- OTP: keypad. Default code `123456`. No voice OTP.
- After OTP: voice is the default input. Text is fallback.
- Languages: **all Sarvam Indic codes + English** in the picker. Auto-detect on STT if they skip.
- Firestore region: **`asia-south1` (Mumbai)**. If that region cannot be created, stop and tell the human. Do not silently pick `us-central1`.
- Storage: Spark/no-cost default bucket is **`US-EAST1`** (`kalasetu-903c2.firebasestorage.app`). Mumbai is not offered on that plan. Do not treat this as permission to move Firestore out of Mumbai.
- FastAPI exists from day one (OTP, enhance, web speech, sign, market feed).
- App may call Sarvam + Gemini Live **directly** with gitignored keys.
- Web calls Sarvam + Gemini **only** through FastAPI.
- Image output must pass the quality gate in `09_IMAGE_PIPELINE.md`. Pretty-bad cut-outs are not “done.”
- If a feature exists on the app, the web can do the same **job** (except the show catalog is web-only). Looks may differ.
- Web is **Next.js App Router** in `apps/web`. Do not add Vite.
- After each milestone in `11_APP_PLAN.md` / `12_WEB_PLAN.md`, run that milestone’s **Working if** checks before starting the next.

## Do not

- Do not write product code in `DemoSIH-main/`.
- Do not add React Native.
- Do not add Vite. Web is Next.js.
- Do not add Bhashini, Whisper.cpp, Piper, NLLB, Gemma-2B, Postgres, or PostGIS.
- Do not add a cart, checkout, or payment on app **or** web.
- Do not add a marketplace tab on the **app**.
- Do not build a chatbot / blank prompt.
- Do not generate or download backgrounds. Use the six bundled presets.
- Do not change product hue/chroma. Light only. If colour-delta fails, keep the original photo.
- Do not commit `.env`, `apps/mobile/.env`, `google-services.json` with secrets beyond the usual Firebase public config, or vendor API keys.
- Do not query all `artisans` from a client SDK. Trends go through Admin SDK → `public_trends`.
- Do not invent a second listing schema. Listing documents are the schema (`fields` map).
- Do not claim live GeM/ONDC/IndiaHandmade writes.
- Do not use star ratings.
- Do not call the Trade Record a “credit score” in any UI string.
- Do not announce “beginner mode” to the user.

## Marketplace (precise)

| Surface | Allowed |
|---|---|
| App | Publish, share, QR. **No shop, no browse-all, no cart.** |
| Web `/market` | **Show catalog** of `status == published` listings. Tap opens public card. **No cart, no pay, no buyer accounts.** |
| Web `/v/{listingId}` | Public card (QR target). |

A listing saved on the app with `status: published` **must** appear on web `/market` after refresh (or snapshot). That is the demo punch.

## Provenance shape (mandatory)

```json
{
  "value": {},
  "provenance": {
    "source": "sarvam-saaras-v3",
    "version": "3",
    "confidence": 0.91,
    "ts": "2026-09-13T00:00:00+05:30"
  }
}
```

Never render `value` without a way to see provenance.

## When you finish a change

State: path of files, how to verify (the **Working if** line), and any mock still in place.

## When you are blocked

Stop. Name the missing key, region, or decision. Do not stub a fake GeM live integration. Mock + label is required instead.
