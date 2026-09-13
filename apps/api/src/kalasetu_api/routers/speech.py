from __future__ import annotations

import base64

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from pydantic import BaseModel, Field

from kalasetu_api.adapters.speech.sarvam import SarvamError, synthesize_speech, transcribe_audio
from kalasetu_api.deps import require_bearer
from kalasetu_api.engines.cataloger import (
    CatalogerSession,
    apply_transcript,
    listing_table_rows,
    start_session,
)

router = APIRouter(prefix="/v1/speech", tags=["speech"])


class TtsRequest(BaseModel):
    text: str
    language_code: str = "mr-IN"


class CatalogTurnRequest(BaseModel):
    transcript: str = ""
    language_code: str = "mr-IN"
    cluster: str = "varanasi"
    session: dict = Field(default_factory=dict)


def _sarvam_http_error(exc: SarvamError) -> HTTPException:
    return HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=str(exc))


@router.post("/stt")
async def stt(
    _: str = Depends(require_bearer),
    file: UploadFile = File(...),
    language_code: str = Form("mr-IN"),
) -> dict:
    audio = await file.read()
    if not audio:
        raise HTTPException(status_code=400, detail="Empty audio")
    try:
        result = transcribe_audio(
            audio,
            filename=file.filename or "clip.wav",
            content_type=file.content_type or "audio/wav",
            language_code=language_code,
        )
    except SarvamError as exc:
        raise _sarvam_http_error(exc) from exc
    return {
        "transcript": result["transcript"],
        "language_code": result["language_code"],
        "provenance": {
            "source": "sarvam-saaras-v3",
            "version": "3",
            "confidence": 0.9,
        },
    }


@router.post("/tts")
async def tts(body: TtsRequest, _: str = Depends(require_bearer)) -> dict:
    try:
        audio = synthesize_speech(body.text, language_code=body.language_code)
    except SarvamError as exc:
        raise _sarvam_http_error(exc) from exc
    return {
        "audio_b64": base64.b64encode(audio).decode("ascii"),
        "content_type": "audio/wav",
        "language_code": body.language_code,
        "provenance": {"source": "sarvam-bulbul-v3", "version": "3", "confidence": 1.0},
    }


@router.post("/live/turn")
async def live_turn(body: CatalogTurnRequest, _: str = Depends(require_bearer)) -> dict:
    """Turn-based cataloger (Flash JSON at the end). Not a Gemini Live socket."""
    session = (
        start_session(cluster=body.cluster, language_code=body.language_code)
        if not body.session
        else CatalogerSession.from_dict(body.session)
    )
    if body.transcript.strip():
        session = apply_transcript(session, body.transcript)
    return {
        "session": session.to_dict(),
        "speak": session.speak,
        "question": session.question,
        "reread": session.reread,
        "phase": session.phase,
        "done": session.phase == "complete",
        "listing": session.listing,
        "table": listing_table_rows(session) if session.phase == "complete" else [],
        "source_label": "Turn cataloger — not Gemini Live",
    }
