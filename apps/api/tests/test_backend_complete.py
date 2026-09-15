from datetime import datetime, timedelta, timezone

from fastapi.testclient import TestClient

from kalasetu_api.adapters.firebase import _MEM_LISTINGS
from kalasetu_api.config import get_settings
from kalasetu_api.main import app

client = TestClient(app)


def _auth(uid: str) -> dict[str, str]:
    return {"Authorization": f"Bearer dev.{uid}"}


def _draft(uid: str, extra: dict | None = None) -> str:
    payload = {
        "title_en": "Test listing",
        "cluster": "varanasi",
        "fields": {
            "craft": "saree",
            "material": "silk",
            "hours": 10,
            "material_cost_inr": 900,
            "effort": "skilled",
            "gi": "yes",
            "colour": ["red"],
        },
    }
    if extra:
        payload.update(extra)
    resp = client.post("/v1/listings", headers=_auth(uid), json=payload)
    assert resp.status_code == 200
    return resp.json()["id"]


def _publish(uid: str, listing_id: str) -> dict:
    client.post(f"/v1/listings/{listing_id}/price", headers=_auth(uid))
    resp = client.post(f"/v1/listings/{listing_id}/sign", headers=_auth(uid))
    assert resp.status_code == 200
    return resp.json()


def test_money_empty_state_and_trade_record():
    uid = "money-empty-1"
    resp = client.get("/v1/money", headers=_auth(uid))
    assert resp.status_code == 200
    body = resp.json()
    assert body["empty"] is True
    assert "No sales yet" in body["spoken"]
    assert body["trade_record"]["label"] == "Trade Record"
    assert "credit" not in body["trade_record"]["label"].lower()


def test_sale_updates_money_and_trade_record():
    uid = "money-seller-2"
    listing_id = _draft(uid)
    _publish(uid, listing_id)
    sale = client.post(
        "/v1/sales",
        headers=_auth(uid),
        json={"listing_id": listing_id, "amount": 2500},
    )
    assert sale.status_code == 200
    assert sale.json()["sale"]["amount"] == 2500

    money = client.get("/v1/money", headers=_auth(uid)).json()
    assert money["empty"] is False
    assert money["total_inr"] == 2500
    assert money["trade_record"]["counts"]["sales"] >= 1

    sales = client.get("/v1/sales", headers=_auth(uid)).json()
    assert sales["count"] == 1


def test_advisor_first_publish_then_empty_after_persist():
    uid = "advisor-first-3"
    listing_id = _draft(uid)
    _publish(uid, listing_id)
    first = client.get("/v1/advisor", headers=_auth(uid))
    assert first.status_code == 200
    body = first.json()
    assert body["empty"] is False
    assert body["rule_id"] == "first_publish"
    assert body["sentence"]
    assert body["provenance"]["source"].startswith("advisor-rules.v1")

    second = client.get("/v1/advisor", headers=_auth(uid)).json()
    assert second["rule_id"] != "first_publish"


def test_advisor_stale_draft():
    uid = "advisor-stale-4"
    listing_id = _draft(uid)
    stale = (datetime.now(timezone.utc) - timedelta(hours=30)).isoformat()
    _MEM_LISTINGS[(uid, listing_id)]["updatedAt"] = stale
    _MEM_LISTINGS[(uid, listing_id)]["createdAt"] = stale
    body = client.get("/v1/advisor", headers=_auth(uid)).json()
    assert body["empty"] is False
    assert body["rule_id"] == "stale_draft"


def test_advisor_underpricing_after_three_sales():
    uid = "advisor-price-5"
    listing_id = _draft(uid)
    signed = _publish(uid, listing_id)
    client.get("/v1/advisor", headers=_auth(uid))
    rec = client.get(f"/v1/listings/{listing_id}", headers=_auth(uid)).json()["prices"]["recommended"]["value"]
    low = float(rec) * 0.5
    for _ in range(3):
        resp = client.post("/v1/sales", headers=_auth(uid), json={"listing_id": listing_id, "amount": low})
        assert resp.status_code == 200
    body = client.get("/v1/advisor", headers=_auth(uid)).json()
    assert body["rule_id"] == "underpricing"
    assert signed["status"] == "published"


def test_trends_recompute_and_current():
    headers = {}
    admin = get_settings().admin_api_token
    if admin:
        headers["X-Admin-Token"] = admin
    resp = client.post("/v1/trends/recompute", headers=headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["ok"] is True
    assert "n" in body
    assert "rising" in body
    assert body["provenance"]["source"] == "trend-agg.v1"
    current = client.get("/v1/trends/current")
    assert current.status_code == 200
    assert current.json()["n"] == body["n"]


def test_export_gem_ondc_ih_are_mocked():
    uid = "export-artisan-6"
    listing_id = _draft(uid)
    _publish(uid, listing_id)
    for channel in ("gem", "ondc", "ih"):
        resp = client.get(
            f"/v1/listings/{listing_id}/export",
            headers=_auth(uid),
            params={"channel": channel},
        )
        assert resp.status_code == 200
        body = resp.json()
        assert body["label"] == "Mock — for SIH demo"
        assert body["live_write"] is False
        assert body["channel"] == channel
        assert body["record"]


def test_audio_media_upload_and_fetch():
    uid = "audio-artisan-7"
    listing_id = _draft(uid)
    resp = client.post(
        f"/v1/listings/{listing_id}/media",
        headers=_auth(uid),
        files={"file": ("clip.opus", b"fake-opus-bytes", "audio/opus")},
        data={"kind": "audio"},
    )
    assert resp.status_code == 200
    url = resp.json()["url"]
    assert "audio.opus" in url
    fetched = client.get(f"/v1/listings/{listing_id}/media/audio.opus")
    assert fetched.status_code == 200
    assert fetched.content == b"fake-opus-bytes"


def test_auth_verify_reports_auth_mode():
    resp = client.post("/v1/auth/verify", json={"phone": "9000011122", "code": "123456"})
    assert resp.status_code == 200
    body = resp.json()
    assert body["auth_mode"] in ("firebase", "dev")
    assert "firebase_ready" in body
    assert body["token"].startswith("dev.")


def test_insights_includes_trends_and_history_shape():
    uid = "insights-artisan-8"
    listing_id = _draft(uid)
    _publish(uid, listing_id)
    client.get("/v1/advisor", headers=_auth(uid))
    resp = client.get("/v1/insights", headers=_auth(uid))
    assert resp.status_code == 200
    body = resp.json()
    assert "advisor" in body
    assert "history" in body
    assert "trends" in body
