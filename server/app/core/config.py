from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    PROJECT_NAME: str
    MONGODB_URL: str
    REDIS_URL: str | None = None
    REDIS_CONNECT_TIMEOUT_SECONDS: float = 2.0
    REDIS_SOCKET_TIMEOUT_SECONDS: float = 2.0
    REDIS_OPERATION_TIMEOUT_SECONDS: float = 2.5
    SLOW_REQUEST_THRESHOLD_MS: float = 2000.0
    SECRET_KEY: str
    ALGORITHM: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int
    LOG_LEVEL: str = "INFO"

    CORS_ORIGINS: list[str] = [
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:5173",
        "http://127.0.0.1:5173",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
    ]
    CORS_ALLOW_CREDENTIALS: bool = True

    SMTP_HOST: str
    SMTP_PORT: int
    SMTP_USER: str
    SMTP_PASSWORD: str
    EMAILS_FROM_EMAIL: str

    STOP_WORDS_TITLES: list = ["white noise", "baby sleep", "relaxing sounds", "taras bulba", "rapeman"]
    STOP_WORDS_SUBTITLES: list = ["dream supplier"]
    
    TMDB_API_KEY: str
    SPOTIFY_CLIENT_ID: str
    SPOTIFY_CLIENT_SECRET: str
    GOOGLE_BOOKS_API_KEY: str

    model_config = SettingsConfigDict(env_file=".env")

settings = Settings()
