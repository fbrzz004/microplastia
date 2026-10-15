from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.auth import (
    RegisterRequest,
    LoginRequest,
    UsuarioResponse,
    TokenResponse
)
from app.services.auth_service import (
    get_user_by_email,
    create_user,
    authenticate_user
)
from app.core.security import create_access_token


router = APIRouter(
    prefix="/auth",
    tags=["Auth"]
)


@router.post(
    "/register",
    response_model=UsuarioResponse,
    status_code=status.HTTP_201_CREATED
)
def register(
    data: RegisterRequest,
    db: Session = Depends(get_db)
):
    existing_user = get_user_by_email(
        db,
        data.correo
    )

    if existing_user:
        raise HTTPException(
            status_code=400,
            detail="El correo ya está registrado"
        )

    usuario = create_user(
        db=db,
        nombre=data.nombre,
        apellido=data.apellido,
        correo=data.correo,
        password=data.password
    )

    return usuario


@router.post(
    "/login",
    response_model=TokenResponse
)
def login(
    data: LoginRequest,
    db: Session = Depends(get_db)
):
    usuario = authenticate_user(
        db,
        data.correo,
        data.password
    )

    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Correo o contraseña incorrectos"
        )

    if not usuario.estado:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Usuario inactivo"
        )

    token = create_access_token(
        {
            "sub": str(usuario.id_usuario),
            "correo": usuario.correo,
            "rol": usuario.rol
        }
    )

    return {
        "access_token": token,
        "token_type": "bearer",
        "usuario": usuario
    }