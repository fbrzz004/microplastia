from pydantic import Field
from pydantic_settings import (
    BaseSettings,
    SettingsConfigDict,
)


class Settings(BaseSettings):

    # ======================================================
    # APLICACIÓN
    # ======================================================

    app_name: str = (
        "MicroplastIA API"
    )

    description: str = (
        "Backend para detección "
        "de microplásticos mediante IA"
    )

    api_v1_prefix: str = (
        "/api/v1"
    )

    environment: str = (
        "development"
    )

    debug: bool = False

    docs_enabled: bool = True


    # ======================================================
    # LOGGING
    # ======================================================

    log_level: str = "INFO"


    # ======================================================
    # BASE DE DATOS
    # ======================================================

    database_url: str


    # ======================================================
    # JWT
    # ======================================================

    secret_key: str = Field(
        min_length=32
    )

    algorithm: str = (
        "HS256"
    )

    access_token_expire_minutes: int = (
        60
    )


    # ======================================================
    # CORS
    # ======================================================

    allowed_origins: str = (
        "http://localhost:4200"
    )


    # ======================================================
    # TRUSTED HOSTS
    # ======================================================

    allowed_hosts: str = (
        "localhost,127.0.0.1"
    )


    # ======================================================
    # LOGIN / RATE LIMIT
    # ======================================================

    login_max_attempts: int = (
        5
    )

    login_attempt_window_minutes: int = (
        15
    )

    login_block_minutes: int = (
        15
    )


    # ======================================================
    # MODELO IA
    # ======================================================

    model_path: str = (
        "weights/best.pt"
    )

    confidence_threshold: float = (
        0.25
    )


    # ======================================================
    # ARCHIVOS
    # ======================================================

    upload_dir: str = (
        "uploads"
    )

    static_dir: str = (
        "static"
    )

    max_upload_mb: int = (
        10
    )

    public_base_url: str = ""


    # ======================================================
    # STORAGE
    # ======================================================

    storage_backend: str = (
        "local"
    )

    storage_jpeg_quality: int = Field(
        default=90,
        ge=50,
        le=100,
    )


    # ======================================================
    # SUPABASE STORAGE
    # ======================================================

    supabase_url: str = ""

    supabase_secret_key: str = ""

    supabase_storage_bucket: str = (
        "microplastia-images"
    )


    # ======================================================
    # HELPERS
    # ======================================================

    @property
    def is_production(
        self,
    ) -> bool:

        return (
            self.environment
            .strip()
            .lower()
            == "production"
        )


    @property
    def cors_origins(
        self,
    ) -> list[str]:

        return [
            origin.strip()

            for origin
            in self.allowed_origins.split(
                ","
            )

            if origin.strip()
        ]


    @property
    def trusted_hosts(
        self,
    ) -> list[str]:

        return [
            host.strip()

            for host
            in self.allowed_hosts.split(
                ","
            )

            if host.strip()
        ]


    @property
    def uses_supabase_storage(
        self,
    ) -> bool:

        return (
            self.storage_backend
            .strip()
            .lower()
            == "supabase"
        )


    model_config = (
        SettingsConfigDict(
            env_file=".env",
            env_file_encoding="utf-8",
            extra="ignore",
            protected_namespaces=(),
        )
    )


settings = Settings()