
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.security import (
    get_current_user,
    hash_password,
    verify_password,
)
from app.db.session import get_db
from app.models.user import Usuario
from app.schemas.auth import UsuarioResponse
from app.schemas.profile import (
    UpdateProfileRequest,
    ChangePasswordRequest,
)
from app.db.session import get_db
router = APIRouter(
    prefix="/users",
    tags=["Users"],
)


@router.put(
    "/me",
    response_model=UsuarioResponse,
)
def update_my_profile(
    data: UpdateProfileRequest,
    current_user: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    nombre = data.nombre.strip()
    apellido = data.apellido.strip() if data.apellido else None
    correo = data.correo.strip().lower()

    if not nombre:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El nombre no puede estar vacío",
        )

    if not correo:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El correo no puede estar vacío",
        )

    existing_user = (
        db.query(Usuario)
        .filter(
            Usuario.correo == correo,
            Usuario.id_usuario != current_user.id_usuario,
        )
        .first()
    )

    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El correo ya está registrado",
        )

    current_user.nombre = nombre
    current_user.apellido = apellido or None
    current_user.correo = correo

    db.commit()
    db.refresh(current_user)

    return current_user


@router.put("/me/password", status_code=status.HTTP_200_OK)
def change_my_password(
    data: ChangePasswordRequest,
    current_user: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if not verify_password(
        data.password_actual,
        current_user.password_hash,
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La contraseña actual es incorrecta",
        )

    if data.password_nueva != data.confirmar_password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Las contraseñas nuevas no coinciden",
        )

    if verify_password(
        data.password_nueva,
        current_user.password_hash,
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La nueva contraseña debe ser diferente",
        )

    current_user.password_hash = hash_password(
        data.password_nueva
    )

    db.commit()
    return {
        "message": "Contraseña actualizada correctamente"
    }   
