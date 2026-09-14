from fastapi.testclient import TestClient

from kalasetu_api.main import app

client = TestClient(app)


def test_speech_routes_require_bearer():
    assert client.post("/v1/speech/stt").status_code == 401
    assert client.post("/v1/speech/tts", json={"text": "नमस्कार"}).status_code == 401
    assert client.post("/v1/speech/live/turn", json={}).status_code == 401


def test_catalog_turn_starts_marathi_interview():
    response = client.post(
        "/v1/speech/live/turn",
        json={"language_code": "mr-IN", "cluster": "varanasi"},
        headers={"Authorization": "Bearer demo"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["done"] is False
    assert body["phase"] == "interviewing"
    assert "उत्पादन" in body["question"]
    assert body["session"]["current_slot"] == "craft"
