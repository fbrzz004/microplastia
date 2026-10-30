from app.core.config import settings


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