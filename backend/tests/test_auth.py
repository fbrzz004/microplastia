import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.db.session import Base, get_db
from app.main import app

# Base de datos SQLite en memoria para aislar los tests del despliegue real.
engine = create_engine(
    "sqlite://",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base.metadata.create_all(bind=engine)


def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db
client = TestClient(app)


@pytest.fixture()
def correo_unico():
    return f"test_{uuid.uuid4().hex[:8]}@example.com"


def test_register_login_flow(correo_unico):
    registro = client.post(
        "/api/v1/auth/register",
        json={
            "nombre": "Test",
            "apellido": "Automático",
            "correo": correo_unico,
            "password": "Secreta123",
        },
    )
    assert registro.status_code == 201, registro.text
    assert registro.json()["correo"] == correo_unico
    assert "password_hash" not in registro.json()

    login = client.post(
        "/api/v1/auth/login",
        json={"correo": correo_unico, "password": "Secreta123"},
    )
    assert login.status_code == 200, login.text
    body = login.json()
    assert body["token_type"] == "bearer"
    assert body["access_token"]
    assert body["usuario"]["correo"] == correo_unico


def test_register_correo_duplicado(correo_unico):
    payload = {
        "nombre": "Test",
        "correo": correo_unico,
        "password": "Secreta123",
    }
    assert client.post("/api/v1/auth/register", json=payload).status_code == 201
    duplicado = client.post("/api/v1/auth/register", json=payload)
    assert duplicado.status_code == 400


def test_login_password_incorrecta(correo_unico):
    client.post(
        "/api/v1/auth/register",
        json={
            "nombre": "Test",
            "correo": correo_unico,
            "password": "Secreta123",
        },
    )
    respuesta = client.post(
        "/api/v1/auth/login",
        json={"correo": correo_unico, "password": "Incorrecta"},
    )
    assert respuesta.status_code == 401
