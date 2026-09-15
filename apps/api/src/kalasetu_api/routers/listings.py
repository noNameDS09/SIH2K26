from __future__ import annotations

import uuid
from datetime import datetime, timezone
from typing import Any

from fastapi import APIRouter, Depends, File, Form, Header, HTTPException, UploadFile, status
from fastapi.responses import Response
from pydantic import BaseModel, Field

from kalasetu_api.adapters.firebase import (
    bootstrap_firestore_catalog,
    get_listing,
    list_artisan_listings,
    list_published_market_items,
    publish_listing_doc,
    record_event,
    save_listing,
)
from kalasetu_api.demo_store import build_price_for
from kalasetu_api.deps import current_uid
from kalasetu_api.engines.pricing import compute_prices
from kalasetu_api.engines.signing import sign_listing_payload
from kalasetu_api.listing_media import listing_image_url, media_bytes, media_jpeg, put_audio_media

router = APIRouter(tags=["listings"])


class ListingPayload(BaseModel):
    id: str | None = None
    title: str | None = None
    title_hi: str | None = None
    title_en: str | None = None
    description: str | None = None
    desc_hi: str | None = None
    desc_en: str | None = None
    fields: dict[str, Any] = Field(default_factory=dict)
    cluster: str | None = None
    price_hint: float | None = None
    photo_url: str | None = None


class ListingPatchPayload(BaseModel):
    title: str | None = None
    title_hi: str | None = None
    title_en: str | None = None
    description: str | None = None
    desc_hi: str | None = None
    desc_en: str | None = None
    fields: dict[str, Any] | None = None
    cluster: str | None = None
    price_hint: float | None = None
    photo_url: str | None = None


@router.get("/v1/market")
async def market_catalog(
    category: str | None = None,
    craft: str | None = None,
    cluster: str | None = None,
    gi: str | None = None,
    tag: str | None = None,
    q: str | None = None,
    search: str | None = None,
    min_price: float | None = None,
    max_price: float | None = None,
    sort: str | None = None,
) -> dict:
    """Published marketplace items with filtering, search, and category facets."""
    all_items = list_published_market_items()

    # Collect facets from complete catalog
    categories = sorted({str(it.get("category")) for it in all_items if it.get("category")})
    clusters = sorted({str(it.get("cluster")) for it in all_items if it.get("cluster")})
    crafts = sorted({str(it.get("craft")) for it in all_items if it.get("craft")})

    all_tags: set[str] = set()
    for it in all_items:
        for t in it.get("tags", []):
            if t:
                all_tags.add(str(t))

    query = (q or search or "").strip().lower()
    cat_filter = (category or "").strip().lower()
    craft_filter = (craft or "").strip().lower()
    cluster_filter = (cluster or "").strip().lower()
    gi_filter = (gi or "").strip().lower()
    tag_filter = (tag or "").strip().lower()

    filtered: list[dict[str, Any]] = []
    for item in all_items:
        # 1. Category filter
        if cat_filter and cat_filter not in str(item.get("category", "")).lower():
            continue

        # 2. Craft filter
        if craft_filter and craft_filter != str(item.get("craft", "")).lower():
            continue

        # 3. Cluster filter
        if cluster_filter and cluster_filter not in str(item.get("cluster", "")).lower():
            continue

        # 4. GI filter
        if gi_filter:
            item_gi = str(item.get("fields", {}).get("gi") or item.get("gi") or "no").lower()
            if gi_filter in ("yes", "true", "1") and item_gi != "yes":
                continue
            if gi_filter in ("no", "false", "0") and item_gi == "yes":
                continue

        # 5. Tag filter
        if tag_filter:
            item_tags = [str(t).lower() for t in item.get("tags", [])]
            if tag_filter not in item_tags:
                continue

        # 6. Price range
        item_price = float(
            item.get("listed_price")
            or item.get("price_hint")
            or (item.get("prices", {}).get("listed", {}).get("value") if isinstance(item.get("prices"), dict) else 0)
            or 0
        )
        if min_price is not None and item_price < min_price:
            continue
        if max_price is not None and item_price > max_price:
            continue

        # 7. Search query across title, descriptions, tags, artisan, craft, cluster
        if query:
            searchable = " ".join([
                str(item.get("title", "")),
                str(item.get("title_en", "")),
                str(item.get("title_hi", "")),
                str(item.get("description", "")),
                str(item.get("desc_en", "")),
                str(item.get("desc_hi", "")),
                str(item.get("craft", "")),
                str(item.get("cluster", "")),
                str(item.get("cluster_name", "")),
                str(item.get("category", "")),
                str(item.get("artisan", {}).get("name", "") if isinstance(item.get("artisan"), dict) else ""),
                " ".join([str(t) for t in item.get("tags", [])]),
            ]).lower()
            if query not in searchable:
                continue

        filtered.append(item)

    # Sorting
    if sort == "price_asc":
        filtered.sort(key=lambda x: float(x.get("listed_price") or x.get("price_hint") or 0))
    elif sort == "price_desc":
        filtered.sort(key=lambda x: float(x.get("listed_price") or x.get("price_hint") or 0), reverse=True)
    elif sort == "latest":
        filtered.sort(key=lambda x: str(x.get("updatedAt", "")), reverse=True)

    return {
        "items": filtered,
        "total": len(filtered),
        "categories": categories,
        "clusters": clusters,
        "crafts": crafts,
        "tags": sorted(all_tags),
    }


