"""Firebase Storage for listing media.

Paths (locked in agent-coding-guide/06_DATA.md):

    artisans/{uid}/listings/{listingId}/original.jpg
    artisans/{uid}/listings/{listingId}/studio.jpg
    artisans/{uid}/listings/{listingId}/audio.opus
    artisans/{uid}/listings/{listingId}/qr.png

Falls back to None when Admin SDK / bucket is unavailable (tests, offline).
Clients still fetch bytes through GET /v1/listings/{id}/media/{filename}.
"""

from __future__ import annotations

import logging
import os
from typing import Any

from kalasetu_api.adapters import firebase as fb
from kalasetu_api.config import Settings, get_settings

log = logging.getLogger("kalasetu.storage")

CONTENT_TYPES: dict[str, str] = {
    "original.jpg": "image/jpeg",
    "original.jpeg": "image/jpeg",
    "studio.jpg": "image/jpeg",
    "studio.jpeg": "image/jpeg",
    "qr.png": "image/png",
    "audio.opus": "audio/opus",
    "audio.wav": "audio/wav",
    "audio.webm": "audio/webm",
}


def canonical_filename(filename: str) -> str:
    name = (filename or "").strip().lower().split("/")[-1]
    aliases = {
        "original": "original.jpg",
        "original.jpeg": "original.jpg",
        "studio": "studio.jpg",
        "studio.jpeg": "studio.jpg",
        "qr": "qr.png",
        "audio": "audio.opus",
        "audio.ogg": "audio.opus",
    }
    return aliases.get(name, name)


def content_type_for(filename: str) -> str:
    return CONTENT_TYPES.get(canonical_filename(filename), "application/octet-stream")


def blob_path(uid: str, listing_id: str, filename: str) -> str:
    return f"artisans/{uid}/listings/{listing_id}/{canonical_filename(filename)}"


def profile_document_path(uid: str, document_id: str, filename: str) -> str:
    safe_name = (filename or "document").strip().lower().split("/")[-1]
    extension = safe_name.rsplit(".", 1)[-1] if "." in safe_name else "bin"
    return f"artisans/{uid}/documents/{document_id}.{extension}"


def upload_profile_document(
    uid: str,
    document_id: str,
    filename: str,
    data: bytes,
    content_type: str,
    settings: Settings | None = None,
) -> str | None:
    if not data or not uid or not document_id:
        return None
    bucket = get_storage_bucket(settings)
    if bucket is None:
        return None
    path = profile_document_path(uid, document_id, filename)
    try:
        bucket.blob(path).upload_from_string(data, content_type=content_type)
        return path
    except Exception as exc:
        log.warning("Firebase profile document upload failed for %s: %s", path, exc)
        return None


def _skip_network() -> bool:
    return bool(os.environ.get("PYTEST_CURRENT_TEST")) and not os.environ.get("FORCE_FIRESTORE")


def get_storage_bucket(settings: Settings | None = None):
    if _skip_network():
        return None
    settings = settings or get_settings()
    app = fb.get_firebase_app(settings)
    if not app:
        return None
    bucket_name = (
        settings.firebase_storage_bucket
        or (f"{settings.firebase_project_id}.firebasestorage.app" if settings.firebase_project_id else "")
    )
    if not bucket_name:
        return None
    try:
        from firebase_admin import storage

        return storage.bucket(bucket_name, app=app)
    except Exception as exc:
        log.warning("Firebase Storage bucket unavailable: %s", exc)
        return None


def upload_listing_bytes(
    uid: str,
    listing_id: str,
    filename: str,
    data: bytes,
    content_type: str | None = None,
    settings: Settings | None = None,
) -> str | None:
    """Upload bytes to Storage. Returns the API media URL, or None if Storage is offline."""
    if not data or not uid or not listing_id:
        return None
    bucket = get_storage_bucket(settings)
    if bucket is None:
        return None
    name = canonical_filename(filename)
    path = blob_path(uid, listing_id, name)
    try:
        blob = bucket.blob(path)
        blob.upload_from_string(
            data,
            content_type=content_type or content_type_for(name),
        )
        from kalasetu_api.listing_media import media_url

        return media_url(listing_id, name)
    except Exception as exc:
        log.warning("Storage upload failed for %s: %s", path, exc)
        return None


def download_listing_bytes(
    listing_id: str,
    filename: str,
    uid: str | None = None,
    settings: Settings | None = None,
) -> bytes | None:
    name = canonical_filename(filename)
    author = uid or fb.resolve_listing_uid(listing_id, settings=settings)
    if not author:
        return None
    bucket = get_storage_bucket(settings)
    if bucket is None:
        return None
    path = blob_path(author, listing_id, name)
    try:
        blob = bucket.blob(path)
        if not blob.exists():
            return None
        return blob.download_as_bytes()
    except Exception as exc:
        log.warning("Storage download failed for %s: %s", path, exc)
        return None


def storage_status(settings: Settings | None = None) -> dict[str, Any]:
    settings = settings or get_settings()
    bucket_name = settings.firebase_storage_bucket or (
        f"{settings.firebase_project_id}.firebasestorage.app" if settings.firebase_project_id else ""
    )
    return {
        "configured": bool(bucket_name and settings.firebase_admin_ready),
        "bucket": bucket_name or None,
        "location": settings.firebase_storage_location,
    }
