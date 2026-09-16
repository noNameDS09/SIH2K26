from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from kalasetu_api.adapters.firebase import get_listing, record_event
from kalasetu_api.deps import current_uid
from kalasetu_api.engines.export import export_listing

router = APIRouter(tags=["export"])


class ExportPayload(BaseModel):
    channel: str = "gem"


@router.get("/v1/listings/{listing_id}/export")
async def export_get(
    listing_id: str,
    channel: str = "gem",
    uid: str = Depends(current_uid),
) -> dict:
    return _export(listing_id, channel, uid)


@router.post("/v1/listings/{listing_id}/export")
async def export_post(
    listing_id: str,
    body: ExportPayload,
    uid: str = Depends(current_uid),
) -> dict:
    return _export(listing_id, body.channel, uid)


def _export(listing_id: str, channel: str, uid: str) -> dict:
    listing = get_listing(listing_id, uid=uid)
    if listing is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Listing not found")
    try:
        payload = export_listing(listing, channel)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    record_event(
        uid=uid,
        listing_id=listing_id,
        kind="listing.exported",
        payload={"channel": payload["channel"], "label": payload["label"]},
    )
    return payload
