from fastapi.testclient import TestClient

from kalasetu_api.main import app

client = TestClient(app)


def test_health_ok():
    response = client.get("/health")
    assert response.status_code == 200
    body = response.json()
    assert body["ok"] is True
    assert body["firestore_location"] == "asia-south1"
    assert body["storage_location"] == "us-east1"
    assert "sarvam_api_key" in body["wired"]


def test_otp_mock_roundtrip():
    sent = client.post("/v1/auth/otp", json={"phone": "9876543210"})
    assert sent.status_code == 200
    assert sent.json()["label"] == "Mock — for SIH demo"

    bad = client.post("/v1/auth/verify", json={"phone": "9876543210", "code": "000000"})
    assert bad.status_code == 401

    ok = client.post("/v1/auth/verify", json={"phone": "9876543210", "code": "123456"})
    assert ok.status_code == 200
    assert ok.json()["token"].startswith("dev.")


def test_local_flutter_web_preflight_allows_dynamic_port():
    response = client.options(
        "/v1/auth/otp",
        headers={
            "Origin": "http://localhost:5000",
            "Access-Control-Request-Method": "POST",
            "Access-Control-Request-Headers": "content-type",
        },
    )
    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == "http://localhost:5000"


def test_enhance_requires_auth():
    response = client.post("/v1/images/enhance")
    assert response.status_code == 401
