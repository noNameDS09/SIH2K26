"""KalaSetu Sahayak Assistant Router."""

from __future__ import annotations

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from kalasetu_api.deps import require_bearer
from kalasetu_api.engines.assistant import answer_query

router = APIRouter(prefix="/v1/assistant", tags=["assistant"])


class AssistantQueryRequest(BaseModel):
    query: str
    language_code: str = "hi-IN"
    listing_id: str | None = None


@router.post("/query")
async def query_assistant(body: AssistantQueryRequest, _: str = Depends(require_bearer)) -> dict:
    """Answers an artisan voice or text question using grounded knowledge and Sarvam Bulbul TTS."""
    return answer_query(
        query=body.query,
        language_code=body.language_code,
        listing_id=body.listing_id,
    )
