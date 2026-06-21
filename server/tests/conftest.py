import os
from pathlib import Path
import sys


ROOT_DIR = Path(__file__).resolve().parents[1]
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))


TEST_ENV_DEFAULTS = {
    "PROJECT_NAME": "OmniSource Test",
    "MONGODB_URL": "mongodb://127.0.0.1:27017/omnisource_test",
    "ACCESS_TOKEN_EXPIRE_MINUTES": "60",
    "SMTP_HOST": "smtp.test",
    "SMTP_PORT": "2525",
    "SMTP_USER": "test@example.com",
    "SMTP_PASSWORD": "test-password",
    "EMAILS_FROM_EMAIL": "test@example.com",
    "TMDB_API_KEY": "test-tmdb-key",
    "SPOTIFY_CLIENT_ID": "test-spotify-client",
    "SPOTIFY_CLIENT_SECRET": "test-spotify-secret",
    "GOOGLE_BOOKS_API_KEY": "test-google-books-key",
}

for key, value in TEST_ENV_DEFAULTS.items():
    os.environ.setdefault(key, value)
