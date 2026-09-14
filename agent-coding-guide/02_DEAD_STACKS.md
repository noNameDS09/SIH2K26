# 02 — Dead stacks (do not revive)

If you find these in old markdown, **ignore them**.

| Dead | Live |
|---|---|
| Bhashini, Whisper.cpp, Piper, NLLB-200 | Sarvam (Saaras STT, Bulbul TTS, Translate) + Gemini Live / Gemini JSON |
| Gemma-2B as the cataloger | Gemini Live asks questions, returns JSON |
| Postgres + PostGIS | Cloud Firestore `asia-south1` + Firebase Storage `US-EAST1` (Spark default; Mumbai not offered) |
| Web-only PWA, no Flutter | Flutter app **and** Next.js web. App is the hand demo. |
| Vite, vite-plugin-pwa, React SPA | Next.js App Router in `apps/web`. Same jobs, own UI. |
| Flutter last, 6-hour wrapper | App-first sequence (`11_APP_PLAN.md`) |
| One shared visual design system / Geist-only UI | Separate UI per client. Brand name + `#F97316` only. |
| CLIP / heavy CV on device | Quality enhance on **server**. YOLOv8n-seg optional preview only. |
| Live GeM/ONDC/IH | Shaped JSON + **Mock — for SIH demo** |
| Real Aadhaar face-auth | Mock + badge |
| App marketplace / cart | App: none. Web: `/market` show catalog only |
| Chatbot advisor | Rules + one spoken sentence |
| Credit score in UI | Trade Record, five bars, unlocks only |
| Star ratings | Confirmed-delivery counts (later). Not in Stage 1–6 critical path |
| `DemoSIH-main/` as the product | Frozen prototype. Do not extend |

## Partial supersedes (historical)

ADR-001 web-only → two clients.  
ADR-003 pricing math still used; inputs come from Live costing questions.  
ADR-007 PWA-primary → **app is the demo hand-piece**; web is Next.js and still must implement jobs.  
ADR-013 no marketplace → **web show catalog allowed** (ADR-024). Still no cart.  
ADR-015 all keys on server → **app may call Sarvam/Gemini directly**. Web may not.
