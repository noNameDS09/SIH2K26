from __future__ import annotations

from typing import Any

from kalasetu_api.catalog_seed import get_all_30_catalog_items
from kalasetu_api.engines.pricing import compute_prices, price_provenance

DEMO_LISTINGS: dict[str, dict[str, Any]] = {
    "demo-saree": {
        "id": "demo-saree",
        "title": "Handloom saree",
        "title_hi": "हाथकरघा साड़ी",
        "description": "Natural handloom silk saree with zari border and soft drape.",
        "description_hi": "प्राकृतिक हाथकरघा रेशम की साड़ी, जरी किनारा और नरम ड्रेप।",
        "photo_url": "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=900&q=80",
        "price_hint": 4200,
        "fields": {
            "craft": "handloom",
            "material": "silk",
            "technique": "weave",
            "colour": ["red", "gold"],
            "occasion": "festival",
            "gi": "yes",
            "hours": 18,
            "material_cost_inr": 1800,
            "material_source": "trader",
            "effort": "skilled",
        },
        "cluster": "Bengal",
        "category": "Handloom & Textiles",
        "status": "published",
        "source_label": "Mock — for SIH demo",
        "tags": ["handloom", "silk", "saree", "bengal", "gi-tag"],
    },
    "demo-brass": {
        "id": "demo-brass",
        "title": "Brass diya set",
        "title_hi": "कांस्य दिया सेट",
        "description": "Handcrafted brass diya set for festive gifting and ritual use.",
        "description_hi": "पारंपरिक कारीगरी वाला कांस्य दियाセット, पूजा और उपहार के लिए।",
        "photo_url": "https://images.unsplash.com/photo-1512436991641-6745cdb1723f?auto=format&fit=crop&w=900&q=80",
        "price_hint": 2100,
        "fields": {
            "craft": "metalcraft",
            "material": "brass",
            "technique": "casting",
            "colour": ["gold", "bronze"],
            "occasion": "festival",
            "gi": "no",
            "hours": 12,
            "material_cost_inr": 900,
            "material_source": "shop",
            "effort": "normal",
        },
        "cluster": "Jaipur",
        "category": "Metal Craft & Dhokra",
        "status": "published",
        "source_label": "Mock — for SIH demo",
        "tags": ["metalcraft", "brass", "diya", "jaipur"],
    },
}

# Merge all 30 catalog items into DEMO_LISTINGS
for _prod in get_all_30_catalog_items():
    DEMO_LISTINGS[_prod["id"]] = _prod

# Re-export so existing imports keep working.
__all__ = [
    "DEMO_LISTINGS",
    "build_price_for",
    "get_listing",
    "list_market_catalog",
    "price_provenance",
]


def list_market_catalog() -> list[dict[str, Any]]:
    items: list[dict[str, Any]] = []
    for item in DEMO_LISTINGS.values():
        prices = item.get("prices") or build_price_for(item)
        items.append(
            {
                "id": item["id"],
                "title": item["title"],
                "title_en": item.get("title_en", item["title"]),
                "title_hi": item.get("title_hi", ""),
                "description": item["description"],
                "desc_en": item.get("desc_en", item["description"]),
                "desc_hi": item.get("desc_hi", ""),
                "image_url": item.get("photo_url") or item.get("image_url"),
                "photo_url": item.get("photo_url") or item.get("image_url"),
                "category": item.get("category", "Handicrafts"),
                "craft": item.get("craft", "handloom"),
                "cluster": item.get("cluster", "varanasi"),
                "cluster_name": item.get("cluster_name", item.get("cluster", "").title()),
                "artisan": item.get("artisan"),
                "listed_price": item.get("listed_price") or item.get("price_hint"),
                "price_hint": item.get("listed_price") or item.get("price_hint"),
                "prices": prices,
                "tags": item.get("tags", []),
                "gi": item.get("fields", {}).get("gi", "no"),
                "signature": item.get("signature"),
                "qr_url": item.get("qr_url"),
                "signedAt": item.get("signedAt"),
                "source_label": item.get("source_label", "KalaSetu Verified"),
                "status": item.get("status", "published"),
                "fields": item.get("fields", {}),
            }
        )
    return items


def get_listing(listing_id: str) -> dict | None:
    return DEMO_LISTINGS.get(listing_id)


def build_price_for(listing: dict) -> dict:
    if "prices" in listing and listing["prices"]:
        return listing["prices"]
    return compute_prices(
        listing.get("fields", {}),
        cluster=listing.get("cluster"),
        listed=listing.get("price_hint"),
    )
