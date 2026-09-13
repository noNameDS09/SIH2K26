from io import BytesIO

from fastapi.testclient import TestClient
from PIL import Image

from kalasetu_api.engines import studio
from kalasetu_api.main import app

client = TestClient(app)
AUTH = {"Authorization": "Bearer demo"}


def _jpeg(color: tuple[int, int, int] = (180, 24, 24), size: tuple[int, int] = (64, 64)) -> bytes:
    image = Image.new("RGB", size, color)
    buf = BytesIO()
    image.save(buf, format="JPEG")
    return buf.getvalue()


def _opaque_cutout(image: Image.Image) -> Image.Image:
    return image.convert("RGBA")


def test_enhance_rejects_bad_preset():
    response = client.post(
        "/v1/images/enhance",
        files={"file": ("x.jpg", _jpeg(), "image/jpeg")},
        data={"listing_id": "draft-1", "bg_preset": "marble"},
        headers=AUTH,
    )
    assert response.status_code == 400


def test_enhance_rejects_empty_file():
    response = client.post(
        "/v1/images/enhance",
        files={"file": ("x.jpg", b"", "image/jpeg")},
        data={"listing_id": "draft-1", "bg_preset": "linen"},
        headers=AUTH,
    )
    assert response.status_code == 400


def test_enhance_returns_urls_and_provenance(monkeypatch):
    monkeypatch.setattr(studio, "cutout_isnet", _opaque_cutout)
    listing_id = "draft-saree-studio"
    response = client.post(
        "/v1/images/enhance",
        files={"file": ("saree.jpg", _jpeg(), "image/jpeg")},
        data={"listing_id": listing_id, "bg_preset": "linen"},
        headers=AUTH,
    )
    assert response.status_code == 200
    body = response.json()
    assert body["listing_id"] == listing_id
    assert body["bg_preset"] == "linen"
    assert body["provenance"]["source"] == "kalasetu-studio.v1"
    assert "deltaE" in body
    original = client.get(f"/v1/listings/{listing_id}/media/original.jpg")
    studio_jpg = client.get(f"/v1/listings/{listing_id}/media/studio.jpg")
    assert original.status_code == 200
    assert studio_jpg.status_code == 200
    assert original.headers["content-type"].startswith("image/jpeg")
    assert studio_jpg.headers["content-type"].startswith("image/jpeg")


def test_enhance_uses_slate_for_metal_craft(monkeypatch):
    monkeypatch.setattr(studio, "cutout_isnet", _opaque_cutout)
    response = client.post(
        "/v1/images/enhance",
        files={"file": ("diya.jpg", _jpeg((90, 90, 95)), "image/jpeg")},
        data={"listing_id": "draft-brass-studio", "bg_preset": "auto", "craft": "brass diya"},
        headers=AUTH,
    )
    assert response.status_code == 200
    assert response.json()["bg_preset"] == "slate"
