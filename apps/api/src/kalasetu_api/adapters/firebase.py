"""Firebase Admin and Firestore adapter for KalaSetu.

Connects to Firestore in asia-south1 (Mumbai) and Firebase Auth custom tokens.
Fallback to in-memory store when offline or credentials not configured.
"""

from __future__ import annotations

import logging
import os
import uuid
from datetime import datetime, timezone
from typing import Any

from kalasetu_api.catalog_seed import get_all_30_catalog_items
from kalasetu_api.config import Settings, get_settings
from kalasetu_api.demo_store import DEMO_LISTINGS, list_market_catalog

log = logging.getLogger("kalasetu.firebase")

_firebase_initialized = False
_firebase_app = None
_firestore_client = None

# In-memory fallbacks for offline testing / development
_MEM_PHONE_INDEX: dict[str, str] = {}
_MEM_ARTISANS: dict[str, dict[str, Any]] = {}
_MEM_LISTINGS: dict[tuple[str, str], dict[str, Any]] = {}
_MEM_LISTING_INDEX: dict[str, str] = {}
_MEM_PUBLISHED: dict[str, dict[str, Any]] = {}
_MEM_EVENTS: list[dict[str, Any]] = []
_MEM_SALES: dict[str, dict[str, Any]] = {}
_MEM_TRENDS: dict[str, dict[str, Any]] = {}


def normalize_phone(phone: str) -> str:
    cleaned = (phone or "").strip()
    has_plus = cleaned.startswith("+")
    digits = "".join(ch for ch in cleaned if ch.isdigit())
    if not digits:
        return "unknown"
    if len(digits) == 10 and not has_plus:
        return f"+91{digits}"
    return f"+{digits}" if has_plus else f"+{digits}"


def _seed_in_memory_catalog() -> None:
    for item in get_all_30_catalog_items():
        listing_id = item["id"]
        uid = item["artisanId"]
        _MEM_LISTINGS[(uid, listing_id)] = item
        _MEM_LISTING_INDEX[listing_id] = uid
        _MEM_PUBLISHED[listing_id] = item
        art = item.get("artisan")
        if art:
            norm_p = normalize_phone(art.get("phone", ""))
            _MEM_ARTISANS[uid] = {
                "uid": uid,
                "phone": norm_p,
                "name": art.get("name", ""),
                "lang": "hi-IN",
                "cluster": item.get("cluster", "varanasi"),
                "pehchan": {"id": art.get("pehchan_id")},
                "consentAt": item.get("signedAt"),
                "tradeRecord": {
                    "identity": 1,
                    "listings": 1,
                    "sales": 0,
                    "consistency": 1,
                    "community": 1,
                },
                "createdAt": item.get("signedAt"),
                "updatedAt": item.get("signedAt"),
            }
            if norm_p and norm_p != "unknown":
                _MEM_PHONE_INDEX[norm_p] = uid


_seed_in_memory_catalog()


def get_firebase_app(settings: Settings | None = None):
    global _firebase_initialized, _firebase_app
    if _firebase_initialized and _firebase_app:
        return _firebase_app
    settings = settings or get_settings()
    cred_path = settings.resolved_credentials_path
    if not cred_path:
        return None
    try:
        import firebase_admin
        from firebase_admin import credentials

        if not firebase_admin._apps:
            cred = credentials.Certificate(str(cred_path))
            options: dict[str, Any] = {}
            if settings.firebase_project_id:
                options["projectId"] = settings.firebase_project_id
            _firebase_app = firebase_admin.initialize_app(cred, options=options)
        else:
            _firebase_app = firebase_admin.get_app()
        _firebase_initialized = True
        return _firebase_app
    except Exception as exc:
        log.warning("Firebase Admin initialization failed: %s", exc)
        return None