@router.post("/v1/market/seed")
async def seed_market_catalog() -> dict:
    """Bootstrap the 30 handcrafted catalog products into Firestore."""
    result = bootstrap_firestore_catalog()
    return {"ok": True, **result}


@router.get("/v1/listings")
async def my_listings(uid: str = Depends(current_uid)) -> dict:
    """Listings for the authenticated artisan."""
    items = list_artisan_listings(uid)
    return {"items": items}


@router.post("/v1/listings")
async def create_listing(
    payload: ListingPayload,
    uid: str = Depends(current_uid),
) -> dict:
    """Create or draft a new listing for the authenticated artisan."""
    listing_id = payload.id.strip() if payload.id else f"list-{uuid.uuid4().hex[:8]}"
    data = payload.model_dump(exclude_unset=True)
    if "id" in data:
        data.pop("id")

    saved = save_listing(uid=uid, listing_id=listing_id, data=data)
    record_event(
        uid=uid,
        listing_id=listing_id,
        kind="listing.drafted",
        payload={"cluster": saved.get("cluster")},
    )
    return saved


@router.get("/v1/listings/{listing_id}")
async def get_listing_detail(
    listing_id: str,
    authorization: str | None = Header(default=None),
) -> dict:
    """Get full listing document. If author token provided, checks artisan store first."""
    uid = None
    if authorization and authorization.lower().startswith("bearer "):
        token = authorization.split(" ", 1)[1].strip()
        if token.startswith("dev."):
            uid = token.split("dev.", 1)[1]
        elif token:
            uid = token

    listing = get_listing(listing_id, uid=uid)
    if listing is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Listing not found")
    return listing


@router.patch("/v1/listings/{listing_id}")
async def patch_listing(
    listing_id: str,
    payload: ListingPatchPayload,
    uid: str = Depends(current_uid),
) -> dict:
    """Update fields or metadata on an artisan's draft listing."""
    listing = get_listing(listing_id, uid=uid)
    if listing is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Listing not found")

    updates = payload.model_dump(exclude_unset=True)
    if not updates:
        return listing

    saved = save_listing(uid=uid, listing_id=listing_id, data=updates)
    record_event(
        uid=uid,
        listing_id=listing_id,
        kind="listing.confirmed",
        payload={"updatedKeys": list(updates.keys())},
    )
    return saved


