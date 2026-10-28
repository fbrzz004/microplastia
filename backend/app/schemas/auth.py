from pydantic import BaseModel, EmailStr, Field

class RegisterRequest(BaseModel):
    nombre: str
    apellido: str | None = None
    correo: EmailStr
    password: str


class LoginRequest(BaseModel):
    correo: EmailStr
    password: str


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

class UpdateProfileRequest(BaseModel):
    nombre: str = Field(min_length=1, max_length=100)
    apellido: str | None = Field(default=None, max_length=100)
    correo: EmailStr


class ChangePasswordRequest(BaseModel):
    password_actual: str
    password_nueva: str = Field(min_length=8)
    confirmar_password: str