def get_firestore_client(settings: Settings | None = None):
    global _firestore_client
    # During automated tests or offline runs, default to fast in-memory store
    # unless explicitly configured with FORCE_FIRESTORE=1
    if (
        (os.environ.get("PYTEST_CURRENT_TEST") or os.environ.get("KALASETU_OFFLINE"))
        and not os.environ.get("FORCE_FIRESTORE")
    ):
        return None

    if _firestore_client is not None:
        return _firestore_client

    app = get_firebase_app(settings)
    if not app:
        return None
    try:
        # The default google-cloud-firestore gRPC transport can hang behind
        # otherwise-working local proxies/firewalls. Firebase's REST endpoint
        # is reachable in the same environment and exposes the same high-level
        # document/query API, so use it for reliable local and hosted writes.
        from google.cloud import firestore as google_firestore
        from google.cloud.firestore_v1.services.firestore import client as firestore_client
        from google.cloud.firestore_v1.services.firestore.transports import FirestoreRestTransport
        from google.oauth2 import service_account

        settings = settings or get_settings()
        credentials_path = settings.resolved_credentials_path
        if credentials_path is None:
            return None
        credentials = service_account.Credentials.from_service_account_file(
            str(credentials_path),
            scopes=["https://www.googleapis.com/auth/datastore"],
        )

        class RestFirestoreClient(google_firestore.Client):
            @property
            def _firestore_api(self):
                if self._firestore_api_internal is None:
                    transport = FirestoreRestTransport(credentials=self._credentials)
                    self._firestore_api_internal = firestore_client.FirestoreClient(
                        transport=transport,
                        client_options=self._client_options,
                    )
                return self._firestore_api_internal

        _firestore_client = RestFirestoreClient(
            project=settings.firebase_project_id or credentials.project_id,
            credentials=credentials,
            database=settings.firestore_database or "(default)",
        )
        return _firestore_client
    except Exception as exc:
        log.warning("Firestore client creation failed: %s", exc)
        return None


def mint_custom_token(
    uid: str,
    claims: dict[str, Any] | None = None,
    settings: Settings | None = None,
) -> str | None:
    app = get_firebase_app(settings)
    if not app:
        return None
    try:
        from firebase_admin import auth

        token = auth.create_custom_token(uid, developer_claims=claims, app=app)
        if isinstance(token, bytes):
            return token.decode("utf-8")
        return str(token)
    except Exception as exc:
        log.warning("Firebase custom token creation failed: %s", exc)
        return None


# ---------------------------------------------------------------------------
# Artisan profiles
# ---------------------------------------------------------------------------


def get_or_create_artisan(
    phone: str,
    settings: Settings | None = None,
) -> dict[str, Any]:
    norm_phone = normalize_phone(phone)
    now_iso = datetime.now(timezone.utc).isoformat()
    db = get_firestore_client(settings)

    if db is not None:
        try:
            phone_doc_ref = db.collection("phone_index").document(norm_phone)
            # Keep local/demo auth responsive when Firebase credentials exist but
            # Firestore is unreachable (for example, offline DNS). Production
            # still uses Firestore; an unavailable network falls back to memory.
            phone_snap = phone_doc_ref.get(timeout=15.0)
            if phone_snap.exists:
                data = phone_snap.to_dict() or {}
                existing_uid = data.get("uid")
                if existing_uid:
                    art_doc_ref = db.collection("artisans").document(existing_uid)
                    art_snap = art_doc_ref.get(timeout=15.0)
                    if art_snap.exists:
                        art_data = art_snap.to_dict() or {}
                        art_data["uid"] = existing_uid
                        return art_data

            # Create new artisan with unique UUID
            new_uid = str(uuid.uuid4())
            new_artisan: dict[str, Any] = {
                "uid": new_uid,
                "phone": norm_phone,
                "name": "",
                "lang": "mr-IN",
                "cluster": "varanasi",
                "pehchan": {},
                "consentAt": None,
                "tradeRecord": {
                    "identity": 1,
                    "listings": 0,
                    "sales": 0,
                    "consistency": 1,
                    "community": 1,
                },
                "createdAt": now_iso,
                "updatedAt": now_iso,
            }
            db.collection("artisans").document(new_uid).set(new_artisan, timeout=15.0)
            phone_doc_ref.set(
                {
                    "uid": new_uid,
                    "phone": norm_phone,
                    "createdAt": now_iso,
                },
                timeout=15.0,
            )
            return new_artisan
        except Exception as exc:
            log.warning("Firestore get_or_create_artisan failed, falling back to memory: %s", exc)

    # In-memory fallback
    if norm_phone in _MEM_PHONE_INDEX:
        mem_uid = _MEM_PHONE_INDEX[norm_phone]
        if mem_uid in _MEM_ARTISANS:
            return _MEM_ARTISANS[mem_uid]

    new_uid = str(uuid.uuid4())
    mem_artisan: dict[str, Any] = {
        "uid": new_uid,
        "phone": norm_phone,
        "name": "",
        "lang": "mr-IN",
        "cluster": "varanasi",
        "pehchan": {},
        "consentAt": None,
        "tradeRecord": {
            "identity": 1,
            "listings": 0,
            "sales": 0,
            "consistency": 1,
            "community": 1,
        },
        "createdAt": now_iso,
        "updatedAt": now_iso,
    }
    _MEM_PHONE_INDEX[norm_phone] = new_uid
    _MEM_ARTISANS[new_uid] = mem_artisan
    return mem_artisan


