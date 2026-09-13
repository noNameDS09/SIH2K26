import uuid
from fastapi.testclient import TestClient

from kalasetu_api.main import app

client = TestClient(app)


def test_otp_request_normalizes_phone():
    response = client.post("/v1/auth/otp", json={"phone": "9876543210"})
    assert response.status_code == 200
    body = response.json()
    assert body["ok"] is True
    assert body["phone"] == "+919876543210"
    assert body["label"] == "Mock — for SIH demo"


def test_verify_otp_bad_code():
    response = client.post("/v1/auth/verify", json={"phone": "9876543210", "code": "000000"})
    assert response.status_code == 401


def test_verify_otp_creates_and_persists_uuid_for_phone():
    phone = "9876512345"
    response1 = client.post("/v1/auth/verify", json={"phone": phone, "code": "123456"})
    assert response1.status_code == 200
    body1 = response1.json()
    assert body1["ok"] is True
    uid1 = body1["uid"]
    # Check that uid is a valid UUID
    uuid_obj = uuid.UUID(uid1)
    assert str(uuid_obj) == uid1
    assert body1["phone"] == "+919876512345"
    assert body1["token"] == f"dev.{uid1}"
    assert "artisan" in body1
    assert body1["artisan"]["uid"] == uid1

    # Second login with same phone must return the EXACT same UUID!
    response2 = client.post("/v1/auth/verify", json={"phone": phone, "code": "123456"})
    assert response2.status_code == 200
    body2 = response2.json()
    assert body2["uid"] == uid1
    assert body2["token"] == f"dev.{uid1}"


def test_auth_me_and_update_profile():
    # Login first
    phone = "9123456789"
    auth_resp = client.post("/v1/auth/verify", json={"phone": phone, "code": "123456"})
    token = auth_resp.json()["token"]
    uid = auth_resp.json()["uid"]

    # GET /v1/auth/me
    me_resp = client.get("/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert me_resp.status_code == 200
    assert me_resp.json()["artisan"]["uid"] == uid
    assert me_resp.json()["artisan"]["phone"] == "+919123456789"

    # PATCH /v1/auth/profile (onboarding simulation)
    update_resp = client.patch(
        "/v1/auth/profile",
        json={"name": "Aarti Devi", "cluster": "varanasi", "lang": "hi-IN"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert update_resp.status_code == 200
    artisan = update_resp.json()["artisan"]
    assert artisan["name"] == "Aarti Devi"
    assert artisan["cluster"] == "varanasi"
    assert artisan["lang"] == "hi-IN"

    # Verify GET returns updated fields
    recheck = client.get("/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert recheck.json()["artisan"]["name"] == "Aarti Devi"
