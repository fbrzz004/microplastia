import io

from fastapi.testclient import TestClient
from PIL import Image

from app.main import app

client = TestClient(app)


def _sample_image_bytes(fmt: str = "JPEG", color: str = "red") -> io.BytesIO:
    img = Image.new("RGB", (100, 100), color=color)
    buffer = io.BytesIO()
    img.save(buffer, format=fmt)
    buffer.seek(0)
    return buffer


def test_read_root():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"


def test_health_check():
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["data"]["status"] == "ok"


def test_analyze_endpoint():
    response = client.post(
        "/api/v1/analyze",
        files={"file": ("test_sample.jpg", _sample_image_bytes(), "image/jpeg")},
        data={"sample_id": "TEST-SAMPLE-01"},
    )

    assert response.status_code == 200
    res_data = response.json()
    assert res_data["success"] is True
    assert res_data["data"]["sample_id"] == "TEST-SAMPLE-01"
    assert res_data["data"]["total_particles"] >= 0
    assert isinstance(res_data["data"]["breakdown"], dict)
    assert "processing_time_ms" in res_data["data"]


def test_analyze_generates_annotated_image():
    response = client.post(
        "/api/v1/analyze",
        files={"file": ("annotated.jpg", _sample_image_bytes("PNG"), "image/png")},
    )

    assert response.status_code == 200
    annotated_url = response.json()["data"]["annotated_image_url"]
    assert annotated_url

    preview = client.get(annotated_url)
    assert preview.status_code == 200
    assert preview.headers["content-type"].startswith("image/")


def test_analyze_rejects_non_image():
    response = client.post(
        "/api/v1/analyze",
        files={"file": ("nota.txt", b"no soy una imagen", "text/plain")},
    )
    assert response.status_code == 400


def test_analyze_rejects_corrupt_image():
    response = client.post(
        "/api/v1/analyze",
        files={"file": ("rota.jpg", b"\xff\xd8\xff\xe0datos-basura", "image/jpeg")},
    )
    assert response.status_code == 400


def test_analyze_rejects_empty_file():
    response = client.post(
        "/api/v1/analyze",
        files={"file": ("vacia.jpg", b"", "image/jpeg")},
    )
    assert response.status_code == 400