def resolve_listing_uid(
    listing_id: str,
    settings: Settings | None = None,
) -> str | None:
    if listing_id in _MEM_LISTING_INDEX:
        return _MEM_LISTING_INDEX[listing_id]
    db = get_firestore_client(settings)
    if db is not None:
        try:
            snap = db.collection("listing_index").document(listing_id).get()
            if snap.exists:
                return (snap.to_dict() or {}).get("uid")
        except Exception as exc:
            log.warning("Firestore resolve_listing_uid failed: %s", exc)
    if listing_id in DEMO_LISTINGS:
        return DEMO_LISTINGS[listing_id].get("artisanId") or DEMO_LISTINGS[listing_id].get("artisan", {}).get("uid")
    return None


def get_artisan(uid: str, settings: Settings | None = None) -> dict[str, Any] | None:
    db = get_firestore_client(settings)
    if db is not None:
        try:
            snap = db.collection("artisans").document(uid).get()
            if snap.exists:
                data = snap.to_dict() or {}
                data["uid"] = uid
                return data
        except Exception as exc:
            log.warning("Firestore get_artisan failed: %s", exc)
    return _MEM_ARTISANS.get(uid)


def update_artisan(
    uid: str,
    updates: dict[str, Any],
    settings: Settings | None = None,
) -> dict[str, Any] | None:
    now_iso = datetime.now(timezone.utc).isoformat()
    fields = dict(updates)
    fields["updatedAt"] = now_iso
    db = get_firestore_client(settings)
    if db is not None:
        try:
            doc_ref = db.collection("artisans").document(uid)
            doc_ref.update(fields)
            snap = doc_ref.get()
            if snap.exists:
                data = snap.to_dict() or {}
                data["uid"] = uid
                return data
        except Exception as exc:
            log.warning("Firestore update_artisan failed: %s", exc)
    if uid in _MEM_ARTISANS:
        _MEM_ARTISANS[uid].update(fields)
        return _MEM_ARTISANS[uid]
    return None


# ---------------------------------------------------------------------------
# Pipeline Events
# ---------------------------------------------------------------------------


def record_event(
    *,
    uid: str,
    listing_id: str,
    kind: str,
    payload: dict[str, Any] | None = None,
    settings: Settings | None = None,
) -> dict[str, Any]:
    event = {
        "id": str(uuid.uuid4()),
        "artisanId": uid,
        "listingId": listing_id,
        "kind": kind,
        "ts": datetime.now(timezone.utc).isoformat(),
        "payload": payload or {},
    }
    db = get_firestore_client(settings)
    if db is not None:
        try:
            db.collection("events").document(event["id"]).set(event)
            return event
        except Exception as exc:
            log.warning("Firestore record_event failed: %s", exc)
    _MEM_EVENTS.append(event)
    return event


