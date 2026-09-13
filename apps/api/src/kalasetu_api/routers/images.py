from __future__ import annotations

import asyncio

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status

from kalasetu_api.deps import require_bearer
from kalasetu_api.engines.studio import (
    PRESET_NAMES,
    StudioUnavailable,
    enhance_bytes,
)
from kalasetu_api.listing_media import media_url, put_studio_media

router = APIRouter(tags=["images"])


@router.post("/v1/images/enhance")
async def enhance(
    file: UploadFile = File(...),
    bg_preset: str = Form("linen"),
    listing_id: str = Form(...),
    craft: str = Form(""),
    _: str = Depends(require_bearer),
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
    data = await file.read()
    if not data:
        raise HTTPException(status_code=400, detail="Empty image")
    try:
        result = await asyncio.to_thread(
            enhance_bytes, data, preset=chosen, craft=craft
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except StudioUnavailable as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=str(exc)
        ) from exc
    put_studio_media(listing_id, result)
    return {
        "listing_id": listing_id,
        "accepted": result.accepted,
        "deltaE": result.delta_e,
        "deltaE_limit": 2.0,
        "bg_preset": result.bg_preset,
        "bg_reason": result.bg_reason,
        "reject_reason": result.reject_reason,
        "original_url": media_url(listing_id, "original"),
        "studio_url": media_url(listing_id, "studio"),
        "used_studio": result.accepted,
        "provenance": result.provenance,
    }
