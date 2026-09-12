# KalaSetu agent-coding-guide

**This folder is the source of truth for every coding agent in every environment.**

Do not follow `PROJECT_CONTEXT.md`, `sih-understanding/`, or old ADRs when they disagree with these files. Those are pitch/research. This folder is what you implement.

If two files in `agent-coding-guide/` conflict, follow `00_AGENT_RULES.md`, then log the clash in `docs/OPEN_QUESTIONS.md`.

---

## Read order (mandatory before writing code)

| Order | File | When |
|---|---|---|
| 1 | [00_AGENT_RULES.md](00_AGENT_RULES.md) | Always |
| 2 | [01_CONTEXT.md](01_CONTEXT.md) | Always |
| 3 | [02_DEAD_STACKS.md](02_DEAD_STACKS.md) | Always |
| 4 | [03_REPO.md](03_REPO.md) | Always |
| 5 | [04_FEATURES_AND_SCREENS.md](04_FEATURES_AND_SCREENS.md) | Always |
| 6 | [05_MAIN_PIPELINE.md](05_MAIN_PIPELINE.md) | Always |
| 7 | [06_DATA.md](06_DATA.md) | Always |
| 8 | [07_APP_ARCHITECTURE.md](07_APP_ARCHITECTURE.md) | App work |
| 9 | [08_WEB_ARCHITECTURE.md](08_WEB_ARCHITECTURE.md) | Web work |
| 10 | [09_IMAGE_PIPELINE.md](09_IMAGE_PIPELINE.md) | Photo / studio |
| 11 | [10_VOICE_AND_AGENTS.md](10_VOICE_AND_AGENTS.md) | Speech, Live, advisor, trends |
| 12 | [11_APP_PLAN.md](11_APP_PLAN.md) | Building the Flutter app |
| 13 | [12_WEB_PLAN.md](12_WEB_PLAN.md) | Building the PWA |
| 14 | [13_API.md](13_API.md) | FastAPI |
| 15 | [14_FAQ.md](14_FAQ.md) | Before inventing a new approach |

---

## Scope of the first build (locked as B)

Full mockup stages 1–6 plus the extra screens in `04_FEATURES_AND_SCREENS.md`.

Not a tiny photo-only slice. Sequence still matters: follow `11_APP_PLAN.md` / `12_WEB_PLAN.md`. Do not start on Stage 6 Home before Stage 2 capture writes a listing.

---

## One-line product

Artisan photographs and speaks. KalaSetu writes a bilingual listing, a three-band price, and a QR. The **app never is a shop**. The **web has a show catalog** so a listing published on the phone appears on the website. No cart. No payment on KalaSetu.
