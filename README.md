# omnisource

A cross-platform media aggregator powered by FastAPI and Flutter. Unifies movies, books, and music into a single AI-driven discovery experience.

## Runtime

- Flutter client: `lib/`
- FastAPI backend: `server/app/`

For Flutter web or mobile, override backend URL with:

```bash
flutter run --dart-define=API_BASE_URL=http://<your-host>:8000
```

## Docker Quick Start

Run the backend stack (API + MongoDB + Redis):

```bash
docker compose up --build
```

API will be available at:

```bash
http://localhost:8000
```

If you need real external integrations (TMDB/Spotify/Google Books/SMTP), set
environment variables before start (or create local `.env` from `.env.example`).
Never commit real secrets.

Stop and remove containers/volumes:

```bash
docker compose down -v
```

## Deep Research Data Seeding

If Deep Research keeps rotating the same small set of items, seed metadata and
backfill vectors:

```bash
cd server
python run_seed_vectors.py --content-type movie --tag-limit 40
```

Useful flags:

- `--refresh-all` recomputes vectors for all matched docs
- `--max-docs 500` limits processing for a quick run
- `--no-seed-home` skips home snapshot seeding
