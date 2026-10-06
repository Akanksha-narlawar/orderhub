import os
import sys

import pytest

sys.path.insert(
    0,
    os.path.abspath(
        os.path.join(os.path.dirname(__file__), "..")
    )
)

from app.app import app


@pytest.fixture
def client():
    app.config["TESTING"] = True

    with app.test_client() as client:
        yield client


def test_home(client):
    response = client.get("/")
    assert response.status_code == 200

    data = response.get_json()
    assert data["message"] == "OrderHub API"


def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200

    data = response.get_json()
    assert data["status"] == "UP"


def test_orders(client):
    response = client.get("/orders")
    assert response.status_code == 200

    data = response.get_json()
    assert "orders" in data
    assert len(data["orders"]) > 0


def test_version_defaults(client, monkeypatch):
    monkeypatch.delenv("APP_VERSION", raising=False)
    monkeypatch.delenv("BUILD_NUMBER", raising=False)
    monkeypatch.delenv("GIT_COMMIT", raising=False)

    response = client.get("/version")
    assert response.status_code == 200

    data = response.get_json()

    assert data["version"] == "1.0.1"
    assert data["build"] == "unknown"
    assert data["commit"] == "unknown"


def test_version_environment_variables(client, monkeypatch):
    monkeypatch.setenv("APP_VERSION", "2.0.0")
    monkeypatch.setenv("BUILD_NUMBER", "100")
    monkeypatch.setenv("GIT_COMMIT", "abc123")

    response = client.get("/version")

    assert response.status_code == 200

    data = response.get_json()

    assert data["version"] == "2.0.0"
    assert data["build"] == "100"
    assert data["commit"] == "abc123"