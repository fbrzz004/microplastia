from sqlalchemy.orm import Session

from app.core.security import (
    hash_password,
    verify_password,
)
from app.models.user import Usuario


def normalize_email(
    correo: str,
) -> str:

    return correo.strip().lower()


def get_user_by_email(
    db: Session,
    correo: str,
) -> Usuario | None:

    normalized_email = normalize_email(
        correo
    )

    return (
        db.query(Usuario)
        .filter(
            Usuario.correo
            == normalized_email
        )
        .first()
    )


def create_user(
    db: Session,
    nombre: str,
    apellido: str | None,
    correo: str,
    password: str,
) -> Usuario:

    usuario = Usuario(
        nombre=nombre.strip(),
        apellido=(
            apellido.strip()
            if apellido
            else None
        ),
        correo=normalize_email(
            correo
        ),
        password_hash=hash_password(
            password
        ),
        rol="usuario",
        estado=True,
    )

    db.add(
        usuario
    )

    db.commit()

    db.refresh(
        usuario
    )

    return usuario


def authenticate_user(
    db: Session,
    correo: str,
    password: str,
) -> Usuario | None:

    usuario = get_user_by_email(
        db,
        correo,
    )

    if usuario is None:
        return None

    if not verify_password(
        password,
        usuario.password_hash,
    ):
        return None

    return usuario