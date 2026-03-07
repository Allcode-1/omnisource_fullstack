# OmniSource

OmniSource is a cross-platform media discovery app (Flutter + FastAPI) that
aggregates movies, books, and music into one feed with search, personalization,
playlists, analytics, and deep-research recommendations.

The project is optimized for:

1. Diploma / portfolio demonstration
2. MVP+ level product architecture
3. Clear growth path toward production-grade quality

## Contents

1. [Architecture](#architecture)
2. [Tech Stack](#tech-stack)
3. [Repository Layout](#repository-layout)
4. [Quick Start (Docker)](#quick-start-docker)
5. [Local Development](#local-development)
6. [Environment Variables](#environment-variables)
7. [ML and Recommendations](#ml-and-recommendations)
8. [Quality and Security Gates](#quality-and-security-gates)
9. [Deep Research Seeding](#deep-research-seeding)
10. [Troubleshooting](#troubleshooting)

## Architecture

High-level architecture documentation is available in
[`ARCHITECTURE.md`](ARCHITECTURE.md).

Core runtime:

1. Flutter client in `lib/`
2. FastAPI backend in `server/app/`
3. MongoDB for documents and interaction history
4. Redis for caching and low-latency hot paths
5. External providers: TMDB, Spotify, Google Books

## Tech Stack

Frontend:

1. Flutter (mobile + web)
2. Bloc/Cubit state management
3. Dio HTTP client

Backend:

1. FastAPI
2. Beanie + MongoDB
3. Redis
4. SentenceTransformers + NumPy for vector-based recommendation logic

Tooling:

1. Docker / Docker Compose
2. GitHub Actions CI
3. Ruff, Pytest, Bandit, pip-audit

## Repository Layout

```text
.
├─ lib/                         # Flutter app
├─ server/
│  ├─ app/                      # FastAPI application
│  ├─ tests/                    # Backend tests
│  ├─ Dockerfile                # Backend image
│  ├─ requirements.txt
│  └─ .env.example
├─ docker-compose.yml           # API + Mongo + Redis stack
├─ ARCHITECTURE.md
└─ README.md
```

## Quick Start (Docker)

### 1) Prepare env

```bash
cp .env.example .env
# Windows PowerShell:
# Copy-Item .env.example .env
```

Update secrets and provider keys in `.env`:

1. `SECRET_KEY`
2. `TMDB_API_KEY`
3. `SPOTIFY_CLIENT_ID`
4. `SPOTIFY_CLIENT_SECRET`
5. `GOOGLE_BOOKS_API_KEY`
6. SMTP credentials (if password reset email is needed)

### 2) Start the stack

```bash
docker compose up --build
```

Services:

1. API: `http://localhost:8000`
2. MongoDB: `localhost:27017`
3. Redis: `localhost:6379`

Health endpoint:

```bash
curl http://localhost:8000/health
```

Stop and remove containers:

```bash
docker compose down
```

Stop and remove containers + volumes:

```bash
docker compose down -v
```

## Local Development

### Backend

```bash
cd server
python -m venv .venv
# Windows PowerShell:
# .venv\Scripts\Activate.ps1
# macOS/Linux:
# source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

### Flutter (web example)

```bash
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

## Environment Variables

Main templates:

1. Root: [`.env.example`](.env.example) (Docker stack)
2. Backend-only: [`server/.env.example`](server/.env.example)

Most important groups:

1. Data stores: `MONGODB_URL`, `REDIS_URL`
2. Auth/security: `SECRET_KEY`, JWT settings, auth rate limits
3. Runtime: logging and slow request threshold
4. Image proxy cache limits
5. SMTP and external APIs

## ML and Recommendations

Current implementation is a practical semi-ML pipeline:

1. Content vectors are generated via SentenceTransformers (with hash fallback)
2. User interactions are tracked with weighted events
3. Recommendations use vector similarity + rating blending
4. Deep Research mode applies vector retrieval with fallback to discovery APIs

This is suitable for MVP+/diploma scope and can be evolved to fully trained
models (Neural CF / Matrix Factorization / Two-Tower) with offline training.

## Quality and Security Gates

### Backend checks

```bash
cd server
python -m ruff check .
python -m bandit -q -r app -ll
python -m pip_audit -r requirements.txt --ignore-vuln CVE-2024-23342
python -m pytest -q
```

### Flutter checks

```bash
flutter analyze
flutter test
```

### Git hooks (optional)

```bash
pip install pre-commit
pre-commit install
pre-commit install --hook-type pre-push
```

CI workflow is defined in [`.github/workflows/ci.yml`](.github/workflows/ci.yml).
Dependency handling policy is documented in
[`server/DEPENDENCY_POLICY.md`](server/DEPENDENCY_POLICY.md).

## Deep Research Seeding

If Deep Research keeps returning too small a rotating pool, seed metadata and
recompute vectors:

```bash
cd server
python run_seed_vectors.py --content-type movie --tag-limit 40
```

Useful flags:

1. `--refresh-all` recompute vectors for all matched documents
2. `--max-docs 500` limit quick-run volume
3. `--no-seed-home` skip home snapshot seeding

## Troubleshooting

1. Slow cold start:
   Model warmup and first vectorizer initialization can take time.
   Keep container running, use warmup, and persist cache volumes.
2. Empty recommendations:
   Ensure interactions are generated and metadata vectors exist.
3. External API results are sparse:
   Verify provider API keys and quotas.
4. Password reset emails do not arrive:
   Check SMTP credentials and provider restrictions.
