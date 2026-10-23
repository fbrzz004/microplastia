import io

from PIL import Image


def _sample_image_bytes(fmt: str = "JPEG", color: str = "red") -> io.BytesIO:
    img = Image.new("RGB", (100, 100), color=color)
    buffer = io.BytesIO()
    img.save(buffer, format=fmt)
    buffer.seek(0)
    return buffer


def test_read_root(client):
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"


def test_health_check(client):
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["data"]["status"] == "ok"


def test_analyze_endpoint(client, auth_headers):
    response = client.post(
        "/api/v1/analyze",
        headers=auth_headers,
        files={"file": ("test_sample.jpg", _sample_image_bytes(), "image/jpeg")},
        data={"sample_id": "TEST-SAMPLE-01"},
    )

    assert response.status_code == 200, response.text
    res_data = response.json()
    assert res_data["success"] is True
    assert res_data["data"]["sample_id"] == "TEST-SAMPLE-01"
    assert res_data["data"]["total_particles"] >= 0
    assert isinstance(res_data["data"]["breakdown"], dict)
    assert "processing_time_ms" in res_data["data"]
    assert res_data["data"]["result_id"] is not None


def test_analyze_requires_authentication(client):
    response = client.post(
        "/api/v1/analyze",
        files={"file": ("test_sample.jpg", _sample_image_bytes(), "image/jpeg")},
    )
    assert response.status_code == 401


def test_analyze_generates_annotated_image(client, auth_headers):
    response = client.post(
        "/api/v1/analyze",
        headers=auth_headers,
        files={"file": ("annotated.jpg", _sample_image_bytes("PNG"), "image/png")},
    )

    assert response.status_code == 200, response.text
    annotated_url = response.json()["data"]["annotated_image_url"]
    assert annotated_url

    preview = client.get(annotated_url)
    assert preview.status_code == 200
    assert preview.headers["content-type"].startswith("image/")


def test_analyze_accepts_octet_stream(client, auth_headers):
    response = client.post(
        "/api/v1/analyze",
        headers=auth_headers,
        files={
            "file": (
                "flutter.jpg",
                _sample_image_bytes(),
                "application/octet-stream",
            )
        },
    )
    assert response.status_code == 200, response.text


def test_analyze_rejects_non_image(client, auth_headers):
    response = client.post(
        "/api/v1/analyze",
        headers=auth_headers,
        files={"file": ("nota.txt", b"no soy una imagen", "text/plain")},
    )
    assert response.status_code == 400


def test_analyze_rejects_corrupt_image(client, auth_headers):
    response = client.post(
        "/api/v1/analyze",
        headers=auth_headers,
        files={"file": ("rota.jpg", b"\xff\xd8\xff\xe0datos-basura", "image/jpeg")},
    )
    assert response.status_code == 400


def test_analyze_rejects_empty_file(client, auth_headers):
    response = client.post(
        "/api/v1/analyze",
        headers=auth_headers,
        files={"file": ("vacia.jpg", b"", "image/jpeg")},
    )
    assert response.status_code == 400
