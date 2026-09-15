# KalaSetu FastAPI Backend (`apps/api`)

The central backend service powering the KalaSetu ecosystem. It coordinates:
- **Artisan Authentication** (Mock OTP & Firebase Custom Token minting)
- **AI Image Studio** (Background removal via ISNet/rembg, CIELAB $\Delta E$ quality gate, background compositing)
- **Multilingual Voice Agents** (Gemini Live WebSocket conversational interview & Sarvam STT/TTS)
- **4-Tier Pricing Engine** (Cost breakdown, cluster wage benchmarks, GI premiums)
- **Cryptographic Signing & QR Generation** (Deterministic HMAC-SHA256 & QR code PNGs)
- **Firestore Persistence & Public Marketplace** (`/market` catalog with search, filtering, and facets)

---

## 🚀 Quick Start

### 1. Environment Configuration

Copy the sample environment file from the repository root:

```bash
cp .env.example .env
```

Ensure the key environment variables in `.env` are configured:
```dotenv
# Port & Host
PUBLIC_BASE_URL=http://localhost:8000
CORS_ORIGINS=http://localhost:3000,http://127.0.0.1:3000,http://localhost:8501,http://localhost:8080,http://127.0.0.1:8080

# Secrets
LISTING_HMAC_SECRET=your-random-32-byte-hex-secret
OTP_PROVIDER=mock
OTP_MOCK_CODE=123456

# AI & Voice Providers
SARVAM_API_KEY=your_sarvam_key
GEMINI_API_KEY=your_gemini_api_key

# Firebase (Optional for local offline test, required for real Firestore)
FIREBASE_PROJECT_ID=kalasetu-903c2
FIREBASE_CREDENTIALS_PATH=./secrets/kalasetu-903c2-firebase-adminsdk.json
```

---

### 2. Running Locally (Python Virtualenv)

From the repository root:

```bash
cd apps/api

# Create & activate a virtual environment (Python 3.12+)
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies (including optional dev, studio, and voice packages)
pip install -e ".[dev,studio,voice]"

# Run FastAPI with live reload
uvicorn kalasetu_api.main:app --app-dir src --reload --host 0.0.0.0 --port 8000
```

> **Makefile Shortcut (from repo root):**
> ```bash
> make api-local
> ```

---

### 3. Running with Docker

From the repository root:

```bash
docker compose up --build api
```

> **Makefile Shortcut (from repo root):**
> ```bash
> make api
> ```

The API will be available at **`http://localhost:8000`**.

---

### 4. Interactive Documentation & Health Check

