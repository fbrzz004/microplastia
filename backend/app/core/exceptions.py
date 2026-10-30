import logging

from fastapi import Request
from fastapi.responses import JSONResponse
from sqlalchemy.exc import SQLAlchemyError


logger = logging.getLogger(
    "microplastia"
)


# ==========================================================
# ERROR DE BASE DE DATOS
# ==========================================================

async def database_exception_handler(
    request: Request,
    exc: SQLAlchemyError,
):

    logger.exception(
        "Database error | %s %s",
        request.method,
        request.url.path,
    )

    return JSONResponse(
        status_code=503,
        content={
            "success": False,
            "message": (
                "El servicio no está "
                "disponible temporalmente. "
                "Inténtalo nuevamente."
            ),
        },
    )


# ==========================================================
# ERROR INTERNO
# ==========================================================

async def unexpected_exception_handler(
    request: Request,
    exc: Exception,
):

    logger.exception(
        "Unexpected error | %s %s",
        request.method,
        request.url.path,
    )

    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "message": (
                "No se pudo completar "
                "la operación."
            ),
        },
    )