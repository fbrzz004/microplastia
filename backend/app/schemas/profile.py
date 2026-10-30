from pydantic import BaseModel, EmailStr, Field


class UpdateProfileRequest(BaseModel):
    nombre: str = Field(
        min_length=1,
        max_length=100,
    )

    apellido: str | None = Field(
        default=None,
        max_length=100,
    )

    correo: EmailStr


class ChangePasswordRequest(BaseModel):
    password_actual: str = Field(
        min_length=1,
        max_length=64,
    )

    password_nueva: str = Field(
        min_length=8,
        max_length=64,
    )

    confirmar_password: str = Field(
        min_length=8,
        max_length=64,
    )