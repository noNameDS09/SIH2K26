# 07 — App architecture (Flutter)

## Job

Hand demo. Stages 1–6 + extra screens. Own visual design. Publishes listings that the web market can show.

## Layers

```
lib/ui/          screens, theme, routing
lib/voice/       Sarvam + Gemini Live (direct)
lib/api/         FastAPI (OTP, enhance, sign) + FlutterFire (Firestore/Storage)
```

Do not put business price math in widgets. Price comes from FastAPI (or a small `lib/api/pricing.dart` that calls FastAPI). Do not reimplement enhance in five files.

## Direct vs proxy

| Call | App |
|---|---|
| Sarvam STT/TTS | Direct (`lib/voice`) |
| Gemini Live | Direct WebSocket / SDK |
| Firestore / Storage | FlutterFire |
| OTP | FastAPI |
| Image enhance (quality path) | FastAPI `POST /v1/images/enhance` |
| Sign / QR | FastAPI |
| Fallback if Live/Sarvam fail | FastAPI `/v1/speech/*` |

Keys: `apps/mobile/.env` or `--dart-define`. Gitignored.

## Routing

GoRouter (or equivalent) with the screen IDs in `04_FEATURES_AND_SCREENS.md`. Deep link not required for v1 except we should not lose the draft on rotation — persist `listingId` in local store.

## State

One current `listingId` while in the pipeline. Home reads `artisans/{uid}/listings` and `public_trends`.

## Quality

Studio: always send to server enhance for the **shown** studio image (quality). On-device YOLO is optional preview. If server fails, show original + error, do not show a bad mask as final.

## Tests you run on a device/emulator (see 11)

After each plan step. No “it compiled” as done.
