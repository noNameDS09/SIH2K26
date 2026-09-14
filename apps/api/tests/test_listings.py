import io
from fastapi.testclient import TestClient
from PIL import Image

from kalasetu_api.main import app

client = TestClient(app)

AUTH_HEADER = {"Authorization": "Bearer dev.test-artisan-42"}


def test_listing_lifecycle_draft_price_sign_and_market():
    # 1. Create listing draft
    create_resp = client.post(
        "/v1/listings",
        headers=AUTH_HEADER,
        json={
            "title_hi": "हाथ से बनी रेशमी साड़ी",
            "title_en": "Handwoven Silk Saree",
            "cluster": "varanasi",
            "fields": {
                "craft": "saree",
                "material": "silk",
                "hours": 12,
                "material_cost_inr": 1500,
                "effort": "skilled",
                "gi": "yes",
            },
        },
    )
    assert create_resp.status_code == 200
    listing = create_resp.json()
    listing_id = listing["id"]
    assert listing_id.startswith("list-")
    assert listing["artisanId"] == "test-artisan-42"
    assert listing["status"] == "draft"

    # 2. Artisan's my-listings list
    my_resp = client.get("/v1/listings", headers=AUTH_HEADER)
    assert my_resp.status_code == 200
    items = my_resp.json()["items"]
    assert any(it["id"] == listing_id for it in items)

    # 3. Patch listing
    patch_resp = client.patch(
        f"/v1/listings/{listing_id}",
        headers=AUTH_HEADER,
        json={"desc_en": "Pure Varanasi Katan silk woven on traditional pit loom."},
    )
    assert patch_resp.status_code == 200
    assert patch_resp.json()["desc_en"] == "Pure Varanasi Katan silk woven on traditional pit loom."

    # 4. Compute and persist price
    price_resp = client.post(
        f"/v1/listings/{listing_id}/price",
        headers=AUTH_HEADER,
    )
    assert price_resp.status_code == 200
    prices = price_resp.json()["prices"]
    assert "floor" in prices and "recommended" in prices and "aspirational" in prices
    assert prices["floor"]["value"] > 0
    assert prices["floor"]["provenance"]["source"] == "kalasetu-pricing.v1"
    assert prices["floor"]["provenance"]["confidence"] >= 0.9

    # 5. Sign and freeze listing (HMAC + QR generation)
    sign_resp = client.post(
        f"/v1/listings/{listing_id}/sign",
        headers=AUTH_HEADER,
    )
    assert sign_resp.status_code == 200
    sign_data = sign_resp.json()
    assert sign_data["status"] == "published"
    assert len(sign_data["signature"]) == 64  # SHA256 hex string
    assert f"/v/{listing_id}" in sign_data["public_url"]
    assert "qr.png" in sign_data["qr_url"]
    assert sign_data["source_label"] == "KalaSetu Verified"

    # 6. Fetch QR media PNG
    qr_media_resp = client.get(f"/v1/listings/{listing_id}/media/qr.png")
    assert qr_media_resp.status_code == 200
    assert qr_media_resp.headers["content-type"] == "image/png"
    # Ensure it's a valid readable PNG image
    qr_img = Image.open(io.BytesIO(qr_media_resp.content))
    assert qr_img.format == "PNG"
    assert qr_img.size[0] > 50

    # 7. Check public card /v/{id}
    public_resp = client.get(f"/v/{listing_id}")
    assert public_resp.status_code == 200
    pub_data = public_resp.json()
    assert pub_data["id"] == listing_id
    assert pub_data["status"] == "published"
    assert pub_data["signature"] == sign_data["signature"]
    assert pub_data["qr_url"] == sign_data["qr_url"]
    assert pub_data["prices"]["floor"]["value"] == prices["floor"]["value"]

    # 8. Check that published listing appears on /v1/market
    market_resp = client.get("/v1/market")
    assert market_resp.status_code == 200
    market_items = market_resp.json()["items"]
    assert any(m["id"] == listing_id for m in market_items)


def test_sign_unauthorized_and_not_found():
    # Unauthorized sign
    unauth_resp = client.post("/v1/listings/non-existent/sign")
    assert unauth_resp.status_code == 401

    # Not found sign
    not_found_resp = client.post(
        "/v1/listings/non-existent-999/sign",
        headers=AUTH_HEADER,
    )
    assert not_found_resp.status_code == 404
