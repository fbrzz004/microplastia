from pydantic import BaseModel, EmailStr, Field


class RegisterRequest(BaseModel):
    nombre: str = Field(
        min_length=1,
        max_length=100,
    )

    apellido: str | None = Field(
        default=None,
        max_length=100,
    )

    correo: EmailStr

    password: str = Field(
        min_length=8,
        max_length=64,
    )


class LoginRequest(BaseModel):
    correo: EmailStr

    password: str = Field(
        min_length=1,
        max_length=64,
    )


class UsuarioResponse(BaseModel):
    id_usuario: int
    nombre: str
    apellido: str | None = None
    correo: EmailStr
    rol: str
    estado: bool

    class Config:
        from_attributes = True


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    usuario: UsuarioResponse