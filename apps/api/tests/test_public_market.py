from fastapi.testclient import TestClient

from kalasetu_api.main import app

client = TestClient(app)


def test_market_catalog_returns_demo_items():
    response = client.get("/v1/market")
    assert response.status_code == 200
    body = response.json()
    assert "items" in body
    assert len(body["items"]) >= 30
    demo = next((it for it in body["items"] if it["id"] == "demo-saree"), None)
    assert demo is not None
    assert demo["title"]
    assert demo["source_label"] == "Mock — for SIH demo"


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


def test_market_catalog_30_products_across_6_categories():
    response = client.get("/v1/market")
    assert response.status_code == 200
    body = response.json()

    assert "items" in body
    assert "categories" in body
    assert "clusters" in body
    assert "tags" in body
    assert body["total"] >= 30

    expected_categories = [
        "Handloom & Textiles",
        "Metal Craft & Dhokra",
        "Pottery & Ceramics",
        "Woodcraft & Lacquerware",
        "Leather & Footwear",
        "Stone Craft & Jewelry",
    ]

    for cat in expected_categories:
        assert cat in body["categories"]
        cat_items = [it for it in body["items"] if it.get("category") == cat]
        assert len(cat_items) >= 5, f"Category {cat} should have at least 5 products, got {len(cat_items)}"


def test_market_filtering_by_category_and_craft():
    # Filter by category
    resp_cat = client.get("/v1/market?category=Pottery")
    assert resp_cat.status_code == 200
    pottery_items = resp_cat.json()["items"]
    assert len(pottery_items) >= 5
    for it in pottery_items:
        assert "Pottery" in it["category"]

    # Filter by craft
    resp_craft = client.get("/v1/market?craft=woodcraft")
    assert resp_craft.status_code == 200
    wood_items = resp_craft.json()["items"]
    assert len(wood_items) >= 5
    for it in wood_items:
        assert it["craft"] == "woodcraft"


def test_market_search_and_tag_filtering():
    # Search by keyword
    resp_search = client.get("/v1/market?q=pashmina")
    assert resp_search.status_code == 200
    results = resp_search.json()["items"]
    assert len(results) >= 1
    assert any("pashmina" in it["id"] for it in results)

    # Search in Hindi
    resp_hi = client.get("/v1/market?q=बनारसी")
    assert resp_hi.status_code == 200
    results_hi = resp_hi.json()["items"]
    assert len(results_hi) >= 1

    # Filter by tag
    resp_tag = client.get("/v1/market?tag=gi-tag")
    assert resp_tag.status_code == 200
    gi_items = resp_tag.json()["items"]
    assert len(gi_items) >= 20
    for it in gi_items:
        assert "gi-tag" in [t.lower() for t in it.get("tags", [])]


def test_public_card_complete_structured_product_info():
    # Test specific product card
    sample_id = "banarasi-katan-silk-saree"
    response = client.get(f"/v/{sample_id}")
    assert response.status_code == 200
    data = response.json()

    assert data["id"] == sample_id
    assert "Katan" in data["title"]
    assert data["title_hi"]
    assert data["title_en"]
    assert data["description"]
    assert data["desc_hi"]
    assert data["desc_en"]
    assert data["category"] == "Handloom & Textiles"
    assert data["cluster"] == "varanasi"
    assert data["status"] == "published"
    assert data["source_label"] == "KalaSetu Verified"

    # Artisan information
    assert data["artisan"]
    assert data["artisan"]["name"] == "Ustad Bashir Ahmed"
    assert data["artisan"]["pehchan_id"]

    # Rich voice-cataloging fields
    fields = data["fields"]
    assert fields["material"]
    assert fields["technique"]
    assert fields["hours"] == 36
    assert fields["material_cost_inr"] > 0
    assert fields["gi"] == "yes"
    assert fields["motif"]
    assert fields["colour"]

    # 4-tier pricing model
    prices = data["prices"]
    assert "floor" in prices and "recommended" in prices and "aspirational" in prices and "listed" in prices
    assert prices["floor"]["value"] > 0
    assert prices["recommended"]["value"] >= prices["floor"]["value"]
    assert prices["aspirational"]["value"] >= prices["recommended"]["value"]
    assert prices["floor"]["provenance"]["source"] == "kalasetu-pricing.v1"

    # Cryptographic signature & QR link
    assert data["signature"]
    assert len(data["signature"]) == 64  # SHA256 hex
    assert f"/v1/listings/{sample_id}/media/qr.png" in data["qr_url"]


def test_market_seed_endpoint():
    resp = client.post("/v1/market/seed")
    assert resp.status_code == 200
    body = resp.json()
    assert body["ok"] is True
    assert body["listings"] >= 30
