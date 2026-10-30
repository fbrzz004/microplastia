import logging
import sys

from app.core.config import settings


def configure_logging() -> None:

    level_name = (
        settings.log_level
        .strip()
        .upper()
    )

    level = getattr(
        logging,
        level_name,
        logging.INFO,
    )


    formatter = logging.Formatter(
        "%(asctime)s | "
        "%(levelname)s | "
        "%(name)s | "
        "%(message)s"
    )


    handler = logging.StreamHandler(
        sys.stdout
    )

    handler.setFormatter(
        formatter
    )


    root_logger = logging.getLogger()

    root_logger.handlers.clear()

    root_logger.setLevel(
        level
    )

    root_logger.addHandler(
        handler
    )


    # Reducimos ruido de librerías externas
    logging.getLogger(
        "sqlalchemy.engine"
    ).setLevel(
        logging.WARNING
    )

    logging.getLogger(
        "multipart"
    ).setLevel(
        logging.WARNING
    )


    logger = logging.getLogger(
        "microplastia"
    )

    logger.info(
        "Logging configurado | "
        "environment=%s",
        settings.environment,
    )