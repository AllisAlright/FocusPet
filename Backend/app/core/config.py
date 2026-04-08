from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # These values come from environment variables or `.env`.
    app_name: str = "FocusPet Backend"
    app_env: str = "local"
    app_host: str = "127.0.0.1"
    app_port: int = 8000
    app_debug: bool = True
    database_url: str = "sqlite:///./data/focuspet.db"
    deepseek_api_key: str = ""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )


settings = Settings()
