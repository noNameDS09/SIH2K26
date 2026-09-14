# 11 — App build plan

Do these **in order**. Do not start step n+1 until step n **Working if** passes on a real phone or emulator.

Keys needed from step 3: Firestore `asia-south1`, Storage `US-EAST1`, `SARVAM_API_KEY`, `GEMINI_API_KEY` in gitignored env.

## Step 0 — Skeleton

- `flutter create` in `apps/mobile` if empty (`org` `in.kalasetu`).
- Routes stubbed for every screen in `04`.
- Theme in `lib/ui` (your design). Brand orange allowed.

**Working if:** app launches, you can tap through empty screens.

## Step 1 — OTP mock + artisan doc

- Language picker: all Sarvam langs, tiles speak names (TTS or pre-recorded).
- Phone + OTP → FastAPI → `123456`.
- Create `artisans/{uid}` in Firestore.

**Working if:** after 123456 you land on onboarding/home and the artisan document exists in the Firebase console.

## Step 2 — Onboarding

- Pehchan-shaped fields (seed). Mock Aadhaar camera + badge. Consent.
- Write profile. `lang` stored.

**Working if:** console shows name, lang, cluster; badge visible on that screen.

## Step 3 — Capture + studio (quality)

- Camera + gallery.
- Upload original to Storage.
- `POST /v1/images/enhance`. Show original | studio. dE on screen.

**Working if:** a real messy-background photo comes back with a **clean** cut-out you would show a judge. If not, fix the server model — do not proceed with a bad mask.

## Step 4 — Live cataloger

- Gemini Live asks slots. JSON merges to `listings/{id}.fields`.
- Confirm by ear (Sarvam TTS). Galat repairs one slot.

**Working if:** Firestore `fields` has craft/material/etc without typing. Hindi+English titles present.

## Step 5 — Intelligence + pricing

- Screen 3: card + trend from `public_trends` + opportunity (or empty).
- Costing slots if missing.
- FastAPI three-band price. Override. Write `prices`.

**Working if:** three numbers show with provenance; override persists as `listed`.

## Step 6 — Approval + distribute (Stage 4–5)

- Hear full card. Approve.
- FastAPI sign + QR. `status: published`.
- OS share sheet. Mocked adapter toggles labelled mocked.
- Inventory list.

**Working if:** QR exists; listing `published`; **web `/market` shows it** (coordinate with web step 3 if web is behind — then verify via Firebase `publishedListings` at minimum).

## Step 7 — Home + insights (Stage 6)

- Advisor sentence from own data.
- Bottom nav wired.
- Money screen can be empty-state spoken “no sales yet.”

**Working if:** Home speaks one true line or silence; nav reaches shop/insights/settings.

## Step 8 — Trends + money polish

- Trigger trend job after publish.
- Trade Record bars from identity + listing count (sales may be zero).

**Working if:** `public_trends/current` exists; seed labelled if n low; Trade Record not titled credit score.

## Stop conditions

If Live keys missing: you may hard-fail the Live screen with a visible error. Do not fake JSON for a saree unless the human asks for a fixture, and then label **fixture**.
