# 08 — Web architecture (Next.js)

## Job

Same artisan jobs as the app, **plus** `/market` show catalog and `/v/:id` public card. Own visual design. Must work in mobile Chrome.

## Layers

Match the tree already in `apps/web`:

```
src/app/              App Router routes from 04 (`/market`, `/v/[listingId]`, …)
src/components/ui/    screens, CSS (own design — not shared with Flutter)
src/voice/            MediaRecorder only → POST FastAPI
src/api/              FastAPI client; Firebase JS only for Firestore/Auth-session if used
src/lib/              helpers
public/bg/            six bundled backgrounds
```

Do not add Vite. Do not use `vite-plugin-pwa`. Looks may differ from the Flutter app.

## Keys

Firebase **web config** may live in the client as `NEXT_PUBLIC_*` in `apps/web/.env.local` (gitignored).  
**Sarvam and Gemini keys must not.**

Root `.env` is FastAPI. Do not put vendor keys in `NEXT_PUBLIC_*`.

## Auth

Same mock OTP via FastAPI. Store bearer (or Firebase custom token if API mints one) and use it on API + Firestore rules.

Preferred: FastAPI verifies OTP then returns a **Firebase custom token**; web `signInWithCustomToken`. Then Firestore rules work with `request.auth.uid`.

## `/market`

Query `publishedListings` orderBy `updatedAt` desc. Cards: photo, title, listed price, cluster. Tap → `/v/:id`.

**Working punch:** publish on the app, refresh `/market`, the new card is there.

No filters required for v1 beyond “all published.” No cart button anywhere on the page.

## Installability

Phone Chrome is the target viewport. A PWA (manifest + service worker) is optional later. Cache the shell only; never cache API POST. IndexedDB for in-progress blob if upload dies.

## ONNX in browser

Optional. Quality studio still from FastAPI enhance. Do not ship CLIP.
