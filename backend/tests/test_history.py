# ==========================================================
# HISTORIAL REQUIERE AUTH
# ==========================================================

def test_history_requires_authentication(
    client,
):

    response = client.get(
        "/api/v1/history"
    )

    assert response.status_code == 401


# ==========================================================
# HISTORIAL DEL USUARIO
# ==========================================================

def test_history_authenticated(
    client,
    usuario_autenticado,
):

    response = client.get(
        "/api/v1/history",

        headers=
            usuario_autenticado[
                "headers"
            ],
    )

    assert response.status_code == 200, (
        response.text
    )

    data = response.json()

    assert isinstance(
        data,
        (list, dict),
    )


# ==========================================================
# DETALLE INEXISTENTE
# ==========================================================

def test_history_detail_not_found(
    client,
    usuario_autenticado,
):

    response = client.get(
        "/api/v1/history/999999999",

        headers=
            usuario_autenticado[
                "headers"
            ],
    )

    assert response.status_code == 404


# ==========================================================
# TOKEN INVÁLIDO
# ==========================================================

def test_history_invalid_token(
    client,
):

    response = client.get(
        "/api/v1/history",

        headers={
            "Authorization":
                "Bearer token-falso"
        },
    )

    assert response.status_code == 401