@router.post("/v1/listings/{listing_id}/price")
async def price_listing(
    listing_id: str,
    uid: str = Depends(current_uid),
) -> dict:
    """Compute 4-tier price bands (floor, recommended, aspirational, listed) and persist."""
    listing = get_listing(listing_id, uid=uid)
    if listing is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Listing not found")

    fields = listing.get("fields") or {}
    cluster = listing.get("cluster") or "varanasi"
    listed = listing.get("price_hint") or listing.get("listed_price")
    prices = compute_prices(fields, cluster=cluster, listed=listed)

    save_listing(uid=uid, listing_id=listing_id, data={"prices": prices})
    record_event(
        uid=uid,
        listing_id=listing_id,
        kind="price.computed",
        payload={"floor": prices["floor"]["value"], "rec": prices["recommended"]["value"]},
    )

    return {
        "listing_id": listing_id,
        "prices": prices,
        "source_label": listing.get("source_label", "KalaSetu Verified"),
    }


@router.post("/v1/listings/{listing_id}/sign")
async def sign_listing(
    listing_id: str,
    uid: str = Depends(current_uid),
) -> dict:
    """Cryptographically freeze listing with HMAC, generate QR code PNG, and publish."""
    listing = get_listing(listing_id, uid=uid)
    if listing is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Listing not found")

    # If prices not yet calculated, calculate and persist them first
    if not listing.get("prices"):
        fields = listing.get("fields") or {}
        cluster = listing.get("cluster") or "varanasi"
        listed = listing.get("price_hint") or listing.get("listed_price")
        listing["prices"] = compute_prices(fields, cluster=cluster, listed=listed)
        save_listing(uid=uid, listing_id=listing_id, data={"prices": listing["prices"]})

    # Generate HMAC and QR code PNG
    signing_meta = sign_listing_payload(listing, uid=uid)

    # Publish to publishedListings collection and artisan record
    publish_listing_doc(uid=uid, listing_id=listing_id, signing_meta=signing_meta)
    try:
        from kalasetu_api.engines.trends import recompute_public_trends

        recompute_public_trends()
    except Exception:
        pass

    return {
        "listing_id": listing_id,
        "status": "published",
        "signature": signing_meta["signature"],
        "qr_url": signing_meta["qr_url"],
        "public_url": signing_meta["public_url"],
        "signed_at": signing_meta["signed_at"],
        "source_label": signing_meta["source_label"],
    }


@router.get("/v/{listing_id}")
async def public_listing(listing_id: str) -> dict:
    """Public listing card, target of the QR code."""
    listing = get_listing(listing_id)
    if listing is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Listing not found")

    photo = listing_image_url(
        listing_id,
        listing.get("studioUrl")
        or listing.get("originalUrl")
        or listing.get("photo_url")
        or "",
    )
    prices = listing.get("prices") or build_price_for(listing)
    listed_price = (
        prices.get("listed", {}).get("value")
        or prices.get("recommended", {}).get("value")
        or listing.get("price_hint")
    )

    return {
        "id": listing["id"],
        "title": listing.get("title") or listing.get("title_en") or listing.get("title_hi") or "",
        "title_hi": listing.get("title_hi", ""),
        "title_en": listing.get("title_en", ""),
        "description": listing.get("description") or listing.get("desc_en") or listing.get("desc_hi") or "",
        "desc_en": listing.get("desc_en") or listing.get("description") or "",
        "desc_hi": listing.get("desc_hi") or listing.get("description_hi") or "",
        "category": listing.get("category", "Handicrafts"),
        "craft": listing.get("craft") or listing.get("fields", {}).get("craft", "handloom"),
        "cluster": listing.get("cluster", "varanasi"),
        "cluster_name": listing.get("cluster_name") or listing.get("cluster", "").title(),
        "artisan": listing.get("artisan"),
        "image_url": photo,
        "photo_url": photo,
        "status": listing.get("status", "draft"),
        "prices": prices,
        "listed_price": listed_price,
        "fields": listing.get("fields", {}),
        "tags": listing.get("tags", []),
        "gi": listing.get("fields", {}).get("gi", "no"),
        "qr_url": listing.get("qr_url") or listing.get("qrUrl"),
        "signature": listing.get("signature"),
        "signed_at": listing.get("signed_at") or listing.get("signedAt"),
        "source_label": listing.get("source_label", "KalaSetu Verified"),
    }


