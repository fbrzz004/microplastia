import re


MIN_PASSWORD_LENGTH = 8
MAX_PASSWORD_LENGTH = 64


COMMON_PASSWORDS = {
    "password",
    "password123",
    "12345678",
    "123456789",
    "qwerty123",
    "admin123",
    "admin1234",
}


def validate_password(
    password: str,
) -> list[str]:

    errors: list[str] = []


    if len(password) < MIN_PASSWORD_LENGTH:

        errors.append(
            "La contraseña debe tener "
            "al menos 8 caracteres."
        )


    if len(password) > MAX_PASSWORD_LENGTH:

        errors.append(
            "La contraseña no puede "
            "superar 64 caracteres."
        )


    if not re.search(
        r"[A-Z]",
        password,
    ):

        errors.append(
            "Debe incluir al menos "
            "una letra mayúscula."
        )


    if not re.search(
        r"[a-z]",
        password,
    ):

        errors.append(
            "Debe incluir al menos "
            "una letra minúscula."
        )


    if not re.search(
        r"\d",
        password,
    ):

        errors.append(
            "Debe incluir al menos "
            "un número."
        )


    if not re.search(
        r"[!@#$%^&*()_\-+=\[\]{};:,.?]",
        password,
    ):

        errors.append(
            "Debe incluir al menos "
            "un carácter especial."
        )


    if password.lower() in COMMON_PASSWORDS:

        errors.append(
            "La contraseña es demasiado común."
        )


    if password != password.strip():

        errors.append(
            "La contraseña no debe comenzar "
            "ni terminar con espacios."
        )


    return errors


def is_password_valid(
    password: str,
) -> bool:

    return (
        len(
            validate_password(
                password
            )
        )
        == 0
    )