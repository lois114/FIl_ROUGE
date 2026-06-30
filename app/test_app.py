"""Tests unitaires de la mini-API (exécutés dans le pipeline CI)."""
from app import app


def test_health():
    client = app.test_client()
    r = client.get("/health")
    assert r.status_code == 200
    assert r.get_json()["status"] == "ok"


def test_resultats():
    client = app.test_client()
    r = client.get("/api/resultats/1042")
    assert r.status_code == 200
    assert r.get_json()["echantillon_id"] == 1042
