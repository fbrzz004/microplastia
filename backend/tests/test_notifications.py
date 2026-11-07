import json


def _payload(sample_id: str = "NOTIF-SAMPLE-01") -> dict:
    return {
        "sample_id": sample_id,
        "total_particles": 1,
        "confidence": 0.8,
        "breakdown": {
            "fibra": 1,
        },
        "detections": [
            {
                "class_id": 1,
                "class_name": "fibra",
                "confidence": 0.8,
                "box": [10.0, 10.0, 30.0, 30.0],
            }
        ],
        "processing_time_ms": 100.0,
    }


def _create_analysis(
    client,
    headers,
    sample_id: str = "NOTIF-SAMPLE-01",
):
    return client.post(
        "/api/v1/analyze/mobile",
        headers=headers,
        data={
            "payload": json.dumps(
                _payload(sample_id),
                ensure_ascii=False,
            ),
        },
    )


def test_analysis_creates_notification(
    client,
    auth_headers,
):
    response = _create_analysis(
        client,
        auth_headers,
    )

    assert response.status_code == 200, response.text

    result_id = response.json()["data"]["result_id"]

    response = client.get(
        "/api/v1/notifications",
        headers=auth_headers,
    )

    assert response.status_code == 200, response.text

    data = response.json()["data"]

    assert data["total"] == 1
    assert data["unread_count"] == 1
    assert data["items"][0]["type"] == "analysis"
    assert data["items"][0]["result_id"] == result_id
    assert data["items"][0]["is_read"] is False


def test_mark_notification_as_read(
    client,
    auth_headers,
):
    _create_analysis(client, auth_headers)

    notifications = client.get(
        "/api/v1/notifications",
        headers=auth_headers,
    ).json()["data"]["items"]

    notification_id = notifications[0]["id"]

    response = client.post(
        f"/api/v1/notifications/{notification_id}/read",
        headers=auth_headers,
    )

    assert response.status_code == 200, response.text
    assert response.json()["data"]["is_read"] is True

    count = client.get(
        "/api/v1/notifications/unread-count",
        headers=auth_headers,
    )

    assert count.status_code == 200
    assert count.json()["unread_count"] == 0


def test_mark_all_notifications_as_read(
    client,
    auth_headers,
):
    _create_analysis(client, auth_headers, "NOTIF-1")
    _create_analysis(client, auth_headers, "NOTIF-2")

    response = client.post(
        "/api/v1/notifications/read-all",
        headers=auth_headers,
    )

    assert response.status_code == 200, response.text
    assert response.json()["data"]["updated"] == 2
    assert response.json()["data"]["unread_count"] == 0


def test_notification_preference_blocks_new_notifications(
    client,
    auth_headers,
):
    response = client.put(
        "/api/v1/users/me/preferences",
        headers=auth_headers,
        json={"notificaciones_activas": False},
    )

    assert response.status_code == 200, response.text
    assert response.json()["data"]["notificaciones_activas"] is False

    _create_analysis(client, auth_headers)

    data = client.get(
        "/api/v1/notifications",
        headers=auth_headers,
    ).json()["data"]

    assert data["total"] == 0


def test_notification_preference_can_be_enabled_again(
    client,
    auth_headers,
):
    client.put(
        "/api/v1/users/me/preferences",
        headers=auth_headers,
        json={"notificaciones_activas": False},
    )

    client.put(
        "/api/v1/users/me/preferences",
        headers=auth_headers,
        json={"notificaciones_activas": True},
    )

    _create_analysis(client, auth_headers)

    data = client.get(
        "/api/v1/notifications",
        headers=auth_headers,
    ).json()["data"]

    assert data["total"] == 1


def test_websocket_receives_new_notification(
    client,
    usuario_autenticado,
):
    token = usuario_autenticado["token"]
    headers = usuario_autenticado["headers"]

    with client.websocket_connect(
        f"/api/v1/notifications/ws?token={token}",
        headers={"host": "127.0.0.1"},
    ) as websocket:
        _create_analysis(
            client,
            headers,
            "NOTIF-WS",
        )

        event = websocket.receive_json()

        assert event["event"] == "notification.created"
        assert event["data"]["type"] == "analysis"
        assert event["data"]["result_id"] is not None
