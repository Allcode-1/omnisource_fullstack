from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    PROJECT_NAME: str
    MONGODB_URL: str
    REDIS_URL: str
    SECRET_KEY: str
    ALGORITHM: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int

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