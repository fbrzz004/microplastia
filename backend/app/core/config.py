from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "MicroplastIA API"
    description: str = (
        "Backend para detección de microplásticos mediante IA"
    )

    api_v1_prefix: str = "/api/v1"
    debug: bool = False

    database_url: str

    secret_key: str
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60

    # Inferencia YOLOv8n y almacenamiento de archivos
    model_path: str = "weights/best.pt"
    confidence_threshold: float = 0.25
    upload_dir: str = "uploads"
    static_dir: str = "static"

    model_config = SettingsConfigDict(
        env_file=".env",
        extra="ignore",
        protected_namespaces=(),
    )


settings = Settings()
