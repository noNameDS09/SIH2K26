from fastapi.testclient import TestClient

from kalasetu_api.main import app

client = TestClient(app)


def test_market_catalog_returns_demo_items():
    response = client.get("/v1/market")
    assert response.status_code == 200
    body = response.json()
    assert "items" in body
    assert len(body["items"]) >= 1
    first = body["items"][0]
    assert first["id"]
    assert first["title"]
    assert first["source_label"] == "Mock — for SIH demo"


def test_public_card_returns_listing_with_prices():
    response = client.get("/v/demo-saree")
    assert response.status_code == 200
    body = response.json()
    assert body["id"] == "demo-saree"
    assert body["status"] == "published"
    assert body["prices"]["recommended"]["value"] > 0
    assert body["prices"]["recommended"]["provenance"]["source"] == "kalasetu-pricing.v1"


def test_price_route_requires_bearer_and_returns_provenance():
    response = client.post(
        "/v1/listings/demo-saree/price",
        headers={"Authorization": "Bearer demo-token"},
    )
    assert response.status_code == 200
    payload = response.json()
    assert payload["listing_id"] == "demo-saree"
    assert payload["prices"]["floor"]["provenance"]["confidence"] >= 0.9
