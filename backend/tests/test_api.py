import io
import json

from PIL import Image


def _sample_image_bytes(
    image_format: str = "JPEG",
) -> bytes:
    image = Image.new(
        "RGB",
        (64, 64),
        color=(120, 180, 200),
    )

    buffer = io.BytesIO()

    image.save(
        buffer,
        format=image_format,
    )

    return buffer.getvalue()


def _mobile_payload(
    sample_id: str = "TEST-SAMPLE-01",
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
        "processing_time_ms": 523.5,
    }


def test_read_root(client):
    response = client.get("/")

    assert response.status_code == 200


def test_health_check(client):
    response = client.get("/health")

    assert response.status_code == 200


def test_mobile_analyze_endpoint(
    client,
    auth_headers,
):
    payload = _mobile_payload()

    response = client.post(
        "/api/v1/analyze/mobile",
        headers=auth_headers,
        data={
            "payload": json.dumps(
                payload,
                ensure_ascii=False,
            ),
        },
        files={
            "annotated_file": (
                "annotated.jpg",
                _sample_image_bytes(),
                "image/jpeg",
            ),
        },
    )

    assert response.status_code == 200, (
        response.text
    )

    body = response.json()

    assert body["success"] is True

    assert (
        body["data"]["sample_id"]
        == "TEST-SAMPLE-01"
    )

    assert (
        body["data"]["total_particles"]
        == 2
    )

    assert len(
        body["data"]["detections"]
    ) == 2

    assert (
        body["data"]["result_id"]
        is not None
    )


def test_mobile_analyze_requires_authentication(
    client,
):
    payload = _mobile_payload()

    response = client.post(
        "/api/v1/analyze/mobile",
        data={
            "payload": json.dumps(
                payload,
                ensure_ascii=False,
            ),
        },
    )

    assert response.status_code == 401


def test_mobile_analyze_generates_annotated_image(
    client,
    auth_headers,
):
    payload = _mobile_payload(
        "TEST-ANNOTATED-01"
    )

    response = client.post(
        "/api/v1/analyze/mobile",
        headers=auth_headers,
        data={
            "payload": json.dumps(
                payload,
                ensure_ascii=False,
            ),
        },
        files={
            "annotated_file": (
                "annotated.png",
                _sample_image_bytes("PNG"),
                "image/png",
            ),
        },
    )

    assert response.status_code == 200, (
        response.text
    )

    body = response.json()

    annotated_url = (
        body["data"]
        ["annotated_image_url"]
    )

    assert annotated_url
    assert isinstance(
        annotated_url,
        str,
    )


def test_mobile_analyze_without_image(
    client,
    auth_headers,
):
    payload = _mobile_payload(
        "TEST-NO-IMAGE-01"
    )

    response = client.post(
        "/api/v1/analyze/mobile",
        headers=auth_headers,
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

    body = response.json()

    assert (
        body["data"]
        ["annotated_image_url"]
        is None
    )


def test_mobile_analyze_rejects_invalid_payload(
    client,
    auth_headers,
):
    response = client.post(
        "/api/v1/analyze/mobile",
        headers=auth_headers,
        data={
            "payload": (
                "esto-no-es-json"
            ),
        },
    )

    assert response.status_code == 400


def test_mobile_analyze_rejects_inconsistent_count(
    client,
    auth_headers,
):
    payload = _mobile_payload(
        "TEST-INVALID-COUNT"
    )

    payload["total_particles"] = 5

    response = client.post(
        "/api/v1/analyze/mobile",
        headers=auth_headers,
        data={
            "payload": json.dumps(
                payload,
                ensure_ascii=False,
            ),
        },
    )

    assert response.status_code == 400

    assert (
        "total_particles"
        in response.json()["detail"]
    )


def test_mobile_analyze_rejects_corrupt_image(
    client,
    auth_headers,
):
    payload = _mobile_payload(
        "TEST-CORRUPT-IMAGE"
    )

    response = client.post(
        "/api/v1/analyze/mobile",
        headers=auth_headers,
        data={
            "payload": json.dumps(
                payload,
                ensure_ascii=False,
            ),
        },
        files={
            "annotated_file": (
                "corrupta.jpg",
                b"\xff\xd8datos-basura",
                "image/jpeg",
            ),
        },
    )

    assert response.status_code == 400