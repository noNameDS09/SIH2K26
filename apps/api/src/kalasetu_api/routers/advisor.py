from __future__ import annotations

from fastapi import APIRouter, Depends

from kalasetu_api.adapters.firebase import get_public_trends, list_events
from kalasetu_api.deps import current_uid
from kalasetu_api.engines.advisor import advise_artisan

router = APIRouter(tags=["advisor"])


@router.get("/v1/advisor")
async def advisor(uid: str = Depends(current_uid)) -> dict:
    return advise_artisan(uid)


@router.get("/v1/insights")
async def insights(uid: str = Depends(current_uid)) -> dict:
    advice = advise_artisan(uid, persist=False)
    history = list_events(uid, kind="insight.generated")
    trends = get_public_trends("current") or {}
    return {
        "advisor": advice,
        "history": history,
        "trends": trends,
        "n": trends.get("n"),
        "seed": trends.get("seed"),
    }
