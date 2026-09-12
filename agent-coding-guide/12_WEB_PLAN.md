# 12 — Web build plan

Do in order. Phone Chrome is the target viewport, not only desktop.

FastAPI is **required** from step 1 (speech keys never in JS).

## Step 0 — PWA skeleton

- Vite + React + TS in `apps/web`.
- Routes from `04` including `/market` and `/v/:listingId`.
- Own CSS.

**Working if:** `npm run dev`, routes load on a 390px-wide viewport.

## Step 1 — OTP + custom token

- Same FastAPI OTP.
- Sign into Firebase with custom token from API.
- Create artisan doc if missing.

**Working if:** Firebase Auth uid exists; artisan doc in console.

## Step 2 — Public card `/v/:id`

- Render a published listing by id. No login required if rules allow public read of `publishedListings`.
- Trust block placeholders ok until sign exists.

**Working if:** opening a known id on a second phone/browser shows photo + title.

## Step 3 — Show catalog `/market`

- Grid of `publishedListings`.
- Tap → `/v/:id`.
- No cart UI.

**Working if:** you publish from the **app** (or Firebase console as a test doc) and `/market` shows that card without a rebuild.

## Step 4 — Capture + enhance

- File input + getUserMedia.
- Same enhance endpoint as app.
- Original | studio.

**Working if:** quality matches app (same API). Bad masks = not done.

## Step 5 — Live via FastAPI

- Hold to talk. Upload/stream audio. Server runs Live/STT. Return JSON + next TTS.
- Same Firestore listing shape as app.

**Working if:** a listing created **on the web** also appears on `/market` after publish.

## Step 6 — Pricing, approval, QR, share

- Same jobs as app steps 5–6.
- `navigator.share` + copy link.

**Working if:** web-published listing has QR and shows on `/market`.

## Step 7 — Home, advisor, money, insights

- Same rules as app. Different layout.

**Working if:** same artisan uid sees the same listings on web home and app shop.

## Cross-client punch (required before calling the build “linked”)

1. App: publish listing A.  
2. Web `/market`: listing A visible.  
3. Web: publish listing B.  
4. App shop: listing B visible.

## Stop conditions

No vendor keys in the bundle (`grep` the build). If found, revert.