def list_events(
    uid: str,
    *,
    kind: str | None = None,
    listing_id: str | None = None,
    settings: Settings | None = None,
) -> list[dict[str, Any]]:
    items: list[dict[str, Any]] = []
    db = get_firestore_client(settings)
    if db is not None:
        try:
            query = db.collection("events").where("artisanId", "==", uid)
            if kind:
                query = query.where("kind", "==", kind)
            docs = query.stream()
            for d in docs:
                m = d.to_dict() or {}
                m["id"] = d.id
                items.append(m)
        except Exception as exc:
            log.warning("Firestore list_events failed: %s", exc)

    if not items:
        items = [e for e in _MEM_EVENTS if e.get("artisanId") == uid]
        if kind:
            items = [e for e in items if e.get("kind") == kind]
    if listing_id:
        items = [e for e in items if e.get("listingId") == listing_id]
    items.sort(key=lambda x: str(x.get("ts", "")), reverse=True)
    return items


# ---------------------------------------------------------------------------
# Listings CRUD & Persistence
# ---------------------------------------------------------------------------


def save_listing(
    *,
    uid: str,
    listing_id: str,
    data: dict[str, Any],
    settings: Settings | None = None,
) -> dict[str, Any]:
    now_iso = datetime.now(timezone.utc).isoformat()
    existing = get_listing(listing_id, uid=uid, settings=settings) or {}

    merged: dict[str, Any] = {
        **existing,
        **data,
        "id": listing_id,
        "artisanId": uid,
        "status": data.get("status") or existing.get("status") or "draft",
        "updatedAt": now_iso,
    }
    if "createdAt" not in merged:
        merged["createdAt"] = now_iso

    db = get_firestore_client(settings)
    if db is not None:
        try:
            doc_ref = db.collection("artisans").document(uid).collection("listings").document(listing_id)
            doc_ref.set(merged)
            db.collection("listing_index").document(listing_id).set(
                {
                    "uid": uid,
                    "listingId": listing_id,
                    "updatedAt": now_iso,
                }
            )
            return merged
        except Exception as exc:
            log.warning("Firestore save_listing failed: %s", exc)

    _MEM_LISTINGS[(uid, listing_id)] = merged
    _MEM_LISTING_INDEX[listing_id] = uid
    return merged


def get_listing(
    listing_id: str,
    uid: str | None = None,
    settings: Settings | None = None,
) -> dict[str, Any] | None:
    db = get_firestore_client(settings)

    if uid and db is not None:
        try:
            snap = db.collection("artisans").document(uid).collection("listings").document(listing_id).get()
            if snap.exists:
                item = snap.to_dict() or {}
                item["id"] = listing_id
                return item
        except Exception as exc:
            log.warning("Firestore get_listing (by uid) failed: %s", exc)

    # Check listing index to find the author uid
    if db is not None:
        try:
            idx_snap = db.collection("listing_index").document(listing_id).get()
            if idx_snap.exists:
                author_uid = (idx_snap.to_dict() or {}).get("uid")
                if author_uid:
                    snap = (
                        db.collection("artisans")
                        .document(author_uid)
                        .collection("listings")
                        .document(listing_id)
                        .get()
                    )
                    if snap.exists:
                        item = snap.to_dict() or {}
                        item["id"] = listing_id
                        return item
        except Exception as exc:
            log.warning("Firestore listing_index lookup failed: %s", exc)

        # Check publishedListings directly
        try:
            pub_snap = db.collection("publishedListings").document(listing_id).get()
            if pub_snap.exists:
                item = pub_snap.to_dict() or {}
                item["id"] = listing_id
                return item
        except Exception as exc:
            log.warning("Firestore publishedListings lookup failed: %s", exc)

    # In-memory lookup
    if uid and (uid, listing_id) in _MEM_LISTINGS:
        return _MEM_LISTINGS[(uid, listing_id)]

    mem_uid = _MEM_LISTING_INDEX.get(listing_id)
    if mem_uid and (mem_uid, listing_id) in _MEM_LISTINGS:
        return _MEM_LISTINGS[(mem_uid, listing_id)]

    if listing_id in _MEM_PUBLISHED:
        return _MEM_PUBLISHED[listing_id]

    # Backward-compatible fallback to DEMO_LISTINGS
    if listing_id in DEMO_LISTINGS:
        return DEMO_LISTINGS[listing_id]

    return None


