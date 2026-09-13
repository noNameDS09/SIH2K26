"""Sarvam Saaras STT + Bulbul TTS. Keys stay on the server."""

from __future__ import annotations

import base64
from typing import Any

import httpx

from kalasetu_api.config import Settings, get_settings


class SarvamError(RuntimeError):
    pass


def _headers(settings: Settings) -> dict[str, str]:
    if not settings.sarvam_api_key:
        raise SarvamError("SARVAM_API_KEY is missing")
    return {"api-subscription-key": settings.sarvam_api_key}


def transcribe_audio(
    audio: bytes,
    *,
    filename: str = "answer.wav",
    content_type: str = "audio/wav",
    language_code: str = "mr-IN",
    settings: Settings | None = None,
) -> dict[str, Any]:
    """REST STT. Audio must be ≤30s. language_code is required for short clips."""
    settings = settings or get_settings()
    url = f"{settings.sarvam_api_base_url.rstrip('/')}/speech-to-text"
    files = {"file": (filename, audio, content_type)}
    data = {
        "model": "saaras:v3",
        "mode": "transcribe",
        "language_code": language_code,
    }
    try:
        with httpx.Client(timeout=60.0, trust_env=False) as client:
            response = client.post(url, headers=_headers(settings), files=files, data=data)
    except httpx.HTTPError as exc:
        raise SarvamError(f"STT network error: {exc}") from exc
    if response.status_code >= 400:
        raise SarvamError(f"STT {response.status_code}: {response.text[:400]}")
    body = response.json()
    return {
        "transcript": (body.get("transcript") or "").strip(),
        "language_code": body.get("language_code") or language_code,
        "request_id": body.get("request_id"),
        "raw": body,
    }


def synthesize_speech(
    text: str,
    *,
    language_code: str = "mr-IN",
    settings: Settings | None = None,
) -> bytes:
    """Bulbul v3. 16 kHz WAV to keep bytes (and cost) down."""
    settings = settings or get_settings()
    clean = (text or "").strip()
    if not clean:
        raise SarvamError("TTS text is empty")
    url = f"{settings.sarvam_api_base_url.rstrip('/')}/text-to-speech"
    payload = {
        "text": clean[:2400],
        "target_language_code": language_code,
        "model": "bulbul:v3",
        "speaker": settings.sarvam_tts_speaker,
        "speech_sample_rate": settings.sarvam_tts_sample_rate,
        "output_audio_codec": "wav",
    }
    try:
        with httpx.Client(timeout=60.0, trust_env=False) as client:
            response = client.post(url, headers=_headers(settings), json=payload)
    except httpx.HTTPError as exc:
        raise SarvamError(f"TTS network error: {exc}") from exc
    if response.status_code >= 400:
        raise SarvamError(f"TTS {response.status_code}: {response.text[:400]}")
    body = response.json()
    chunks = body.get("audios") or []
    if not chunks:
        raise SarvamError("TTS returned no audio")
    return base64.b64decode("".join(chunks))