@router.get("/v1/listings/{listing_id}/media/{filename}")
async def listing_media_file(listing_id: str, filename: str) -> Response:
    """Serve studio.jpg, original.jpg, or qr.png media for a listing."""
    res = media_bytes(listing_id, filename)
    if res is None:
        raise HTTPException(
            status_code=404,
            detail=f"Media {filename} not found for listing {listing_id}",
        )
    data, media_type = res
    return Response(content=data, media_type=media_type)


@router.get("/v1/listings/{listing_id}/media/{kind}.jpg")
async def listing_media(listing_id: str, kind: str) -> Response:
    """Backward-compatible endpoint for original.jpg and studio.jpg."""
    if kind not in ("original", "studio"):
        raise HTTPException(status_code=404, detail="Unknown media")
    jpeg = media_jpeg(listing_id, kind)
    if jpeg is None:
        raise HTTPException(status_code=404, detail="No media for this listing")
    return Response(content=jpeg, media_type="image/jpeg")


@router.post("/v1/listings/{listing_id}/media")
async def upload_listing_media(
    listing_id: str,
    file: UploadFile = File(...),
    kind: str = Form("audio"),
    uid: str = Depends(current_uid),
) -> dict:
    listing = get_listing(listing_id, uid=uid)
    if listing is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Listing not found")
    data = await file.read()
    if not data:
        raise HTTPException(status_code=400, detail="Empty file")
    name = (kind or "audio").strip().lower()
    filename = file.filename or "audio.opus"
    if name in ("audio", "audio.opus"):
        url = put_audio_media(
            listing_id,
            data,
            uid=uid,
            filename="audio.opus",
            content_type=file.content_type or "audio/opus",
        )
        save_listing(uid=uid, listing_id=listing_id, data={"audioUrl": url})
        record_event(uid=uid, listing_id=listing_id, kind="media.captured", payload={"kind": "audio"})
        return {"ok": True, "kind": "audio", "url": url, "filename": "audio.opus"}
    raise HTTPException(status_code=400, detail="Only kind=audio is accepted here; photos go through /v1/images/enhance")


@router.post("/v1/listings/{listing_id}/translate")
async def translate_listing(
    listing_id: str,
    target_lang: str = "hi-IN",
) -> dict:
    """Translate listing title and description on-demand and cache in listing document."""
    listing = get_listing(listing_id)
    if listing is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Listing not found")

    target_code = target_lang.strip()
    translations = listing.get("translations") or {}
    if not isinstance(translations, dict):
        translations = {}

    if target_code in translations:
        return {
            "listing_id": listing_id,
            "target_lang": target_code,
            "title": translations[target_code].get("title", ""),
            "description": translations[target_code].get("description", ""),
            "cached": True,
        }

    from kalasetu_api.adapters.llm.gemini import translate_text

    base_title = listing.get("title_en") or listing.get("title") or listing.get("title_hi") or ""
    base_desc = listing.get("desc_en") or listing.get("description") or listing.get("desc_hi") or ""

    translated_title = translate_text(text=base_title, target_language=target_code, source_language="en")
    translated_desc = translate_text(text=base_desc, target_language=target_code, source_language="en")

    translations[target_code] = {
        "title": translated_title,
        "description": translated_desc,
        "translated_at": datetime.now(timezone.utc).isoformat(),
    }

    # Persist translation cache in Firestore & in-memory
    save_listing(uid=listing.get("artisanId") or "demo", listing_id=listing_id, data={"translations": translations})

    return {
        "listing_id": listing_id,
        "target_lang": target_code,
        "title": translated_title,
        "description": translated_desc,
        "cached": False,
    }