def list_artisan_listings(
    uid: str,
    settings: Settings | None = None,
) -> list[dict[str, Any]]:
    db = get_firestore_client(settings)
    if db is not None:
        try:
            docs = (
                db.collection("artisans")
                .document(uid)
                .collection("listings")
                .order_by("updatedAt", direction="DESCENDING")
                .stream()
            )
            items = []
            for d in docs:
                m = d.to_dict() or {}
                m["id"] = d.id
                items.append(m)
            if items:
                return items
        except Exception as exc:
            log.warning("Firestore list_artisan_listings failed: %s", exc)

    # In-memory
    mem_items = [
        item for (author_uid, _), item in _MEM_LISTINGS.items() if author_uid == uid
    ]
    mem_items.sort(key=lambda x: str(x.get("updatedAt", "")), reverse=True)
    return mem_items


def publish_listing_doc(
    *,
    uid: str,
    listing_id: str,
    signing_meta: dict[str, Any],
    settings: Settings | None = None,
) -> dict[str, Any]:
    now_iso = signing_meta.get("signed_at") or datetime.now(timezone.utc).isoformat()
    listing = get_listing(listing_id, uid=uid, settings=settings) or {}

    was_published = (listing.get("status") == "published")

    updated_listing = {
        **listing,
        "id": listing_id,
        "artisanId": uid,
        "status": "published",
        "signature": signing_meta.get("signature"),
        "qrUrl": signing_meta.get("qr_url"),
        "signedAt": now_iso,
        "updatedAt": now_iso,
    }

    # Public denormalized projection (no phone number or private identity fields)
    title_en = updated_listing.get("title_en") or updated_listing.get("title") or ""
    title_hi = updated_listing.get("title_hi") or ""
    title = title_en or title_hi or updated_listing.get("fields", {}).get("craft") or "Handmade creation"
    desc_en = updated_listing.get("desc_en") or updated_listing.get("description") or ""
    desc_hi = updated_listing.get("desc_hi") or ""

    photo_url = (
        updated_listing.get("studioUrl")
        or updated_listing.get("originalUrl")
        or updated_listing.get("photo_url")
        or ""
    )

    prices = updated_listing.get("prices") or {}
    listed_price = (
        prices.get("listed", {}).get("value")
        or prices.get("recommended", {}).get("value")
        or updated_listing.get("price_hint")
    )

    public_card: dict[str, Any] = {
        "id": listing_id,
        "artisanId": uid,
        "title": title,
        "title_hi": title_hi,
        "title_en": title_en,
        "description": desc_en or desc_hi,
        "desc_en": desc_en or desc_hi,
        "desc_hi": desc_hi,
        "photo_url": photo_url,
        "image_url": photo_url,
        "category": updated_listing.get("category") or "Handicrafts",
        "craft": updated_listing.get("craft") or updated_listing.get("fields", {}).get("craft", "handloom"),
        "cluster": updated_listing.get("cluster", "varanasi"),
        "cluster_name": updated_listing.get("cluster_name") or updated_listing.get("cluster", "").title(),
        "artisan": updated_listing.get("artisan"),
        "status": "published",
        "prices": prices,
        "listed_price": listed_price,
        "price_hint": listed_price,
        "fields": updated_listing.get("fields", {}),
        "tags": updated_listing.get("tags", []),
        "gi": updated_listing.get("fields", {}).get("gi", "no"),
        "qr_url": signing_meta.get("qr_url"),
        "signature": signing_meta.get("signature"),
        "signedAt": now_iso,
        "source_label": signing_meta.get("source_label", "KalaSetu Verified"),
        "updatedAt": now_iso,
    }

    db = get_firestore_client(settings)
    if db is not None:
        try:
            # 1. Update artisan's private listing doc
            db.collection("artisans").document(uid).collection("listings").document(listing_id).set(updated_listing)
            # 2. Update listing_index
            db.collection("listing_index").document(listing_id).set({"uid": uid, "listingId": listing_id, "updatedAt": now_iso})
            # 3. Publish to public collection
            db.collection("publishedListings").document(listing_id).set(public_card)
            # 4. Increment artisan's tradeRecord listings count on first publish
            if not was_published:
                art_ref = db.collection("artisans").document(uid)
                art_snap = art_ref.get()
                if art_snap.exists:
                    trade_record = (art_snap.to_dict() or {}).get("tradeRecord", {})
                    current_count = trade_record.get("listings", 0)
                    trade_record["listings"] = current_count + 1
                    art_ref.update({"tradeRecord": trade_record})
        except Exception as exc:
            log.warning("Firestore publish_listing_doc failed: %s", exc)

    _MEM_LISTINGS[(uid, listing_id)] = updated_listing
    _MEM_LISTING_INDEX[listing_id] = uid
    _MEM_PUBLISHED[listing_id] = public_card

    if uid in _MEM_ARTISANS and not was_published:
        trade = _MEM_ARTISANS[uid].setdefault("tradeRecord", {})
        trade["listings"] = int(trade.get("listings") or 0) + 1

    record_event(uid=uid, listing_id=listing_id, kind="listing.signed", payload={"signature": signing_meta.get("signature")}, settings=settings)
    record_event(uid=uid, listing_id=listing_id, kind="listing.published", payload={"qrUrl": signing_meta.get("qr_url")}, settings=settings)

    return public_card