Once running, navigate to:
- **Swagger UI (Interactive API Explorer):** [http://localhost:8000/docs](http://localhost:8000/docs)
- **ReDoc (Detailed OpenAPI Spec):** [http://localhost:8000/redoc](http://localhost:8000/redoc)
- **Health Check:** [http://localhost:8000/health](http://localhost:8000/health)

---

### 5. Running Tests

Run the complete automated test suite (30 passing tests):

```bash
cd apps/api
.venv/bin/pytest
```

> **Makefile Shortcut (from repo root):**
> ```bash
> make test-api
> ```

---

### 6. Voice Cataloger Streamlit Tester

For isolated voice testing with real-time Gemini Live WebSocket audio:

```bash
cd apps/api
PYTHONPATH=src .venv/bin/streamlit run streamlit_cataloger.py
```

> **Makefile Shortcut (from repo root):**
> ```bash
> make voice
> ```
Accessible at **`http://localhost:8501`**.

---

## 📡 Complete Route Reference

### 1. System & Health

| Method | Route | Auth | Description |
|---|---|:---:|---|
| `GET` | `/` | None | API root info, version, and links to `/docs` and `/health`. |
| `GET` | `/health` | None | Service status, Firestore/Storage regions, wired vendor keys, and missing config check. |

---

### 2. Authentication & Artisan Identity (`/v1/auth`)

| Method | Route | Auth | Description |
|---|---|:---:|---|
| `POST` | `/v1/auth/otp` | None | Send OTP to phone number. In demo mode (`OTP_PROVIDER=mock`), code is always `123456`. |
| `POST` | `/v1/auth/verify` | None | Verify OTP. Returns a session bearer token and Firebase `custom_token` for client authentication. |
| `GET` | `/v1/auth/me` | Bearer | Get the authenticated artisan's profile, Pehchan ID, cluster, and language preference. |
| `PATCH` | `/v1/auth/me` | Bearer | Update the artisan profile (name, preferred language, cluster, Pehchan card details). |

---

### 3. Image Enhancement & Studio (`/v1/images`)

| Method | Route | Auth | Description |
|---|---|:---:|---|
| `POST` | `/v1/images/enhance` | Bearer | Multipart (`listing_id` required; `file` optional on re-edit; `bg_preset`, `craft`). Performs subject cutout (ISNet/rembg), checks CIELAB $\Delta E \le 2.0$ color fidelity, composites onto a locked preset (`white`, `linen`, `beige`, `slate`, `jute`, `wood`). If `file` is omitted, the stored `original.jpg` is reused. |

---

### 4. Speech, Voice & Live Cataloger (`/v1/speech`)

| Method | Route | Auth | Description |
|---|---|:---:|---|
| `POST` | `/v1/speech/stt` | Bearer | Transcribe audio via Sarvam Saaras v3 (`file`, `language_code`). |
| `POST` | `/v1/speech/tts` | Bearer | Synthesize audio via Sarvam Bulbul v3 (`text`, `language_code`). |
| `POST` | `/v1/speech/catalog/turn` | Bearer | REST turn-by-turn fallback for slot-filling cataloger. |
| `GET` | `/v1/speech/live/state/{session_id}` | None | Retrieve extracted product slots, status, and summary table for a Live voice session. |
| `GET` | `/v1/speech/live/ui` | None | Lightweight HTML/JS microphone component for audio streaming over WebSocket. |
| `WebSocket` | `/v1/speech/live/ws` | None | Full-duplex WebSocket connecting client microphone to Gemini Live for conversational product cataloging. |

---

### 5. Listings, Pricing & Digital Signing (`/v1/listings`)

| Method | Route | Auth | Description |
|---|---|:---:|---|
| `GET` | `/v1/listings` | Bearer | List all listings (draft and published) belonging to the authenticated artisan. |
| `POST` | `/v1/listings` | Bearer | Create a new listing draft for the authenticated artisan. |
| `GET` | `/v1/listings/{id}` | Bearer | Retrieve an artisan's listing details. |
| `PATCH` | `/v1/listings/{id}` | Bearer | Update listing fields, cluster, photos, or descriptions. |
| `POST` | `/v1/listings/{id}/price` | Bearer | Calculate 4-tier price bands (`floor`, `recommended`, `aspirational`, `listed`) based on hours, materials, cluster wage benchmarks, and GI premiums. |
| `POST` | `/v1/listings/{id}/sign` | Bearer | Freeze listing, compute deterministic HMAC-SHA256 signature, generate high-contrast QR code PNG, upload `qr.png` to Firebase Storage (in-memory fallback), and publish to Firestore (`publishedListings`). |
| `GET` | `/v1/listings/{id}/media/{filename}` | None | Serve `studio.jpg`, `original.jpg`, `qr.png`, or `audio.opus` from memory or Firebase Storage. |
| `GET` | `/v1/listings/{id}/media/{kind}.jpg` | None | Legacy image route serving `original.jpg` or `studio.jpg`. |
| `POST` | `/v1/listings/{id}/media` | Bearer | Upload listing audio (`kind=audio`). Photos still go through `/v1/images/enhance`. |
| `GET` / `POST` | `/v1/listings/{id}/export` | Bearer | Mocked GeM / ONDC / India Handloom export record. Always labelled `Mock — for SIH demo`. No live write. |

---

### 6. Public Marketplace & QR Landing (`/v1/market` & `/v/{id}`)

| Method | Route | Auth | Description |
|---|---|:---:|---|
| `GET` | `/v1/market` | None | Public marketplace catalog containing all published products (including 30 verified Indian craft seed items). Supports search, filtering, and facets:<br>• `?q=text` or `?search=text`: Full-text search (titles, descriptions in English & Hindi, tags, artisan, craft, cluster)<br>• `?category=Handloom`: Filter by category (6 craft categories)<br>• `?craft=metalcraft`: Filter by specific craft<br>• `?cluster=varanasi`: Filter by geographical cluster<br>• `?gi=yes|no`: Filter by Geographical Indication status<br>• `?tag=silk`: Filter by product tag<br>• `?min_price=1000&max_price=5000`: Price range filter<br>• `?sort=price_asc|price_desc|latest`: Sorting<br>• **Returns:** items, total count, and facets (`categories`, `clusters`, `crafts`, `tags`). |
| `POST` | `/v1/market/seed` | None | Bootstrap/populate all 30 handcrafted catalog items and artisan profiles into live Firestore. |
| `GET` | `/v/{listing_id}` | None | **Public Verified Product Card** (the target URL scanned from the QR code). Returns complete public data: bilingual copy, artisan name & Pehchan ID, 4-tier price provenance, and HMAC cryptographic signature. |

---

### 7. Sales, Money & Trade Record

| Method | Route | Auth | Description |
|---|---|:---:|---|
| `POST` | `/v1/sales` | Bearer | Confirm a sale `{ listing_id, amount }` for the artisan. Writes `sales/{id}` and updates Trade Record. |
| `GET` | `/v1/sales` | Bearer | List this artisan's sales and `total_inr`. |
| `GET` | `/v1/money` | Bearer | Spoken-first money screen: sales, total, empty-state line, Trade Record bars. Never called a credit score. |
| `GET` | `/v1/trade-record` | Bearer | Five bars: identity, listings, sales, consistency, community. |

---

### 8. Advisor & Trends

| Method | Route | Auth | Description |
|---|---|:---:|---|
| `GET` | `/v1/advisor` | Bearer | Agent B: one ranked rule, one sentence (or empty). Provenance `advisor-rules.v1/<rule_id>`. |
| `GET` | `/v1/insights` | Bearer | Advisor snapshot, insight history, and current public trend line. |
| `GET` | `/v1/trends/current` | None | Agent C read model. `n` visible; `seed: true` labelled when n < 20. |
| `POST` | `/v1/trends/recompute` | Admin | Rebuild `public_trends/current` from last-30-day sales (listings if no sales). Header `X-Admin-Token` when `ADMIN_API_TOKEN` is set. |

Auth notes:
- `POST /v1/auth/verify` always returns a `dev.{uid}` API bearer for FastAPI.
- `firebase_custom_token` is minted when Admin SDK credentials are valid (`auth_mode=firebase`). Otherwise `auth_mode=dev` and `firebase_custom_token` is `null`.
- Image/QR/audio bytes are stored in process memory **and** uploaded to Firebase Storage path `artisans/{uid}/listings/{id}/…` when the Admin SDK bucket is available.

---

## 📂 Project Architecture

```
apps/api/
├── Dockerfile                   # Production container definition
├── pyproject.toml               # Python package configuration and dependencies
├── requirements-studio.txt      # Rembg / Onnxruntime dependencies
├── streamlit_cataloger.py       # Standalone voice testing tool
├── assets/                      # Bundled background presets (linen, jute, etc.)
├── tests/                       # Pytest test suite
└── src/kalasetu_api/
    ├── main.py                  # FastAPI app factory, CORS, and top-level routes
    ├── config.py                # Pydantic Settings and env loader
    ├── deps.py                  # Auth dependencies (require_bearer, current_uid, require_admin)
    ├── catalog_seed.py          # 30 authentic handicraft product definitions
    ├── demo_store.py            # In-memory baseline store and price builder
    ├── listing_media.py         # Media memory cache + Storage mirror
    ├── adapters/
    │   ├── firebase.py          # Firestore, Auth minting, sales, trends, in-memory fallback
    │   ├── storage.py           # Firebase Storage upload/download
    │   ├── llm/
    │   │   ├── gemini.py        # Gemini client for text extraction + advisor phrasing
    │   │   └── gemini_live.py   # Gemini Live WebSocket configuration & session handlers
    │   └── speech/
    │       ├── sarvam.py        # Sarvam Saaras STT & Bulbul TTS HTTP client
    │       └── live_ui.py       # Embedded PCM audio recording widget
    ├── engines/
    │   ├── cataloger.py         # Slot-filling state machine
    │   ├── languages.py         # Indic language codes
    │   ├── pricing.py           # 4-tier formula using wages & materials benchmarks
    │   ├── signing.py           # HMAC-SHA256 signature and QR code generation
    │   ├── studio.py            # Image cut-out, Delta E calculation, composition
    │   ├── advisor.py           # Agent B rule ranker
    │   ├── trends.py            # Agent C public_trends aggregation
    │   └── export.py            # Mocked GeM / ONDC / IH records
    └── routers/
        ├── auth.py              # OTP and artisan identity endpoints
        ├── images.py            # Image Studio enhancement endpoint
        ├── listings.py          # Listings, pricing, signing, market, media
        ├── sales.py             # Sales, money, Trade Record
        ├── advisor.py           # Advisor + insights
        ├── trends.py            # public_trends current + recompute
        ├── export.py            # Mocked channel export
        ├── speech.py            # STT, TTS, and REST turn endpoints
        └── speech_live.py       # Gemini Live WebSocket & test harness
```
