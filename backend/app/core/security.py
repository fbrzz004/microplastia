from datetime import (
    datetime,
    timedelta,
    timezone,
)

from fastapi import (
    Depends,
    HTTPException,
    status,
)

from fastapi.security import (
    HTTPAuthorizationCredentials,
    HTTPBearer,
)

from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.session import get_db
from app.models.user import Usuario


# ==========================================================
# PASSWORD HASHING
# ==========================================================

pwd_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto",
)


def hash_password(
    password: str,
) -> str:

    return pwd_context.hash(
        password
    )


def verify_password(
    plain_password: str,
    hashed_password: str,
) -> bool:

    try:

        return pwd_context.verify(
            plain_password,
            hashed_password,
        )

    except Exception:

        return False


# ==========================================================
# JWT
# ==========================================================

def create_access_token(
    data: dict,
    expires_delta: timedelta | None = None,
) -> str:

    now = datetime.now(
        timezone.utc
    )

    expire = (
        now + expires_delta
        if expires_delta
        else now
        + timedelta(
            minutes=(
                settings
                .access_token_expire_minutes
            )
        )
    )

    to_encode = data.copy()

    to_encode.update(
        {
            "iat": now,
            "exp": expire,
            "type": "access",
        }
    )

    return jwt.encode(
        to_encode,
        settings.secret_key,
        algorithm=settings.algorithm,
    )


# ==========================================================
# BEARER TOKEN
# ==========================================================

bearer_scheme = HTTPBearer(
    auto_error=False
)


# ==========================================================
# RESOLVER USUARIO
# ==========================================================

def _resolve_user(
    credentials:
        HTTPAuthorizationCredentials
        | None,

    db: Session,

) -> Usuario | None:

    if credentials is None:
        return None

    try:

        payload = jwt.decode(
            credentials.credentials,
            settings.secret_key,
            algorithms=[
                settings.algorithm
            ],
        )

        token_type = payload.get(
            "type"
        )

        if token_type != "access":

            raise ValueError(
                "Tipo de token inválido"
            )

        subject = payload.get(
            "sub"
        )

        if subject is None:

            raise ValueError(
                "Token sin sujeto"
            )

        user_id = int(
            subject
        )

    except (
        JWTError,
        ValueError,
        TypeError,
    ) as exc:

        raise HTTPException(
            status_code=(
                status.HTTP_401_UNAUTHORIZED
            ),
            detail=(
                "Sesión inválida o expirada"
            ),
            headers={
                "WWW-Authenticate":
                    "Bearer"
            },
        ) from exc


    usuario = db.get(
        Usuario,
        user_id,
    )


    if usuario is None:

        raise HTTPException(
            status_code=(
                status.HTTP_401_UNAUTHORIZED
            ),
            detail=(
                "Sesión inválida o expirada"
            ),
            headers={
                "WWW-Authenticate":
                    "Bearer"
            },
        )


    if not usuario.estado:

        raise HTTPException(
            status_code=(
                status.HTTP_403_FORBIDDEN
            ),
            detail=(
                "Acceso no autorizado"
            ),
        )


    return usuario


# ==========================================================
# USUARIO AUTENTICADO
# ==========================================================

def get_current_user(
    credentials:
        HTTPAuthorizationCredentials
        | None
        = Depends(
            bearer_scheme
        ),

    db: Session = Depends(
        get_db
    ),

) -> Usuario:

    usuario = _resolve_user(
        credentials,
        db,
    )

    if usuario is None:

        raise HTTPException(
            status_code=(
                status.HTTP_401_UNAUTHORIZED
            ),
            detail=(
                "Se requiere autenticación"
            ),
            headers={
                "WWW-Authenticate":
                    "Bearer"
            },
        )

    return usuario


# ==========================================================
# ADMINISTRADOR
# ==========================================================

def get_current_admin(
    current_user: Usuario = Depends(
        get_current_user
    ),
) -> Usuario:

    if (
        current_user.rol
        != "administrador"
    ):

        raise HTTPException(
            status_code=(
                status.HTTP_403_FORBIDDEN
            ),
            detail=(
                "No tienes permisos "
                "para realizar esta operación"
            ),
        )

    return current_user