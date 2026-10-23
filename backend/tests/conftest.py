import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.db.session import Base, get_db
import app.models  # noqa: F401  (registra los modelos en el metadata)
from app.main import app

# Base de datos SQLite en memoria para aislar los tests del despliegue real.
engine = create_engine(
    "sqlite://",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)
Base.metadata.create_all(bind=engine)


def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db


@pytest.fixture()
def client():
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture()
def correo_unico():
    return f"test_{uuid.uuid4().hex[:8]}@example.com"


@pytest.fixture()
def usuario(client, correo_unico):
    registro = client.post(
        "/api/v1/auth/register",
        json={
            "nombre": "Test",
            "correo": correo_unico,
            "password": "Secreta123",
        },
    )
    assert registro.status_code == 201, registro.text

    login = client.post(
        "/api/v1/auth/login",
        json={"correo": correo_unico, "password": "Secreta123"},
    )
    assert login.status_code == 200, login.text

    return login.json()


@pytest.fixture()
def auth_headers(usuario):
    return {"Authorization": f"Bearer {usuario['access_token']}"}