def list_published_market_items(settings: Settings | None = None) -> list[dict[str, Any]]:
    db = get_firestore_client(settings)
    items: list[dict[str, Any]] = []

    if db is not None:
        try:
            docs = (
                db.collection("publishedListings")
                .where("status", "==", "published")
                .order_by("updatedAt", direction="DESCENDING")
                .stream()
            )
            for d in docs:
                m = d.to_dict() or {}
                m["id"] = d.id
                items.append(m)
        except Exception as exc:
            log.warning("Firestore list_published_market_items failed: %s", exc)

    if not items:
        # Merge in-memory published items
        items = [
            item for item in _MEM_PUBLISHED.values() if item.get("status") == "published"
        ]
        items.sort(key=lambda x: str(x.get("updatedAt", "")), reverse=True)

    # Always ensure baseline demo items are present if market is otherwise empty
    if not items:
        return list_market_catalog()

    # Prepend any newly published items ahead of demo catalog
    demo_catalog = list_market_catalog()
    existing_ids = {item["id"] for item in items}
    for demo in demo_catalog:
        if demo["id"] not in existing_ids:
            items.append(demo)

    return items


def bootstrap_firestore_catalog(settings: Settings | None = None) -> dict[str, Any]:
    """Seed all 30 handcrafted products and artisan accounts directly to Firestore."""
    db = get_firestore_client(settings)
    if db is None:
        return {
            "artisans": len(_MEM_ARTISANS),
            "listings": len(_MEM_PUBLISHED),
            "mode": "in_memory",
        }

    count_artisans = 0
    count_listings = 0
    items = get_all_30_catalog_items(settings=settings)

    for item in items:
        uid = item["artisanId"]
        listing_id = item["id"]
        art = item.get("artisan") or {}
        phone = normalize_phone(art.get("phone", ""))

        # 1. Artisan profile
        artisan_doc = {
            "uid": uid,
            "phone": phone,
            "name": art.get("name", ""),
            "lang": "hi-IN",
            "cluster": item.get("cluster", "varanasi"),
            "pehchan": {"id": art.get("pehchan_id")},
            "consentAt": item.get("signedAt"),
            "tradeRecord": {
                "identity": 1,
                "listings": 1,
                "sales": 0,
                "consistency": 1,
                "community": 1,
            },
            "createdAt": item.get("signedAt"),
            "updatedAt": item.get("signedAt"),
        }
        try:
            db.collection("artisans").document(uid).set(artisan_doc, merge=True)
            if phone and phone != "unknown":
                db.collection("phone_index").document(phone).set(
                    {"uid": uid, "phone": phone, "createdAt": item.get("signedAt")},
                    merge=True,
                )
            count_artisans += 1

            # 2. Private artisan listing
            db.collection("artisans").document(uid).collection("listings").document(listing_id).set(item, merge=True)
            # 3. Listing index
            db.collection("listing_index").document(listing_id).set(
                {"uid": uid, "listingId": listing_id, "updatedAt": item.get("updatedAt")},
                merge=True,
            )
            # 4. Published listing for /market
            db.collection("publishedListings").document(listing_id).set(item, merge=True)
            count_listings += 1
        except Exception as exc:
            log.warning("Firestore bootstrap failed for %s: %s", listing_id, exc)

    log.info("Bootstrapped %d listings and %d artisans to Firestore", count_listings, count_artisans)
    return {"artisans": count_artisans, "listings": count_listings, "mode": "firestore"}


