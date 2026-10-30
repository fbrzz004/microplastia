import io
import uuid
from pathlib import Path

from PIL import Image


def _image_bytes() -> io.BytesIO:
    image = Image.new("RGB", (100, 100), color="green")
    buffer = io.BytesIO()
    image.save(buffer, format="JPEG")
    buffer.seek(0)
    return buffer


def _analyze(client, headers, sample_id: str) -> dict:
    response = client.post(
        "/api/v1/analyze",
        headers=headers,
        files={"file": ("reporte.jpg", _image_bytes(), "image/jpeg")},
        data={"sample_id": sample_id},
    )
    assert response.status_code == 200, response.text
    return response.json()["data"]


def _other_user(client, correo: str) -> dict:
    registro = client.post(
        "/api/v1/auth/register",
        json={
            "nombre": "Otro",
            "correo": correo,
            "password": "Secreta123!",
        },
    )
    assert registro.status_code == 201, registro.text

    login = client.post(
        "/api/v1/auth/login",
        json={"correo": correo, "password": "Secreta123!"},
    )
    assert login.status_code == 200, login.text

    return {"Authorization": f"Bearer {login.json()['access_token']}"}


def _cleanup(report_url: str) -> None:
    relative = report_url.removeprefix("/static/")
    path = Path("static") / relative
    path.unlink(missing_ok=True)


def test_report_requires_authentication(client):
    response = client.post(
        "/api/v1/reports",
        json={"result_ids": [1]},
    )
    assert response.status_code == 401


def test_report_rejects_empty_selection(client, auth_headers):
    response = client.post(
        "/api/v1/reports",
        headers=auth_headers,
        json={"result_ids": []},
    )
    assert response.status_code == 422


def test_report_generates_pdf(client, auth_headers):
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
        json={"result_ids": [first["result_id"], second["result_id"]]},
    )

    assert response.status_code == 201, response.text
    data = response.json()["data"]
    assert data["total_analyses"] == 2
    assert data["report_url"].startswith("/static/reports/")
    assert data["report_url"].endswith(".pdf")

    try:
        preview = client.get(data["report_url"])
        assert preview.status_code == 200
        assert preview.headers["content-type"] == "application/pdf"
        assert preview.content.startswith(b"%PDF")
        assert len(preview.content) > 1000
    finally:
        _cleanup(data["report_url"])


def test_report_rejects_unknown_result(client, auth_headers):
    response = client.post(
        "/api/v1/reports",
        headers=auth_headers,
        json={"result_ids": [999999]},
    )
    assert response.status_code == 404


def test_report_rejects_foreign_result(client, auth_headers, correo_unico):
    analysis = _analyze(
        client,
        auth_headers,
        f"REP-{uuid.uuid4().hex[:8].upper()}",
    )

    other_headers = _other_user(client, f"report_{correo_unico}")

    response = client.post(
        "/api/v1/reports",
        headers=other_headers,
        json={"result_ids": [analysis["result_id"]]},
    )

    assert response.status_code == 404
