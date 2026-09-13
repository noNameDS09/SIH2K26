"""Firebase Admin and Firestore adapter for KalaSetu.

Connects to Firestore in asia-south1 (Mumbai) and Firebase Auth custom tokens.
Fallback to in-memory store when offline or credentials not configured.
"""

from __future__ import annotations

import logging
import uuid
from datetime import datetime, timezone
from typing import Any

from kalasetu_api.config import Settings, get_settings

log = logging.getLogger("kalasetu.firebase")

_firebase_initialized = False
_firebase_app = None

# In-memory fallbacks for offline testing / development
_MEM_PHONE_INDEX: dict[str, str] = {}
_MEM_ARTISANS: dict[str, dict[str, Any]] = {}


def normalize_phone(phone: str) -> str:
    cleaned = (phone or "").strip()
    has_plus = cleaned.startswith("+")
    digits = "".join(ch for ch in cleaned if ch.isdigit())
    if not digits:
        return "unknown"
    if len(digits) == 10 and not has_plus:
        return f"+91{digits}"
    return f"+{digits}" if has_plus else f"+{digits}"


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
    app = get_firebase_app(settings)
    if not app:
        return None
    try:
        from firebase_admin import firestore

        settings = settings or get_settings()
        return firestore.client(app=app, database=settings.firestore_database)
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
            phone_snap = phone_doc_ref.get()
            if phone_snap.exists:
                data = phone_snap.to_dict() or {}
                existing_uid = data.get("uid")
                if existing_uid:
                    art_doc_ref = db.collection("artisans").document(existing_uid)
                    art_snap = art_doc_ref.get()
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
            db.collection("artisans").document(new_uid).set(new_artisan)
            phone_doc_ref.set(
                {
                    "uid": new_uid,
                    "phone": norm_phone,
                    "createdAt": now_iso,
                }
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
