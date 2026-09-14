from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status

from kalasetu_api.adapters.firebase import get_public_trends
from kalasetu_api.deps import require_admin
from kalasetu_api.engines.trends import recompute_public_trends

router = APIRouter(tags=["trends"])


@router.get("/v1/trends/current")
async def current_trends() -> dict:
    item = get_public_trends("current")
    if item is None:
        item = recompute_public_trends()
    return item


@router.post("/v1/trends/recompute")
async def recompute_trends(_: str = Depends(require_admin)) -> dict:
    try:
        return {"ok": True, **recompute_public_trends()}
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(exc),
        ) from exc
