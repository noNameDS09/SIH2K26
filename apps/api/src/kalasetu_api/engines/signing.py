"""Cryptographic HMAC signing and QR code generation for approved listings.

Frozen values are HMAC-SHA256 signed with settings.listing_hmac_secret.
QR code links directly to the public card /v/{listing_id}.
"""

from __future__ import annotations

import hashlib
import hmac
import io
import json
from datetime import datetime, timezone
from typing import Any

import qrcode

from kalasetu_api.config import get_settings
from kalasetu_api.listing_media import put_qr_media

DEFAULT_HMAC_SECRET = "kalasetu-demo-hmac-secret-v1"


def generate_qr_png(target_url: str) -> bytes:
    """Generate a high-contrast QR PNG targeting the public listing URL."""
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_M,
        box_size=10,
        border=3,
    )
    qr.add_data(target_url)
    qr.make(fit=True)
    img = qr.make_image(fill_color="#1c1917", back_color="#ffffff")
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    return buf.getvalue()


def compute_listing_signature(
    *,
    listing_id: str,
    uid: str,
    fields: dict[str, Any],
    prices: dict[str, Any],
    signed_at: str,
    secret: str | None = None,
) -> str:
    """Deterministic HMAC-SHA256 signature over listing essentials."""
    key = (secret or get_settings().listing_hmac_secret or DEFAULT_HMAC_SECRET).encode(
        "utf-8"
    )
    canonical = json.dumps(
        {
            "id": listing_id,
            "uid": uid,
            "fields": fields,
            "prices": prices,
            "signedAt": signed_at,
        },
        sort_keys=True,
        separators=(",", ":"),
    )
    return hmac.new(key, canonical.encode("utf-8"), hashlib.sha256).hexdigest()


def sign_listing_payload(
    listing: dict[str, Any],
    *,
    uid: str,
    secret: str | None = None,
    public_base_url: str | None = None,
) -> dict[str, Any]:
    """Freeze listing, sign with HMAC, generate QR, and return signing metadata."""
    listing_id = str(listing.get("id") or "")
    if not listing_id:
        raise ValueError("Listing must have an 'id' to be signed")

    signed_at = datetime.now(timezone.utc).isoformat()
    fields = listing.get("fields") or {}
    prices = listing.get("prices") or {}

    signature = compute_listing_signature(
        listing_id=listing_id,
        uid=uid,
        fields=fields,
        prices=prices,
        signed_at=signed_at,
        secret=secret,
    )

    base = (public_base_url or get_settings().public_base_url).rstrip("/")
    public_url = f"{base}/v/{listing_id}"
    qr_png = generate_qr_png(public_url)
    qr_url = put_qr_media(listing_id, qr_png)

    return {
        "listing_id": listing_id,
        "status": "published",
        "signature": signature,
        "signed_at": signed_at,
        "public_url": public_url,
        "qr_url": qr_url,
        "source_label": "KalaSetu Verified",
    }
