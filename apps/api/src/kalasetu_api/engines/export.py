"""Mocked GeM / ONDC / India Handloom export records.

Never claims a live write. Every payload is labelled Mock — for SIH demo.
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

CHANNELS = {
    "gem": {
        "name": "Government e-Marketplace",
        "schema": "gem-listing.v0-mock",
    },
    "ondc": {
        "name": "ONDC",
        "schema": "ondc-on_search.v0-mock",
    },
    "ih": {
        "name": "India Handloom / India Handmade",
        "schema": "india-handloom.v0-mock",
    },
}


def export_listing(listing: dict[str, Any], channel: str) -> dict[str, Any]:
    key = (channel or "gem").strip().lower()
    if key in ("indiahandloom", "indiahandmade", "handloom"):
        key = "ih"
    if key not in CHANNELS:
        raise ValueError(f"Unknown export channel '{channel}'. Use gem, ondc, or ih.")

    meta = CHANNELS[key]
    fields = listing.get("fields") or {}
    prices = listing.get("prices") or {}
    listed = (
        (prices.get("listed") or {}).get("value")
        or listing.get("listed_price")
        or listing.get("price_hint")
    )
    now_iso = datetime.now(timezone.utc).isoformat()
    public = {
        "id": listing.get("id"),
        "title": listing.get("title") or listing.get("title_en") or listing.get("title_hi"),
        "title_hi": listing.get("title_hi"),
        "title_en": listing.get("title_en"),
        "description": listing.get("description") or listing.get("desc_en"),
        "cluster": listing.get("cluster"),
        "craft": listing.get("craft") or fields.get("craft"),
        "material": fields.get("material"),
        "gi": fields.get("gi"),
        "listed_price_inr": listed,
        "photo_url": listing.get("studioUrl") or listing.get("photo_url") or listing.get("image_url"),
        "signature": listing.get("signature"),
        "qr_url": listing.get("qr_url") or listing.get("qrUrl"),
    }
    if key == "gem":
        record = {
            "gemCategory": public["craft"],
            "itemName": public["title"],
            "itemDescription": public["description"],
            "uom": "Number",
            "priceInr": listed,
            "sourceCluster": public["cluster"],
            "originGi": public["gi"],
        }
    elif key == "ondc":
        record = {
            "descriptor": {"name": public["title"], "short_desc": public["description"]},
            "price": {"currency": "INR", "value": str(listed or "")},
            "location_id": public["cluster"],
            "category_id": public["craft"],
        }
    else:
        record = {
            "productName": public["title"],
            "craft": public["craft"],
            "cluster": public["cluster"],
            "giTag": public["gi"],
            "priceInr": listed,
            "image": public["photo_url"],
        }

    return {
        "ok": True,
        "channel": key,
        "channel_name": meta["name"],
        "schema": meta["schema"],
        "label": "Mock — for SIH demo",
        "live_write": False,
        "listing_id": listing.get("id"),
        "exported_at": now_iso,
        "record": record,
        "public": public,
        "provenance": {
            "source": f"export-{key}.v1-mock",
            "version": "1",
            "confidence": 1.0,
            "ts": now_iso,
        },
    }
