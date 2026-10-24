import io
import uuid

from PIL import Image


def _image_bytes() -> io.BytesIO:
    img = Image.new("RGB", (100, 100), color="blue")
    buffer = io.BytesIO()
    img.save(buffer, format="JPEG")
    buffer.seek(0)
    return buffer


def _analyze(client, headers, sample_id: str):
    response = client.post(
        "/api/v1/analyze",
        headers=headers,
        files={"file": ("muestra.jpg", _image_bytes(), "image/jpeg")},
        data={"sample_id": sample_id},
    )
    assert response.status_code == 200, response.text
    return response.json()["data"]


def _nuevo_usuario(client, correo: str) -> dict:
    registro = client.post(
        "/api/v1/auth/register",
        json={
            "nombre": "Otro",
            "correo": correo,
            "password": "Secreta123",
        },
    )
    assert registro.status_code == 201, registro.text

    login = client.post(
        "/api/v1/auth/login",
        json={"correo": correo, "password": "Secreta123"},
    )
    assert login.status_code == 200, login.text

    return {"Authorization": f"Bearer {login.json()['access_token']}"}


def test_history_requires_authentication(client):
    assert client.get("/api/v1/history").status_code == 401
    assert client.get("/api/v1/results/1").status_code == 401


def test_history_lists_analyses_of_the_user(client, auth_headers):
    sample_id = f"MUESTRA-{uuid.uuid4().hex[:8].upper()}"
    analysis = _analyze(client, auth_headers, sample_id)

    response = client.get("/api/v1/history", headers=auth_headers)

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["success"] is True
    assert body["data"]["total"] == 1

    item = body["data"]["items"][0]
    assert item["id"] == analysis["result_id"]
    assert item["sample_id"] == sample_id
    assert item["total_particles"] == analysis["total_particles"]
    assert item["created_at"]


def test_history_detail_returns_full_analysis(client, auth_headers):
    sample_id = f"MUESTRA-{uuid.uuid4().hex[:8].upper()}"
    analysis = _analyze(client, auth_headers, sample_id)

    response = client.get(
        f"/api/v1/results/{analysis['result_id']}",
        headers=auth_headers,
    )

    assert response.status_code == 200, response.text
    detail = response.json()["data"]
    assert detail["id"] == analysis["result_id"]
    assert detail["sample_id"] == sample_id
    assert detail["breakdown"] == analysis["breakdown"]
    assert detail["processing_time_ms"] == analysis["processing_time_ms"]
    assert isinstance(detail["detections"], list)


def test_history_detail_not_found(client, auth_headers):
    response = client.get("/api/v1/results/999999", headers=auth_headers)
    assert response.status_code == 404


def test_history_is_isolated_between_users(client, auth_headers, correo_unico):
    sample_id = f"MUESTRA-{uuid.uuid4().hex[:8].upper()}"
    analysis = _analyze(client, auth_headers, sample_id)

    other_headers = _nuevo_usuario(
        client,
        f"otro_{correo_unico}",
    )

    history = client.get("/api/v1/history", headers=other_headers)
    assert history.status_code == 200
    assert history.json()["data"]["total"] == 0

    detail = client.get(
        f"/api/v1/results/{analysis['result_id']}",
        headers=other_headers,
    )
    assert detail.status_code == 404


def test_history_search_by_sample_id(client, auth_headers):
    sample_id = f"BUSCAR-{uuid.uuid4().hex[:8].upper()}"
    _analyze(client, auth_headers, sample_id)

    response = client.get(
        "/api/v1/history",
        headers=auth_headers,
        params={"q": sample_id[:10]},
    )

    assert response.status_code == 200, response.text
    items = response.json()["data"]["items"]
    assert len(items) == 1
    assert items[0]["sample_id"] == sample_id


def test_history_pagination(client, auth_headers):
    for _ in range(3):
        _analyze(
            client,
            auth_headers,
            f"PAG-{uuid.uuid4().hex[:8].upper()}",
        )

    response = client.get(
        "/api/v1/history",
        headers=auth_headers,
        params={"limit": 2, "offset": 0},
    )
    assert response.status_code == 200
    assert len(response.json()["data"]["items"]) == 2

    siguiente = client.get(
        "/api/v1/history",
        headers=auth_headers,
        params={"limit": 2, "offset": 2},
    )
    assert siguiente.status_code == 200
    assert len(siguiente.json()["data"]["items"]) == 1
