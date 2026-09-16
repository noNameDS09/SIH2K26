from __future__ import annotations

import asyncio

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status

from kalasetu_api.adapters.firebase import get_listing, record_event, save_listing
from kalasetu_api.deps import current_uid
from kalasetu_api.engines.studio import (
    PRESET_NAMES,
    StudioUnavailable,
    enhance_bytes,
)
from kalasetu_api.listing_media import media_bytes, media_url, put_studio_media

router = APIRouter(tags=["images"])


@router.post("/v1/images/enhance")
async def enhance(
    file: UploadFile | None = File(default=None),
    bg_preset: str = Form("linen"),
    listing_id: str = Form(...),
    craft: str = Form(""),
    uid: str = Depends(current_uid),
) -> dict:
    listing_id = listing_id.strip()
    if not listing_id:
        raise HTTPException(status_code=400, detail="listing_id is required")
    preset = bg_preset.strip().lower()
    if preset in ("", "auto"):
        chosen: str | None = None
    elif preset in PRESET_NAMES:
        chosen = preset
    else:
        raise HTTPException(
            status_code=400,
            detail=f"bg_preset must be one of {', '.join(PRESET_NAMES)} or auto",
        )
    data = await file.read() if file is not None else b""
    reused_original = False
    if not data:
        stored = media_bytes(listing_id, "original.jpg")
        if stored:
            data = stored[0]
            reused_original = True
        else:
            raise HTTPException(
                status_code=400,
                detail="Empty image. Upload a photo first, or re-enhance a listing that already has original.jpg.",
            )
    listing = get_listing(listing_id, uid=uid) or {}
    craft_value = craft or str(listing.get("craft") or (listing.get("fields") or {}).get("craft") or "")
    try:
        result = await asyncio.to_thread(
            enhance_bytes, data, preset=chosen, craft=craft_value
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except StudioUnavailable as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=str(exc)
        ) from exc

    put_studio_media(listing_id, result, uid=uid)
    orig_url = media_url(listing_id, "original.jpg")
    stud_url = media_url(listing_id, "studio.jpg")

    save_listing(
        uid=uid,
        listing_id=listing_id,
        data={
            "originalUrl": orig_url,
            "studioUrl": stud_url,
            "photo_url": stud_url if result.accepted else orig_url,
            "bgPreset": result.bg_preset,
            "deltaE": result.delta_e,
            "craft": craft_value or None,
        },
    )
    record_event(
        uid=uid,
        listing_id=listing_id,
        kind="media.enhanced",
        payload={
            "accepted": result.accepted,
            "deltaE": result.delta_e,
            "bgPreset": result.bg_preset,
            "reused_original": reused_original,
        },
    )

    return {
        "listing_id": listing_id,
        "accepted": result.accepted,
        "deltaE": result.delta_e,
        "deltaE_limit": 2.0,
        "bg_preset": result.bg_preset,
        "bg_reason": result.bg_reason,
        "reject_reason": result.reject_reason,
        "original_url": orig_url,
        "studio_url": stud_url,
        "used_studio": result.accepted,
        "reused_original": reused_original,
        "provenance": result.provenance,
    }
