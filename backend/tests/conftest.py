import uuid

import pytest
from fastapi.testclient import TestClient

from app.main import app


# ==========================================================
# CLIENTE HTTP
# ==========================================================

@pytest.fixture()
def client():
    """
    Cliente HTTP de pruebas.

    Se utiliza 127.0.0.1 para que sea compatible
    con TrustedHostMiddleware.
    """

    with TestClient(
        app,
        base_url="http://127.0.0.1",
    ) as test_client:

        yield test_client


# ==========================================================
# CORREO ÚNICO
# ==========================================================

@pytest.fixture()
def correo_unico() -> str:

    identificador = (
        uuid.uuid4()
        .hex[:12]
    )

    return (
        f"test_{identificador}"
        "@example.com"
    )


# ==========================================================
# PASSWORD SEGURA
# ==========================================================

@pytest.fixture()
def password_segura() -> str:

    return "Secreta123!"


# ==========================================================
# REGISTRAR USUARIO
# ==========================================================

@pytest.fixture()
def registrar_usuario(
    client,
    password_segura,
):

    def _registrar(
        correo: str,
        nombre: str = "Usuario Test",
        apellido: str = "Automático",
        password: str | None = None,
    ):

        return client.post(
            "/api/v1/auth/register",
            json={
                "nombre": nombre,
                "apellido": apellido,
                "correo": correo,
                "password": (
                    password
                    or password_segura
                ),
            },
        )

    return _registrar


# ==========================================================
# LOGIN
# ==========================================================

@pytest.fixture()
def login_usuario(
    client,
    password_segura,
):

    def _login(
        correo: str,
        password: str | None = None,
    ):

        return client.post(
            "/api/v1/auth/login",
            json={
                "correo": correo,
                "password": (
                    password
                    or password_segura
                ),
            },
        )

    return _login


# ==========================================================
# USUARIO AUTENTICADO
# ==========================================================

@pytest.fixture()
def usuario_autenticado(
    correo_unico,
    registrar_usuario,
    login_usuario,
):

    registro = registrar_usuario(
        correo_unico
    )

    assert (
        registro.status_code
        == 201
    ), registro.text


    login = login_usuario(
        correo_unico
    )

    assert (
        login.status_code
        == 200
    ), login.text


    data = login.json()

    token = data.get(
        "access_token"
    )

    assert token is not None


    return {
        "correo":
            correo_unico,

        "token":
            token,

        "usuario":
            data.get(
                "usuario"
            ),

        "headers": {
            "Authorization":
                f"Bearer {token}"
        },
    }


# ==========================================================
# HEADERS DE AUTENTICACIÓN
#
# Compatibilidad con tests antiguos y nuevos.
# ==========================================================

@pytest.fixture()
def auth_headers(
    usuario_autenticado,
):

    return (
        usuario_autenticado[
            "headers"
        ]
    )