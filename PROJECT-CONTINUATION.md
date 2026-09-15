# KalaSetu — Project Continuation Notes

Updated: 2026-09-15

This file is the handoff point for continuing KalaSetu without reconstructing the current project context.

## Product shape

KalaSetu is a voice-first artisan workspace. The main product journey is:

```text
Capture → Studio → Describe → Review → Price → Approve → Published
```

The public side includes the landing page, marketplace/catalog browsing, and public listing cards. The internal side is an authenticated artisan workspace.

## Current frontend structure

The Next.js app lives at `apps/web`.

Important frontend files:

- `apps/web/src/app/page.tsx` — landing route.
- `apps/web/src/components/landing-page.tsx` — landing composition and hero copy.
- `apps/web/src/components/artisan-workspace.tsx` — workspace route switch.
- `apps/web/src/components/workspace/workspace-ui.tsx` — shared workspace shell, grouped navigation, creation rail, actions, provenance, empty/loading states, and motion.
- `apps/web/src/components/workspace/access-pages.tsx` — language, OTP, and onboarding.
- `apps/web/src/components/workspace/creation-pages.tsx` — capture, studio, live cataloger, intelligence, pricing, approval, distribution.
- `apps/web/src/components/workspace/management-pages.tsx` — home, catalog, money, insights, settings.
- `apps/web/src/lib/api-client.ts` — frontend-to-FastAPI client.
- `apps/web/src/lib/firebase-client.ts` — Firebase custom-token browser session.
- `apps/web/src/app/globals.css`, `workspace.css`, and `workspace-pages.css` — shared visual system and workspace styling.

## Navigation decision

Pipeline pages are intentionally not listed as separate sidebar destinations. The sidebar contains workspace/management routes only. The creation rail is the single source of truth for:

```text
Capture, Studio, Describe, Review, Price, Approve, Published
```

## Design direction

- KalaSetu cream, olive, sage, brown, and peach palette.
- Serif display headings with readable sans-serif body text.
- Voice-first, low-literacy-friendly interaction patterns.
- AI values must retain visible provenance.
- Mock values must be labelled `Mock — for SIH demo`.
- Artwork belongs at page edges, rails, transitions, and empty states; it must not obscure controls or product media.
- Supporting assets are in `apps/web/public/assets`.
- New internal-page artwork is route-specific and should dissolve into the page background using masking/blending rather than look like a pasted photograph.

## Asset library

The supplied asset library is documented in:

- `apps/web/public/assets/README.txt`
- `apps/web/public/assets/INDEX.txt`

Use the provided illustrations, motifs, landscapes, logos, and patterns selectively. Do not reuse the same motif repeatedly when another suitable asset exists.

## Backend and persistence

The FastAPI app lives at `apps/api` and exposes auth, listings, media, image enhancement, speech, pricing, signing, distribution/export, sales, money, advisor, insights, and trends routes.

The frontend API base is controlled by:

```text
NEXT_PUBLIC_API_BASE_URL=http://localhost:8000
```

Firebase credentials are intentionally ignored by Git. Each developer/deployment must provide:

- root `.env`
- the service-account file referenced by `GOOGLE_APPLICATION_CREDENTIALS`

The Firestore adapter now uses a REST transport because the local gRPC transport was hanging during OAuth/token exchange. Firebase Storage is configured for the project bucket and `us-east1`; Firestore is configured for `asia-south1`.

Do not start the API with `KALASETU_OFFLINE=1` when testing persistence. That flag intentionally uses in-memory fallback storage.

## Local development

Frontend:

```bash
cd apps/web
npm install
npm run dev
```

Backend:

```bash
cd apps/api
./.venv/bin/uvicorn kalasetu_api.main:app --app-dir src --reload --host 0.0.0.0 --port 8000
```

Live URLs:

- Frontend: `http://localhost:3000`
- API docs: `http://localhost:8000/docs`
- API health: `http://localhost:8000/health`

Mock OTP remains `123456` while the OTP provider is configured as mock.

## Current working-tree state

There are active, intentionally uncommitted frontend design changes in:

- `apps/web/src/app/globals.css`
- `apps/web/src/app/layout.tsx`
- `apps/web/src/app/page.tsx`
- `apps/web/src/app/v/[listingId]/page.tsx`
- `apps/web/src/components/artisan-workspace.tsx`
- `apps/web/src/components/market-view.tsx`
- `apps/web/src/components/site-header.tsx`
- `apps/web/src/lib/api-client.ts`
- `apps/web/src/app/workspace-pages.css`
- `apps/web/src/app/workspace.css`
- `apps/web/src/components/home-gate.tsx`
- `apps/web/src/components/public-listing-view.tsx`
- `apps/web/src/components/workspace/`
- `apps/web/public/assets/patterns/leaf-thread.svg`
- `apps/web/public/assets/patterns/weave-grid.svg`

Review these changes before committing; they represent the latest internal-page design iteration and should not be discarded.

Local `.impeccable/` notes are ignored by Git and are not part of the application.

## Verification baseline

The latest verified frontend checks are:

```text
npx tsc --noEmit — pass
npm run lint — pass with no errors
git diff --check — pass
```

The backend should be smoke-tested through `/health`, OTP verification, Firestore persistence, and Storage reachability after starting without offline mode.

## Next recommended work

1. Review the current uncommitted workspace design files in the browser at 1280px/1440px and mobile width.
2. Tune asset placement and background dissolution page by page; avoid adding another global decorative layer without checking overlap.
3. Verify the full creation rail with one real Firebase-backed listing.
4. Commit the current frontend iteration only after visual review.
5. Push to `main` only after the frontend and backend smoke checks pass.
