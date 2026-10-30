from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    status,
)
from sqlalchemy.exc import (
    IntegrityError,
)
from sqlalchemy.orm import Session

from app.core.login_protection import (
    is_login_blocked,
    register_failed_login,
    reset_login_attempts,
)
from app.core.password_policy import (
    validate_password,
)
from app.core.security import (
    create_access_token,
    get_current_user,
)
from app.db.session import get_db
from app.models.user import Usuario
from app.schemas.auth import (
    LoginRequest,
    RegisterRequest,
    TokenResponse,
    UsuarioResponse,
)
from app.services.auth_service import (
    authenticate_user,
    create_user,
    get_user_by_email,
    normalize_email,
)


router = APIRouter(
    prefix="/auth",
    tags=["Auth"],
)


# ==========================================================
# REGISTRO
# ==========================================================

@router.post(
    "/register",
    response_model=UsuarioResponse,
    status_code=(
        status.HTTP_201_CREATED
    ),
)
def register(
    data: RegisterRequest,
    db: Session = Depends(
        get_db
    ),
):

    nombre = (
        data.nombre.strip()
    )

    apellido = (
        data.apellido.strip()
        if data.apellido
        else None
    )

    correo = normalize_email(
        str(
            data.correo
        )
    )


    if not nombre:

        raise HTTPException(
            status_code=(
                status.HTTP_400_BAD_REQUEST
            ),
            detail=(
                "El nombre no puede "
                "estar vacío"
            ),
        )


    existing_user = (
        get_user_by_email(
            db,
            correo,
        )
    )


    if existing_user:

        raise HTTPException(
            status_code=(
                status.HTTP_400_BAD_REQUEST
            ),
            detail=(
                "No se pudo completar "
                "el registro"
            ),
        )


    password_errors = (
        validate_password(
            data.password
        )
    )


    if password_errors:

        raise HTTPException(
            status_code=(
                status.HTTP_400_BAD_REQUEST
            ),
            detail={
                "message": (
                    "La contraseña no cumple "
                    "los requisitos de seguridad."
                ),
                "errors":
                    password_errors,
            },
        )


    try:

        usuario = create_user(
            db=db,
            nombre=nombre,
            apellido=apellido,
            correo=correo,
            password=data.password,
        )

    except IntegrityError:

        db.rollback()

        raise HTTPException(
            status_code=(
                status.HTTP_400_BAD_REQUEST
            ),
            detail=(
                "No se pudo completar "
                "el registro"
            ),
        )


    return usuario


# ==========================================================
# LOGIN
# ==========================================================

@router.post(
    "/login",
    response_model=TokenResponse,
)
def login(
    data: LoginRequest,
    db: Session = Depends(
        get_db
    ),
):

    correo = normalize_email(
        str(
            data.correo
        )
    )


    # ------------------------------------------------------
    # RATE LIMIT
    # ------------------------------------------------------

    if is_login_blocked(
        db,
        correo,
    ):

        raise HTTPException(
            status_code=(
                status.HTTP_429_TOO_MANY_REQUESTS
            ),
            detail=(
                "Se realizaron demasiados "
                "intentos. Inténtalo "
                "nuevamente más tarde."
            ),
        )


    # ------------------------------------------------------
    # AUTENTICACIÓN
    # ------------------------------------------------------

    usuario = authenticate_user(
        db,
        correo,
        data.password,
    )


    if usuario is None:

        register_failed_login(
            db,
            correo,
        )

        raise HTTPException(
            status_code=(
                status.HTTP_401_UNAUTHORIZED
            ),
            detail=(
                "Credenciales inválidas"
            ),
            headers={
                "WWW-Authenticate":
                    "Bearer"
            },
        )


    # ------------------------------------------------------
    # CUENTA INACTIVA
    # ------------------------------------------------------

    if not usuario.estado:

        register_failed_login(
            db,
            correo,
        )

        raise HTTPException(
            status_code=(
                status.HTTP_403_FORBIDDEN
            ),
            detail=(
                "No se pudo iniciar sesión"
            ),
        )


    # ------------------------------------------------------
    # LOGIN EXITOSO
    # ------------------------------------------------------

    reset_login_attempts(
        db,
        correo,
    )


    token = create_access_token(
        {
            "sub": str(
                usuario.id_usuario
            ),
            "rol": usuario.rol,
        }
    )


    return {
        "access_token": token,
        "token_type": "bearer",
        "usuario": usuario,
    }


# ==========================================================
# USUARIO ACTUAL
# ==========================================================

@router.get(
    "/me",
    response_model=UsuarioResponse,
)
def get_my_profile(
    current_user: Usuario = Depends(
        get_current_user
    ),
):

    return current_user