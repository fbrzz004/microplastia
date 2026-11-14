from app.core.config import (
    Settings,
    production_config_errors,
    settings,
)


# ==========================================================
# SECURITY HEADERS
# ==========================================================

def test_security_headers(
    client,
):

    response = client.get(
        "/health"
    )

    assert response.status_code == 200


    assert (
        response.headers.get(
            "x-content-type-options"
        )
        == "nosniff"
    )


    assert (
        response.headers.get(
            "x-frame-options"
        )
        == "DENY"
    )


    assert (
        response.headers.get(
            "referrer-policy"
        )
        == "no-referrer"
    )


    assert (
        "permissions-policy"
        in response.headers
    )


# ==========================================================
# TRUSTED HOST
# ==========================================================

def test_untrusted_host_is_rejected(
    client,
):

    response = client.get(
        "/health",
        headers={
            "Host":
                "sitio-malicioso.example"
        },
    )

    assert response.status_code == 400


# ==========================================================
# ADMIN SIN JWT
# ==========================================================

def test_admin_requires_authentication(
    client,
):

    response = client.get(
        "/api/v1/admin/dashboard"
    )

    assert response.status_code == 401


# ==========================================================
# JWT MALFORMADO
# ==========================================================

def test_malformed_jwt_is_rejected(
    client,
):

    response = client.get(
        "/api/v1/auth/me",

        headers={
            "Authorization":
                "Bearer abc.def.ghi"
        },
    )

    assert response.status_code == 401


# ==========================================================
# RATE LIMIT LOGIN
# ==========================================================

def test_login_rate_limit(
    client,
    correo_unico,
):

    estados = []


    intentos = (
        settings.login_max_attempts
        + 2
    )


    for _ in range(intentos):

        response = client.post(
            "/api/v1/auth/login",
            json={
                "correo":
                    correo_unico,

                "password":
                    "Incorrecta123!",
            },
        )

        estados.append(
            response.status_code
        )


    assert 429 in estados

# ==========================================================
# PRODUCCIÓN: CONFIGURACIÓN OBLIGATORIA
# ==========================================================

def _production_settings(**overrides) -> Settings:
    values = {
        "database_url": "sqlite://",
        "secret_key": "x" * 48,
        "environment": "production",
        "allowed_hosts": "microplastia-api.onrender.com",
        "allowed_origins": "https://microplastia-admin.vercel.app",
    }

    values.update(overrides)

    return Settings(**values)


def test_production_accepts_explicit_hosts_and_origins():

    errores = production_config_errors(
        _production_settings()
    )

    assert errores == []


def test_production_rejects_local_hosts():

    errores = production_config_errors(
        _production_settings(
            allowed_hosts="localhost,127.0.0.1",
        )
    )

    assert errores


def test_production_rejects_local_origins():

    errores = production_config_errors(
        _production_settings(
            allowed_origins="http://localhost:4200",
        )
    )

    assert errores


def test_production_rejects_placeholder_secret():

    errores = production_config_errors(
        _production_settings(
            secret_key=(
                "reemplaza-esta-clave-por-una-clave-segura-"
                "de-al-menos-32-caracteres"
            ),
        )
    )

    assert errores


def test_docs_are_disabled_in_production():

    ajustes = _production_settings(
        docs_enabled=True,
    )

    assert ajustes.docs_available is False
