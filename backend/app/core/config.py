from typing import List, Optional

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    APP_ENV: str = "development"
    SECRET_KEY: str = "change-me-in-production"
    ALLOWED_ORIGINS: List[str] = ["*"]

    # Railway injects DATABASE_URL directly; fallback to individual vars for local dev.
    DATABASE_URL: Optional[str] = None

    POSTGRES_USER: str = "hicampus"
    POSTGRES_PASSWORD: str = "hicampus"
    POSTGRES_HOST: str = "localhost"
    POSTGRES_PORT: int = 5433
    POSTGRES_DB: str = "hicampus"

    GOOGLE_TRANSLATOR_API_KEY: str = ""
    NAVER_MAP_CLIENT_ID: str = ""
    NAVER_MAP_CLIENT_SECRET: str = ""
    PUBLIC_DATA_SERVICE_KEY: str = ""

    def get_database_url(self) -> str:
        if self.DATABASE_URL:
            # Railway uses postgres:// — SQLAlchemy requires postgresql://
            return self.DATABASE_URL.replace("postgres://", "postgresql://", 1)
        return (
            f"postgresql://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}"
            f"@{self.POSTGRES_HOST}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"
        )


settings = Settings()
