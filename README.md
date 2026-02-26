# omnisource

A cross-platform media aggregator powered by FastAPI and Flutter. Unifies movies, books, and music into a single AI-driven discovery experience.

## Runtime

- Flutter client: `lib/`
- FastAPI backend: `server/app/`

For Flutter web or mobile, override backend URL with:

```bash
flutter run --dart-define=API_BASE_URL=http://<your-host>:8000
```
