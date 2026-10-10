from sqlalchemy.orm import Session

from app.models.user import Usuario
from app.core.security import (
    hash_password,
    verify_password
)


def get_user_by_email(
    db: Session,
    correo: str
):
    return db.query(Usuario).filter(
        Usuario.correo == correo
    ).first()


def create_user(
    db: Session,
    nombre: str,
    apellido: str | None,
    correo: str,
    password: str
):
    usuario = Usuario(
        nombre=nombre,
        apellido=apellido,
        correo=correo,
        password_hash=hash_password(password),
        rol="usuario",
        estado=True
    )

    db.add(usuario)
    db.commit()
    db.refresh(usuario)

    return usuario


def authenticate_user(
    db: Session,
    correo: str,
    password: str
):
    usuario = get_user_by_email(
        db,
        correo
    )

    if not usuario:
        return None

    if not verify_password(
        password,
        usuario.password_hash
    ):
        return None

    return usuario