
from pydantic import BaseModel, Field


class UpdateProfileRequest(BaseModel):
    nombre: str = Field(min_length=1, max_length=100)
    apellido: str | None = Field(default=None, max_length=100)
    correo: str = Field(min_length=1, max_length=150)


class ChangePasswordRequest(BaseModel):
    password_actual: str = Field(min_length=1)
    password_nueva: str = Field(min_length=8)
    confirmar_password: str = Field(min_length=8)
