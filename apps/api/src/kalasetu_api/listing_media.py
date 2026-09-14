"""In-process original/studio JPEGs and QR PNGs until Firebase Storage is wired."""

from __future__ import annotations

from typing import Any

from kalasetu_api.config import get_settings
from kalasetu_api.engines.studio import StudioResult

_MEDIA: dict[str, dict[str, Any]] = {}


def put_studio_media(listing_id: str, result: StudioResult) -> dict[str, Any]:
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
        }
    )
    return record


def put_qr_media(listing_id: str, png_bytes: bytes) -> str:
    record = _MEDIA.setdefault(listing_id, {})
    record["qr_png"] = png_bytes
    return media_url(listing_id, "qr.png")


def get_studio_media(listing_id: str) -> dict[str, Any] | None:
    return _MEDIA.get(listing_id)


def media_bytes(listing_id: str, filename: str) -> tuple[bytes, str] | None:
    record = _MEDIA.get(listing_id)
    if record is None:
        return None
    name = filename.lower()
    if name in ("original", "original.jpg", "original.jpeg"):
        data = record.get("original_jpeg")
        return (data, "image/jpeg") if data else None
    if name in ("studio", "studio.jpg", "studio.jpeg"):
        data = record.get("studio_jpeg")
        return (data, "image/jpeg") if data else None
    if name in ("qr", "qr.png"):
        data = record.get("qr_png")
        return (data, "image/png") if data else None
    return None


def media_jpeg(listing_id: str, kind: str) -> bytes | None:
    result = media_bytes(listing_id, kind)
    return result[0] if result else None


def media_url(listing_id: str, filename: str) -> str:
    base = get_settings().public_base_url.rstrip("/")
    if not (filename.endswith(".jpg") or filename.endswith(".png")):
        filename = f"{filename}.jpg"
    return f"{base}/v1/listings/{listing_id}/media/{filename}"


def listing_image_url(listing_id: str, fallback: str) -> str:
    record = _MEDIA.get(listing_id)
    if record is None:
        return fallback
    kind = "studio.jpg" if record.get("accepted") else "original.jpg"
    return media_url(listing_id, kind)
