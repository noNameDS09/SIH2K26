"""In-process original/studio/QR/audio bytes, mirrored to Firebase Storage when available."""

from __future__ import annotations

import logging
from typing import Any

from kalasetu_api.config import get_settings
from kalasetu_api.engines.studio import StudioResult

log = logging.getLogger("kalasetu.media")

_MEDIA: dict[str, dict[str, Any]] = {}


def put_studio_media(
    listing_id: str,
    result: StudioResult,
    uid: str | None = None,
) -> dict[str, Any]:
    record = _MEDIA.setdefault(listing_id, {})
    record.update(
        {
            "original_jpeg": result.original_jpeg,
            "studio_jpeg": result.studio_jpeg,
            "accepted": result.accepted,
            "deltaE": result.delta_e,
            "bg_preset": result.bg_preset,
            "bg_reason": result.bg_reason,
            "reject_reason": result.reject_reason,
            "provenance": result.provenance,
            "uid": uid or record.get("uid"),
        }
    )
    _persist(listing_id, "original.jpg", result.original_jpeg, "image/jpeg", uid=uid)
    _persist(listing_id, "studio.jpg", result.studio_jpeg, "image/jpeg", uid=uid)
    return record


def put_qr_media(listing_id: str, png_bytes: bytes, uid: str | None = None) -> str:
    record = _MEDIA.setdefault(listing_id, {})
    record["qr_png"] = png_bytes
    if uid:
        record["uid"] = uid
    _persist(listing_id, "qr.png", png_bytes, "image/png", uid=uid)
    return media_url(listing_id, "qr.png")


def put_audio_media(
    listing_id: str,
    data: bytes,
    *,
    uid: str | None = None,
    filename: str = "audio.opus",
    content_type: str = "audio/opus",
) -> str:
    record = _MEDIA.setdefault(listing_id, {})
    record["audio"] = data
    record["audio_name"] = filename
    record["audio_type"] = content_type
    if uid:
        record["uid"] = uid
    _persist(listing_id, filename or "audio.opus", data, content_type, uid=uid)
    return media_url(listing_id, filename or "audio.opus")


def get_studio_media(listing_id: str) -> dict[str, Any] | None:
    return _MEDIA.get(listing_id)


def media_bytes(listing_id: str, filename: str) -> tuple[bytes, str] | None:
    record = _MEDIA.get(listing_id)
    name = filename.lower()
    if record is not None:
        if name in ("original", "original.jpg", "original.jpeg"):
            data = record.get("original_jpeg")
            if data:
                return data, "image/jpeg"
        if name in ("studio", "studio.jpg", "studio.jpeg"):
            data = record.get("studio_jpeg")
            if data:
                return data, "image/jpeg"
        if name in ("qr", "qr.png"):
            data = record.get("qr_png")
            if data:
                return data, "image/png"
        if name in ("audio", "audio.opus", "audio.wav", "audio.webm") or name.startswith("audio."):
            data = record.get("audio")
            if data:
                return data, str(record.get("audio_type") or "audio/opus")

    try:
        from kalasetu_api.adapters.storage import content_type_for, download_listing_bytes

        data = download_listing_bytes(listing_id, filename)
        if data:
            return data, content_type_for(filename)
    except Exception as exc:
        log.warning("Storage fallback read failed for %s/%s: %s", listing_id, filename, exc)
    return None


def media_jpeg(listing_id: str, kind: str) -> bytes | None:
    result = media_bytes(listing_id, kind)
    return result[0] if result else None


def media_url(listing_id: str, filename: str) -> str:
    base = get_settings().public_base_url.rstrip("/")
    if not (filename.endswith(".jpg") or filename.endswith(".png") or filename.endswith(".opus") or filename.endswith(".wav") or filename.endswith(".webm")):
        filename = f"{filename}.jpg"
    return f"{base}/v1/listings/{listing_id}/media/{filename}"


def listing_image_url(listing_id: str, fallback: str) -> str:
    record = _MEDIA.get(listing_id)
    if record is None:
        stored = media_bytes(listing_id, "studio.jpg")
        if stored:
            return media_url(listing_id, "studio.jpg")
        return fallback
    kind = "studio.jpg" if record.get("accepted") else "original.jpg"
    return media_url(listing_id, kind)


def _persist(
    listing_id: str,
    filename: str,
    data: bytes,
    content_type: str,
    uid: str | None = None,
) -> None:
    if not data:
        return
    try:
        from kalasetu_api.adapters.firebase import resolve_listing_uid
        from kalasetu_api.adapters.storage import upload_listing_bytes

        author = uid or resolve_listing_uid(listing_id)
        if not author:
            return
        upload_listing_bytes(author, listing_id, filename, data, content_type)
    except Exception as exc:
        log.warning("Storage persist skipped for %s/%s: %s", listing_id, filename, exc)
