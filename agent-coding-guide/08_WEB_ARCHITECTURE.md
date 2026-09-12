# 08 — Web architecture (React PWA)

## Job

Same artisan jobs as the app, **plus** `/market` show catalog and `/v/:id` public card. Own visual design. Must work in mobile Chrome.

## Layers

```
src/ui/       pages, CSS
src/voice/    MediaRecorder only → POST FastAPI
src/api/      FastAPI client; Firebase JS only for Firestore/Auth-session if used
```

## Keys

Firebase **web config** may live in the client (normal).  
**Sarvam and Gemini keys must not.**

## Auth

Same mock OTP via FastAPI. Store bearer (or Firebase custom token if API mints one) and use it on API + Firestore rules.

Preferred: FastAPI verifies OTP then returns a **Firebase custom token**; web `signInWithCustomToken`. Then Firestore rules work with `request.auth.uid`.

## `/market`

Query `publishedListings` orderBy `updatedAt` desc. Cards: photo, title, listed price, cluster. Tap → `/v/:id`.

**Working punch:** publish on the app, refresh `/market`, the new card is there.

No filters required for v1 beyond “all published.” No cart button anywhere on the page.

## PWA

`vite-plugin-pwa`. Cache shell. Do not cache API POST. IndexedDB for in-progress blob if upload dies.

## ONNX in browser

Optional. Quality studio still from FastAPI enhance. Do not ship CLIP.
