from fastapi import APIRouter, Depends, Header, HTTPException, status

from kalasetu_api.config import get_settings
from kalasetu_api.demo_store import build_price_for, get_listing, list_market_catalog
from kalasetu_api.deps import require_bearer

router = APIRouter(tags=["listings"])


@router.get("/v1/market")
async def market_catalog() -> dict:
    return {"items": list_market_catalog()}


@router.post("/v1/listings/{listing_id}/price")
async def price_listing(listing_id: str, _: str = Depends(require_bearer)) -> dict:
    listing = get_listing(listing_id)
    if listing is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Listing not found")
    return {
        "listing_id": listing_id,
        "prices": build_price_for(listing),
        "source_label": listing["source_label"],
    }


@router.post("/v1/listings/{listing_id}/sign")
async def sign_listing(listing_id: str, _: str = Depends(require_bearer)) -> dict:
    listing = get_listing(listing_id)
    if listing is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Listing not found")
    return {
        "listing_id": listing_id,
        "status": "published",
        "signature": "demo-hmac-sha256",
        "qr_url": f"https://example.test/v/{listing_id}",
        "source_label": listing["source_label"],
    }


@router.get("/v/{listing_id}")
async def public_listing(listing_id: str) -> dict:
    listing = get_listing(listing_id)
    if listing is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Listing not found")
    return {
        "id": listing["id"],
        "title": listing["title"],
        "title_hi": listing["title_hi"],
        "description": listing["description"],
        "description_hi": listing["description_hi"],
        "image_url": listing["photo_url"],
        "cluster": listing["cluster"],
        "status": listing["status"],
        "prices": build_price_for(listing),
        "source_label": listing["source_label"],
    }


@router.post("/v1/trends/recompute")
async def recompute_trends(x_admin_token: str | None = Header(default=None)) -> dict:
    settings = get_settings()
    if not settings.admin_api_token or x_admin_token != settings.admin_api_token:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Admin token required")
    return {
        "ok": True,
        "n": 2,
        "seed": True,
        "window": "current",
        "source": "trend-agg.v1",
    }