# ---------------------------------------------------------------------------
# Sales + Trade Record
# ---------------------------------------------------------------------------


def save_sale(
    *,
    uid: str,
    listing_id: str,
    amount: float,
    settings: Settings | None = None,
    extra: dict[str, Any] | None = None,
) -> dict[str, Any]:
    listing = get_listing(listing_id, uid=uid, settings=settings) or {}
    fields = listing.get("fields") or {}
    colours = fields.get("colour") or []
    if isinstance(colours, str):
        colours = [colours]
    colour = colours[0] if colours else ""
    sale_id = str(uuid.uuid4())
    now_iso = datetime.now(timezone.utc).isoformat()
    rec = None
    prices = listing.get("prices") or {}
    if isinstance(prices, dict):
        rec = (prices.get("recommended") or {}).get("value")
    sale: dict[str, Any] = {
        "id": sale_id,
        "artisanId": uid,
        "listingId": listing_id,
        "craft": listing.get("craft") or fields.get("craft") or "",
        "colour": colour,
        "cluster": listing.get("cluster") or "varanasi",
        "amount": float(amount),
        "recommended": rec,
        "confirmedAt": now_iso,
        **(extra or {}),
    }
    db = get_firestore_client(settings)
    if db is not None:
        try:
            db.collection("sales").document(sale_id).set(sale)
            art_ref = db.collection("artisans").document(uid)
            art_snap = art_ref.get()
            if art_snap.exists:
                trade_record = (art_snap.to_dict() or {}).get("tradeRecord", {})
                trade_record["sales"] = int(trade_record.get("sales") or 0) + 1
                art_ref.update({"tradeRecord": trade_record})
        except Exception as exc:
            log.warning("Firestore save_sale failed: %s", exc)

    _MEM_SALES[sale_id] = sale
    if uid in _MEM_ARTISANS:
        trade = _MEM_ARTISANS[uid].setdefault("tradeRecord", {})
        trade["sales"] = int(trade.get("sales") or 0) + 1
    record_event(
        uid=uid,
        listing_id=listing_id,
        kind="sale.confirmed",
        payload={"amount": amount, "saleId": sale_id},
        settings=settings,
    )
    return sale


