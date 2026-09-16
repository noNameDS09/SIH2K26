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
from kalasetu_api.engines.languages import (
    get_welcome_greeting,
    language_label,
    normalize_language_code,
)
from kalasetu_api.engines.assistant import answer_query
from kalasetu_api.engines.voice_navigation import parse_voice_command

router = APIRouter(prefix="/v1/speech", tags=["speech"])


class TtsRequest(BaseModel):
    text: str
    language_code: str = "mr-IN"


class CatalogTurnRequest(BaseModel):
    transcript: str = ""
    language_code: str = "mr-IN"
    cluster: str = "varanasi"
    session: dict = Field(default_factory=dict)


@router.post("/detect-language")
async def detect_language(file: UploadFile = File(...)) -> dict:
    """Unauthenticated LID endpoint using Sarvam Saaras LID + Bulbul TTS.
    Returns detected language, native label, greeting message, and spoken confirmation audio.
    """
    audio = await file.read()
    if not audio:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Audio file is empty")

    detected_code = "hi-IN"
    transcript = ""
    source = "sarvam-saaras-lid"
    confidence = 0.95

    try:
        res = transcribe_audio(
            audio,
            filename=file.filename or "speech.wav",
            content_type=file.content_type or "audio/wav",
            language_code="unknown",
        )
        detected_code = normalize_language_code(res.get("language_code") or "hi-IN")
        transcript = res.get("transcript") or ""
    except SarvamError:
        # Graceful fallback for offline / mock test environments
        detected_code = "hi-IN"
        transcript = "नमस्ते, मैं बुनकर हूँ।"
        source = "mock-fallback"
        confidence = 0.8

    label = language_label(detected_code)
    greeting = get_welcome_greeting(detected_code)
    audio_b64 = ""
    try:
        tts_audio = synthesize_speech(greeting, language_code=detected_code)
        audio_b64 = base64.b64encode(tts_audio).decode("ascii")
    except Exception:
        audio_b64 = ""

    return {
        "language_code": detected_code,
        "language_name": label,
        "transcript": transcript,
        "greeting": greeting,
        "audio_b64": audio_b64,
        "content_type": "audio/wav" if audio_b64 else "",
        "provenance": {
            "source": source,
            "version": "3",
            "confidence": confidence,
        },
    }


def _sarvam_http_error(exc: SarvamError) -> HTTPException:
    detail = str(exc)
    if " 400:" in detail or "Invalid file type" in detail or "audio too short" in detail:
        return HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="The voice recording format was not accepted. Please record again for a little longer.",
        )
    return HTTPException(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        detail="The speech service is temporarily unavailable. Please try again.",
    )


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


@router.post("/voice-action")
async def voice_action(
    file: UploadFile | None = File(None),
    transcript: str = Form(""),
    language_code: str = Form("hi-IN"),
    listing_id: str | None = Form(None),
    _: str = Depends(require_bearer),
) -> dict:
    """Unified voice navigation and Q&A endpoint.
    If speech contains navigation keywords, navigates to workspace view with spoken confirmation.
    If speech contains a question, answers with grounded KalaSetu Sahayak assistant in user's language.
    """
    norm_lang = normalize_language_code(language_code)
    recognized_text = transcript.strip()

    if file is not None:
        try:
            audio = await file.read()
            if audio:
                stt_res = transcribe_audio(
                    audio,
                    filename=file.filename or "command.wav",
                    content_type=file.content_type or "audio/wav",
                    language_code=norm_lang,
                )
                recognized_text = (stt_res.get("transcript") or "").strip()
        except Exception:
            pass

    if not recognized_text:
        return {
            "intent": "empty",
            "action": "none",
            "target": None,
            "transcript": "",
            "spoken": "कृपया पुनः बोलें।",
            "audio_b64": "",
            "content_type": "",
        }

    parsed = parse_voice_command(recognized_text, language_code=norm_lang)

    if parsed["intent"] in ("navigation", "action"):
        spoken = parsed["spoken"]
        audio_b64 = ""
        try:
            tts_audio = synthesize_speech(spoken, language_code=norm_lang)
            audio_b64 = base64.b64encode(tts_audio).decode("ascii")
        except Exception:
            audio_b64 = ""

        return {
            "intent": parsed["intent"],
            "action": parsed["action"],
            "target": parsed["target"],
            "transcript": recognized_text,
            "spoken": spoken,
            "audio_b64": audio_b64,
            "content_type": "audio/wav" if audio_b64 else "",
        }

    # Intent is question or general query -> route to KalaSetu Sahayak
    result = answer_query(
        query=recognized_text,
        language_code=norm_lang,
        listing_id=listing_id,
    )
    return {
        "intent": "question",
        "action": "assistant",
        "target": None,
        "transcript": recognized_text,
        "spoken": result["answer"],
        "answer": result["answer"],
        "audio_b64": result["audio_b64"],
        "content_type": result["content_type"],
        "provenance": result["provenance"],
    }
