import json
import uuid


def _mobile_payload(
    sample_id: str,
) -> dict:
    return {
        "sample_id": sample_id,
        "total_particles": 2,
        "confidence": 0.75,
        "breakdown": {
            "fibra": 1,
            "fragmento": 1,
            "gránulo": 0,
            "partícula orgánica": 0,
        },
        "detections": [
            {
                "class_id": 1,
                "class_name": "fibra",
                "confidence": 0.80,
                "box": [
                    10.0,
                    10.0,
                    30.0,
                    30.0,
                ],
            },
            {
                "class_id": 2,
                "class_name": "fragmento",
                "confidence": 0.70,
                "box": [
                    32.0,
                    32.0,
                    50.0,
                    50.0,
                ],
            },
        ],
        "processing_time_ms": 500.0,
    }


def _analyze(
    client,
    headers,
    sample_id: str,
) -> dict:
    payload = _mobile_payload(
        sample_id
    )

    response = client.post(
        "/api/v1/analyze/mobile",
        headers=headers,
        data={
            "payload": json.dumps(
                payload,
                ensure_ascii=False,
            ),
        },
    )

    assert response.status_code == 200, (
        response.text
    )

    return response.json()["data"]


def test_report_requires_authentication(
    client,
):
    response = client.post(
        "/api/v1/reports",
        json={
            "result_ids": [1],
        },
    )

    assert response.status_code == 401


def test_report_rejects_empty_selection(
    client,
    auth_headers,
):
    response = client.post(
        "/api/v1/reports",
        headers=auth_headers,
        json={
            "result_ids": [],
        },
    )

    assert response.status_code in {
        400,
        422,
    }


def test_report_generates_pdf(
    client,
    auth_headers,
):
    first = _analyze(
        client,
        auth_headers,
        f"REP-{uuid.uuid4().hex[:8].upper()}",
    )

    second = _analyze(
        client,
        auth_headers,
        f"REP-{uuid.uuid4().hex[:8].upper()}",
    )

    response = client.post(
        "/api/v1/reports",
        headers=auth_headers,
        json={
            "result_ids": [
                first["result_id"],
                second["result_id"],
            ],
        },
    )

    # El endpoint crea un nuevo reporte.
    assert response.status_code == 201, (
        response.text
    )

    body = response.json()

    assert body["success"] is True

    assert (
        body["data"]["total_analyses"]
        == 2
    )

    report_url = (
        body["data"]["report_url"]
    )

    assert report_url
    assert report_url.endswith(".pdf")

    # report_url es una ruta local /static/...
    preview = client.get(
        report_url
    )

    assert preview.status_code == 200

    assert (
        preview.headers["content-type"]
        == "application/pdf"
    )

    assert preview.content.startswith(
        b"%PDF"
    )


def test_report_rejects_unknown_result(
    client,
    auth_headers,
):
    response = client.post(
        "/api/v1/reports",
        headers=auth_headers,
        json={
            "result_ids": [
                999999999,
            ],
        },
    )

    assert response.status_code in {
        400,
        404,
    }


def test_report_rejects_foreign_result(
    client,
    auth_headers,
):
    analysis = _analyze(
        client,
        auth_headers,
        f"REP-{uuid.uuid4().hex[:8].upper()}",
    )

    # Creamos un correo completamente distinto
    # al usuario ya autenticado.
    foreign_email = (
        f"foreign_"
        f"{uuid.uuid4().hex[:12]}"
        "@example.com"
    )

    register_response = client.post(
        "/api/v1/auth/register",
        json={
            "nombre": "Otro",
            "apellido": "Usuario",
            "correo": foreign_email,
            "password": "Password123!",
        },
    )

    assert (
        register_response.status_code
        == 201
    ), register_response.text

    login_response = client.post(
        "/api/v1/auth/login",
        json={
            "correo": foreign_email,
            "password": "Password123!",
        },
    )

    assert (
        login_response.status_code
        == 200
    ), login_response.text

    token = (
        login_response.json()
        ["access_token"]
    )

    foreign_headers = {
        "Authorization": (
            f"Bearer {token}"
        ),
    }

    response = client.post(
        "/api/v1/reports",
        headers=foreign_headers,
        json={
            "result_ids": [
                analysis["result_id"],
            ],
        },
    )

    assert response.status_code in {
        403,
        404,
    }