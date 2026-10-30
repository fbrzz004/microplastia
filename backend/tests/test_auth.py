# ==========================================================
# REGISTRO + LOGIN
# ==========================================================

def test_register_login_flow(
    client,
    correo_unico,
    password_segura,
):

    registro = client.post(
        "/api/v1/auth/register",
        json={
            "nombre":
                "Test",

            "apellido":
                "Automático",

            "correo":
                correo_unico,

            "password":
                password_segura,
        },
    )


    assert (
        registro.status_code
        == 201
    ), registro.text


    usuario = registro.json()


    assert (
        usuario.get(
            "correo"
        )
        == correo_unico
    )


    login = client.post(
        "/api/v1/auth/login",
        json={
            "correo":
                correo_unico,

            "password":
                password_segura,
        },
    )


    assert (
        login.status_code
        == 200
    ), login.text


    data = login.json()


    assert data.get(
        "access_token"
    )


    assert (
        data.get(
            "token_type"
        )
        == "bearer"
    )


    assert data.get(
        "usuario"
    )


# ==========================================================
# EMAIL DUPLICADO
# ==========================================================

def test_register_correo_duplicado(
    client,
    correo_unico,
    password_segura,
):

    payload = {
        "nombre":
            "Test",

        "apellido":
            "Usuario",

        "correo":
            correo_unico,

        "password":
            password_segura,
    }


    primera = client.post(
        "/api/v1/auth/register",
        json=payload,
    )


    assert (
        primera.status_code
        == 201
    )


    segunda = client.post(
        "/api/v1/auth/register",
        json=payload,
    )


    assert (
        segunda.status_code
        == 400
    )


# ==========================================================
# PASSWORD MUY DÉBIL / MUY CORTA
#
# Pydantic puede rechazarla antes de llegar a la
# política personalizada, por eso devuelve 422.
# ==========================================================

def test_register_rejects_weak_password(
    client,
    correo_unico,
):

    response = client.post(
        "/api/v1/auth/register",
        json={
            "nombre":
                "Test",

            "correo":
                correo_unico,

            "password":
                "123456",
        },
    )


    assert (
        response.status_code
        == 422
    )


# ==========================================================
# PASSWORD CON LONGITUD VÁLIDA
# PERO SIN REQUISITOS DE SEGURIDAD
# ==========================================================

def test_register_rejects_insecure_password(
    client,
    correo_unico,
):

    response = client.post(
        "/api/v1/auth/register",
        json={
            "nombre":
                "Test",

            "correo":
                correo_unico,

            "password":
                "password123",
        },
    )


    assert (
        response.status_code
        == 400
    )


# ==========================================================
# PASSWORD INCORRECTA
# ==========================================================

def test_login_password_incorrecta(
    client,
    correo_unico,
    password_segura,
):

    registro = client.post(
        "/api/v1/auth/register",
        json={
            "nombre":
                "Test",

            "correo":
                correo_unico,

            "password":
                password_segura,
        },
    )


    assert (
        registro.status_code
        == 201
    )


    respuesta = client.post(
        "/api/v1/auth/login",
        json={
            "correo":
                correo_unico,

            "password":
                "Incorrecta123!",
        },
    )


    assert (
        respuesta.status_code
        == 401
    )


# ==========================================================
# USUARIO AUTENTICADO
# ==========================================================

def test_get_authenticated_user(
    client,
    usuario_autenticado,
):

    response = client.get(
        "/api/v1/auth/me",

        headers=
            usuario_autenticado[
                "headers"
            ],
    )


    assert (
        response.status_code
        == 200
    ), response.text


    data = response.json()


    assert (
        data.get(
            "correo"
        )
        ==
        usuario_autenticado[
            "correo"
        ]
    )


# ==========================================================
# TOKEN INVÁLIDO
# ==========================================================

def test_invalid_token_rejected(
    client,
):

    response = client.get(
        "/api/v1/auth/me",

        headers={
            "Authorization":
                "Bearer token-invalido"
        },
    )


    assert (
        response.status_code
        == 401
    )