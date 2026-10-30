from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    status,
)
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.password_policy import (
    validate_password,
)
from app.core.security import (
    get_current_user,
    hash_password,
    verify_password,
)
from app.db.session import get_db
from app.models.user import Usuario
from app.schemas.auth import (
    UsuarioResponse,
)
from app.schemas.profile import (
    ChangePasswordRequest,
    UpdateProfileRequest,
)
from app.services.auth_service import (
    normalize_email,
)


router = APIRouter(
    prefix="/users",
    tags=["Users"],
)


# ==========================================================
# ACTUALIZAR PERFIL
# ==========================================================

@router.put(
    "/me",
    response_model=UsuarioResponse,
)
def update_my_profile(
    data: UpdateProfileRequest,
    current_user: Usuario = Depends(
        get_current_user
    ),
    db: Session = Depends(
        get_db
    ),
):

    nombre = data.nombre.strip()

    apellido = (
        data.apellido.strip()
        if data.apellido
        else None
    )

    correo = normalize_email(
        str(data.correo)
    )


    # ------------------------------------------------------
    # NOMBRE
    # ------------------------------------------------------

    if not nombre:

        raise HTTPException(
            status_code=(
                status.HTTP_400_BAD_REQUEST
            ),
            detail=(
                "El nombre no puede estar vacío"
            ),
        )


    # ------------------------------------------------------
    # CORREO DUPLICADO
    # ------------------------------------------------------

    existing_user = (
        db.query(
            Usuario
        )
        .filter(
            Usuario.correo
            == correo,

            Usuario.id_usuario
            != current_user.id_usuario,
        )
        .first()
    )


    if existing_user:

        raise HTTPException(
            status_code=(
                status.HTTP_400_BAD_REQUEST
            ),
            detail=(
                "No se pudo actualizar "
                "el perfil"
            ),
        )


    # ------------------------------------------------------
    # ACTUALIZAR
    # ------------------------------------------------------

    current_user.nombre = nombre

    current_user.apellido = (
        apellido or None
    )

    current_user.correo = correo


    try:

        db.commit()

        db.refresh(
            current_user
        )

    except IntegrityError:

        db.rollback()

        raise HTTPException(
            status_code=(
                status.HTTP_400_BAD_REQUEST
            ),
            detail=(
                "No se pudo actualizar "
                "el perfil"
            ),
        )


    return current_user


# ==========================================================
# CAMBIAR CONTRASEÑA
# ==========================================================

@router.put(
    "/me/password",
    status_code=status.HTTP_200_OK,
)
def change_my_password(
    data: ChangePasswordRequest,
    current_user: Usuario = Depends(
        get_current_user
    ),
    db: Session = Depends(
        get_db
    ),
):

    # ------------------------------------------------------
    # CONTRASEÑA ACTUAL
    # ------------------------------------------------------

    if not verify_password(
        data.password_actual,
        current_user.password_hash,
    ):

        raise HTTPException(
            status_code=(
                status.HTTP_400_BAD_REQUEST
            ),
            detail=(
                "No se pudo cambiar "
                "la contraseña"
            ),
        )


    # ------------------------------------------------------
    # CONFIRMACIÓN
    # ------------------------------------------------------

    if (
        data.password_nueva
        != data.confirmar_password
    ):

        raise HTTPException(
            status_code=(
                status.HTTP_400_BAD_REQUEST
            ),
            detail=(
                "Las contraseñas nuevas "
                "no coinciden"
            ),
        )


    # ------------------------------------------------------
    # POLÍTICA
    # ------------------------------------------------------

    password_errors = validate_password(
        data.password_nueva
    )


    if password_errors:

        raise HTTPException(
            status_code=(
                status.HTTP_400_BAD_REQUEST
            ),
            detail={
                "message": (
                    "La nueva contraseña "
                    "no cumple los requisitos "
                    "de seguridad."
                ),
                "errors": password_errors,
            },
        )


    # ------------------------------------------------------
    # MISMA CONTRASEÑA
    # ------------------------------------------------------

    if verify_password(
        data.password_nueva,
        current_user.password_hash,
    ):

        raise HTTPException(
            status_code=(
                status.HTTP_400_BAD_REQUEST
            ),
            detail=(
                "La nueva contraseña debe "
                "ser diferente"
            ),
        )


    # ------------------------------------------------------
    # GUARDAR
    # ------------------------------------------------------

    current_user.password_hash = (
        hash_password(
            data.password_nueva
        )
    )

    db.commit()


    return {
        "message": (
            "Contraseña actualizada "
            "correctamente"
        )
    }