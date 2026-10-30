from pathlib import Path

from fastapi import (
    FastAPI,
    Request,
)
from fastapi.middleware.cors import (
    CORSMiddleware,
)
from fastapi.middleware.trustedhost import (
    TrustedHostMiddleware,
)
from fastapi.staticfiles import (
    StaticFiles,
)
from sqlalchemy.exc import (
    SQLAlchemyError,
)

import app.models  # noqa: F401

from app.api.v1.router import (
    api_router,
)
from app.core.config import (
    settings,
)
from app.core.exceptions import (
    database_exception_handler,
    unexpected_exception_handler,
)
from app.core.logging_config import (
    configure_logging,
)
from app.db.session import (
    Base,
    engine,
)


# ==========================================================
# LOGGING
# ==========================================================

configure_logging()


# ==========================================================
# BASE DE DATOS
# ==========================================================

Base.metadata.create_all(
    bind=engine
)


# ==========================================================
# FASTAPI
# ==========================================================

app = FastAPI(
    title=settings.app_name,
    description=settings.description,
    version="1.0.0",
    debug=settings.debug,

    docs_url=(
        "/docs"
        if settings.docs_enabled
        else None
    ),

    redoc_url=(
        "/redoc"
        if settings.docs_enabled
        else None
    ),

    openapi_url=(
        "/openapi.json"
        if settings.docs_enabled
        else None
    ),
)


# ==========================================================
# ERRORES
# ==========================================================

app.add_exception_handler(
    SQLAlchemyError,
    database_exception_handler,
)

app.add_exception_handler(
    Exception,
    unexpected_exception_handler,
)


# ==========================================================
# TRUSTED HOSTS
# ==========================================================

if settings.trusted_hosts:

    app.add_middleware(
        TrustedHostMiddleware,
        allowed_hosts=(
            settings.trusted_hosts
        ),
    )


# ==========================================================
# CORS
# ==========================================================

cors_kwargs = {
    "allow_origins":
        settings.cors_origins,

    "allow_credentials":
        False,

    "allow_methods": [
        "GET",
        "POST",
        "PUT",
        "PATCH",
        "DELETE",
        "OPTIONS",
    ],

    "allow_headers": [
        "Authorization",
        "Content-Type",
        "Accept",
    ],
}


if not settings.is_production:

    cors_kwargs[
        "allow_origin_regex"
    ] = (
        r"^https?://"
        r"(localhost|127\.0\.0\.1)"
        r"(:\d+)?$"
    )


app.add_middleware(
    CORSMiddleware,
    **cors_kwargs,
)


# ==========================================================
# HEADERS DE SEGURIDAD
# ==========================================================

@app.middleware("http")
async def security_headers(
    request: Request,
    call_next,
):

    response = await call_next(
        request
    )

    response.headers[
        "X-Content-Type-Options"
    ] = "nosniff"

    response.headers[
        "X-Frame-Options"
    ] = "DENY"

    response.headers[
        "Referrer-Policy"
    ] = "no-referrer"

    response.headers[
        "Permissions-Policy"
    ] = (
        "camera=(), "
        "microphone=(), "
        "geolocation=()"
    )

    response.headers[
        "Cache-Control"
    ] = "no-store"

    if settings.is_production:

        response.headers[
            "Strict-Transport-Security"
        ] = (
            "max-age=31536000; "
            "includeSubDomains"
        )

    return response


# ==========================================================
# ARCHIVOS ESTÁTICOS
# ==========================================================

static_path = (
    Path(__file__)
    .resolve()
    .parent
    .parent
    / settings.static_dir
)

static_path.mkdir(
    parents=True,
    exist_ok=True,
)

app.mount(
    "/static",
    StaticFiles(
        directory=str(
            static_path
        )
    ),
    name="static",
)


# ==========================================================
# HEALTH CHECK
# ==========================================================

@app.get("/")
def read_root():

    return {
        "status": "success",
        "message": (
            "MicroplastIA API disponible"
        ),
    }


@app.get("/health")
def health_check():

    return {
        "status": "ok"
    }


# ==========================================================
# API
# ==========================================================

app.include_router(
    api_router,
    prefix=(
        settings.api_v1_prefix
    ),
)