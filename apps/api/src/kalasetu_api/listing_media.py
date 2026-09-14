"""In-process original/studio JPEGs until Firebase Storage is wired."""

from __future__ import annotations

from typing import Any

from kalasetu_api.config import get_settings
from kalasetu_api.engines.studio import StudioResult

_MEDIA: dict[str, dict[str, Any]] = {}


def put_studio_media(listing_id: str, result: StudioResult) -> dict[str, Any]:
    record = {
        "original_jpeg": result.original_jpeg,
        "studio_jpeg": result.studio_jpeg,
        "accepted": result.accepted,
        "deltaE": result.delta_e,
        "bg_preset": result.bg_preset,
        "bg_reason": result.bg_reason,
        "reject_reason": result.reject_reason,
        "provenance": result.provenance,
    }
    _MEDIA[listing_id] = record
    return record


def get_studio_media(listing_id: str) -> dict[str, Any] | None:
    return _MEDIA.get(listing_id)


def media_jpeg(listing_id: str, kind: str) -> bytes | None:
    record = _MEDIA.get(listing_id)
    if record is None or kind not in ("original", "studio"):
        return None
    return record[f"{kind}_jpeg"]


def media_url(listing_id: str, kind: str) -> str:
    base = get_settings().public_base_url.rstrip("/")
    return f"{base}/v1/listings/{listing_id}/media/{kind}.jpg"


def listing_image_url(listing_id: str, fallback: str) -> str:
    record = _MEDIA.get(listing_id)
    if record is None:
        return fallback
    kind = "studio" if record["accepted"] else "original"
    return media_url(listing_id, kind)