def list_artisan_sales(uid: str, settings: Settings | None = None) -> list[dict[str, Any]]:
    items: list[dict[str, Any]] = []
    db = get_firestore_client(settings)
    if db is not None:
        try:
            docs = (
                db.collection("sales")
                .where("artisanId", "==", uid)
                .order_by("confirmedAt", direction="DESCENDING")
                .stream()
            )
            for d in docs:
                m = d.to_dict() or {}
                m["id"] = d.id
                items.append(m)
        except Exception as exc:
            log.warning("Firestore list_artisan_sales failed: %s", exc)
    if not items:
        items = [s for s in _MEM_SALES.values() if s.get("artisanId") == uid]
        items.sort(key=lambda x: str(x.get("confirmedAt", "")), reverse=True)
    return items


def list_all_sales(settings: Settings | None = None) -> list[dict[str, Any]]:
    items: list[dict[str, Any]] = []
    db = get_firestore_client(settings)
    if db is not None:
        try:
            docs = db.collection("sales").stream()
            for d in docs:
                m = d.to_dict() or {}
                m["id"] = d.id
                items.append(m)
        except Exception as exc:
            log.warning("Firestore list_all_sales failed: %s", exc)
    if not items:
        items = list(_MEM_SALES.values())
    return items


def compute_trade_record(uid: str, settings: Settings | None = None) -> dict[str, Any]:
    """Five unlock bars. Never labelled a credit score."""
    artisan = get_artisan(uid, settings=settings) or {}
    listings = list_artisan_listings(uid, settings=settings)
    published = [item for item in listings if item.get("status") == "published"]
    sales = list_artisan_sales(uid, settings=settings)
    pehchan = artisan.get("pehchan") or {}
    consent = bool(artisan.get("consentAt"))
    identity = 5 if (pehchan.get("id") and consent) else (3 if (pehchan.get("id") or consent) else (1 if artisan.get("phone") else 0))
    listing_bar = min(5, len(published))
    sales_bar = min(5, len(sales))

    latest = published[0].get("updatedAt") or published[0].get("signedAt") if published else None
    consistency = 0
    if latest:
        try:
            ts = datetime.fromisoformat(str(latest).replace("Z", "+00:00"))
            age_days = (datetime.now(timezone.utc) - ts).days
            if age_days <= 7:
                consistency = 5
            elif age_days <= 30:
                consistency = 3
            else:
                consistency = 1
        except ValueError:
            consistency = 1 if published else 0
    community = 5 if len(published) >= 2 else (3 if published else 0)

    record = {
        "identity": identity,
        "listings": listing_bar,
        "sales": sales_bar,
        "consistency": consistency,
        "community": community,
        "counts": {
            "published": len(published),
            "sales": len(sales),
            "drafts": len([item for item in listings if item.get("status") == "draft"]),
        },
        "label": "Trade Record",
    }
    update_artisan(uid, {"tradeRecord": {
        "identity": identity,
        "listings": len(published),
        "sales": len(sales),
        "consistency": consistency,
        "community": community,
    }}, settings=settings)
    return record


# ---------------------------------------------------------------------------
# Public trends
# ---------------------------------------------------------------------------


def save_public_trends(
    payload: dict[str, Any],
    window_id: str = "current",
    settings: Settings | None = None,
) -> dict[str, Any]:
    doc = {**payload, "windowId": window_id}
    db = get_firestore_client(settings)
    if db is not None:
        try:
            db.collection("public_trends").document(window_id).set(doc)
        except Exception as exc:
            log.warning("Firestore save_public_trends failed: %s", exc)
    _MEM_TRENDS[window_id] = doc
    return doc


def get_public_trends(
    window_id: str = "current",
    settings: Settings | None = None,
) -> dict[str, Any] | None:
    db = get_firestore_client(settings)
    if db is not None:
        try:
            snap = db.collection("public_trends").document(window_id).get()
            if snap.exists:
                data = snap.to_dict() or {}
                data["windowId"] = window_id
                return data
        except Exception as exc:
            log.warning("Firestore get_public_trends failed: %s", exc)
    return _MEM_TRENDS.get(window_id)
