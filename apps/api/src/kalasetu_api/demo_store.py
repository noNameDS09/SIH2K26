from __future__ import annotations

from kalasetu_api.engines.pricing import compute_prices, price_provenance

DEMO_LISTINGS = {
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
        "status": "published",
        "source_label": "Mock — for SIH demo",
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
        "status": "published",
        "source_label": "Mock — for SIH demo",
    },
}


# Re-export so existing imports keep working.
__all__ = [
    "DEMO_LISTINGS",
    "build_price_for",
    "get_listing",
    "list_market_catalog",
    "price_provenance",
]


def list_market_catalog() -> list[dict]:
    return [
        {
            "id": item["id"],
            "title": item["title"],
            "title_hi": item["title_hi"],
            "description": item["description"],
            "image_url": item["photo_url"],
            "listed_price": item["price_hint"],
            "cluster": item["cluster"],
            "source_label": item["source_label"],
        }
        for item in DEMO_LISTINGS.values()
    ]


def get_listing(listing_id: str) -> dict | None:
    return DEMO_LISTINGS.get(listing_id)


def build_price_for(listing: dict) -> dict:
    return compute_prices(
        listing["fields"],
        cluster=listing.get("cluster"),
        listed=listing.get("price_hint"),
    )
