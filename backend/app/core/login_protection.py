import hashlib

from datetime import (
    datetime,
    timedelta,
    timezone,
)

from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.login_attempt import (
    LoginAttempt,
)


def _now() -> datetime:

    return datetime.now(
        timezone.utc
    )


def _hash_identifier(
    identifier: str,
) -> str:

    normalized = (
        identifier
        .strip()
        .lower()
    )

    return hashlib.sha256(
        normalized.encode(
            "utf-8"
        )
    ).hexdigest()


def _reset_record(
    record: LoginAttempt,
) -> None:

    record.failed_attempts = 0
    record.window_started_at = None
    record.blocked_until = None


def is_login_blocked(
    db: Session,
    identifier: str,
) -> bool:

    identifier_hash = (
        _hash_identifier(
            identifier
        )
    )

    now = _now()

    record = (
        db.query(
            LoginAttempt
        )
        .filter(
            LoginAttempt.identifier_hash
            == identifier_hash
        )
        .first()
    )

    if record is None:

        return False


    # ------------------------------------------------------
    # BLOQUEO ACTIVO
    # ------------------------------------------------------

    if record.blocked_until:

        if now < record.blocked_until:

            return True

        _reset_record(
            record
        )

        db.commit()

        return False


    # ------------------------------------------------------
    # VENTANA EXPIRADA
    # ------------------------------------------------------

    if record.window_started_at:

        window_limit = (
            record.window_started_at
            + timedelta(
                minutes=(
                    settings
                    .login_attempt_window_minutes
                )
            )
        )

        if now > window_limit:

            _reset_record(
                record
            )

            db.commit()


    return False


def register_failed_login(
    db: Session,
    identifier: str,
) -> None:

    identifier_hash = (
        _hash_identifier(
            identifier
        )
    )

    now = _now()

    record = (
        db.query(
            LoginAttempt
        )
        .filter(
            LoginAttempt.identifier_hash
            == identifier_hash
        )
        .with_for_update()
        .first()
    )


    # ------------------------------------------------------
    # PRIMER INTENTO
    # ------------------------------------------------------

    if record is None:

        record = LoginAttempt(
            identifier_hash=(
                identifier_hash
            ),
            failed_attempts=1,
            window_started_at=now,
        )

        db.add(
            record
        )

        db.commit()

        return


    # ------------------------------------------------------
    # SI YA ESTÁ BLOQUEADO
    # ------------------------------------------------------

    if (
        record.blocked_until
        and now
        < record.blocked_until
    ):

        return


    # ------------------------------------------------------
    # REINICIAR VENTANA
    # ------------------------------------------------------

    if (
        record.window_started_at
        is None
    ):

        record.window_started_at = now

        record.failed_attempts = 0

    else:

        window_limit = (
            record.window_started_at
            + timedelta(
                minutes=(
                    settings
                    .login_attempt_window_minutes
                )
            )
        )

        if now > window_limit:

            record.window_started_at = now

            record.failed_attempts = 0


    # ------------------------------------------------------
    # SUMAR INTENTO
    # ------------------------------------------------------

    record.failed_attempts += 1


    # ------------------------------------------------------
    # BLOQUEAR
    # ------------------------------------------------------

    if (
        record.failed_attempts
        >= settings.login_max_attempts
    ):

        record.blocked_until = (
            now
            + timedelta(
                minutes=(
                    settings
                    .login_block_minutes
                )
            )
        )


    db.commit()


def reset_login_attempts(
    db: Session,
    identifier: str,
) -> None:

    identifier_hash = (
        _hash_identifier(
            identifier
        )
    )

    record = (
        db.query(
            LoginAttempt
        )
        .filter(
            LoginAttempt.identifier_hash
            == identifier_hash
        )
        .first()
    )

    if record is None:

        return


    db.delete(
        record
    )

    db.commit()