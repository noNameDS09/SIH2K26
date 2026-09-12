# 03 — Repo

```
SIH2K26/
├── agent-coding-guide/                 YOU ARE HERE (agent source of truth)
├── apps/
│   ├── api/                  FastAPI (Python, uv)
│   │   └── src/kalasetu_api/
│   ├── mobile/               Flutter app
│   │   └── lib/ui | voice | api
│   └── web/                  React PWA
│       └── src/ui | voice | api
├── packages/
│   ├── brand/                name + #F97316
│   └── contracts/            openapi.yaml
├── seed/                     crafts / wages / materials / comparables
├── docs/                     ADRs, research (not agent SoT)
├── sih-understanding/        pitch research (not agent SoT)
├── DemoSIH-main/             frozen dummy — do not edit
├── docker-compose.yml
└── .env.example
```

## Lanes

| Lane | Path | Owns |
|---|---|---|
| App | `apps/mobile` | Screens, camera, Live, FlutterFire |
| Web | `apps/web` | Screens, `/market`, public card, speech via API |
| API | `apps/api` | OTP, enhance, `/v1/speech`, sign, Admin SDK, trend job |
| Data | Firestore + Storage `asia-south1` | Documents and files |

## Commands (from repo root)

```bash
cp .env.example .env
# fill SARVAM_API_KEY, GEMINI_API_KEY
docker compose up --build
curl -s http://localhost:8000/health
```

Flutter: `apps/mobile` after `flutter create` if the project is still empty.  
Web: Vite app in `apps/web` (create if empty).  
Do not put keys in git.
