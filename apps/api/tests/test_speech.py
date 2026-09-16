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


def test_detect_language_unauthenticated():
    # LID is an unauthenticated endpoint
    sample_wav = b"RIFF\x24\x00\x00\x00WAVEfmt \x10\x00\x00\x00\x01\x00\x01\x00\x80>\x00\x00\x00}\x00\x00\x02\x00\x10\x00data\x00\x00\x00\x00"
    response = client.post(
        "/v1/speech/detect-language",
        files={"file": ("sample.wav", sample_wav, "audio/wav")},
    )
    assert response.status_code == 200
    data = response.json()
    assert "language_code" in data
    assert "language_name" in data
    assert "greeting" in data
    assert "provenance" in data


def test_voice_navigation_commands():
    from kalasetu_api.engines.voice_navigation import parse_voice_command

    shop_cmd = parse_voice_command("दुकान खोलो", language_code="hi-IN")
    assert shop_cmd["intent"] == "navigation"
    assert shop_cmd["target"] == "/shop"
    assert "दुकान" in shop_cmd["spoken"]

    capture_cmd = parse_voice_command("नवीन उत्पादन", language_code="mr-IN")
    assert capture_cmd["intent"] == "navigation"
    assert capture_cmd["target"] == "/capture"

    money_cmd = parse_voice_command("कमाई का खाता", language_code="hi-IN")
    assert money_cmd["intent"] == "navigation"
    assert money_cmd["target"] == "/money"

    question_cmd = parse_voice_command("मेरा यह दाम कैसे तय हुआ?", language_code="hi-IN")
    assert question_cmd["intent"] == "question"
    assert question_cmd["action"] == "assistant"


def test_voice_action_navigation_endpoint():
    response = client.post(
        "/v1/speech/voice-action",
        data={"transcript": "दुकान खोलो", "language_code": "hi-IN"},
        headers={"Authorization": "Bearer demo"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["intent"] == "navigation"
    assert data["target"] == "/shop"
    assert data["action"] == "navigate"


def test_assistant_query_endpoint():
    response = client.post(
        "/v1/assistant/query",
        json={"query": "मेरा यह दाम कैसे तय हुआ?", "language_code": "hi-IN"},
        headers={"Authorization": "Bearer demo"},
    )
    assert response.status_code == 200
    data = response.json()
    assert "answer" in data
    assert data["language_code"] == "hi-IN"
    assert "provenance" in data

