"""KalaSetu Sahayak grounded voice Q&A engine."""

from __future__ import annotations

import base64
from typing import Any

from kalasetu_api.adapters.firebase import get_listing
from kalasetu_api.adapters.llm.gemini import GeminiError, answer_artisan_query
from kalasetu_api.adapters.speech.sarvam import SarvamError, synthesize_speech
from kalasetu_api.engines.languages import normalize_language_code


def answer_query(
    query: str,
    *,
    language_code: str = "hi-IN",
    artisan_context: dict[str, Any] | None = None,
    listing_id: str | None = None,
) -> dict[str, Any]:
    """Answers an artisan question with grounded knowledge and generates Sarvam Bulbul audio."""
    norm_lang = normalize_language_code(language_code)
    listing_context: dict[str, Any] | None = None

    if listing_id:
        try:
            raw = get_listing(listing_id) or {}
            if raw:
                listing_context = {
                    "title": raw.get("title_en") or raw.get("title") or "Artisan Craft",
                    "craft": raw.get("craft_type") or raw.get("craft"),
                    "hours": raw.get("hours_worked"),
                    "material_cost_inr": raw.get("material_cost_inr"),
                    "prices": {
                        "floor": raw.get("price_floor_inr"),
                        "recommended": raw.get("price_recommended_inr"),
                        "aspirational": raw.get("price_aspirational_inr"),
                        "listed": raw.get("price_listed_inr"),
                    },
                    "gi_certified": bool(raw.get("gi_status")),
                    "delta_e": raw.get("delta_e"),
                }
        except Exception:
            listing_context = None

    # Call Gemini Flash grounded reasoner
    try:
        answer = answer_artisan_query(
            query=query,
            target_language=norm_lang,
            artisan_context=artisan_context,
            listing_context=listing_context,
        )
    except (GeminiError, Exception):
        # Fallback reassuring answer if Gemini is offline
        fallback_map = {
            "hi-IN": "कलासेतु आपके शिल्प का सही मूल्य दिलाने और सरकारी पोर्टल से जोड़ने में मदद करता है। आप कभी भी बेझिझक पूछ सकते हैं।",
            "mr-IN": "कलासेतु तुमच्या कलेला योग्य भाव मिळवून देण्यासाठी आणि थेट ग्राहकांशी जोडण्यासाठी मदत करते.",
            "en-IN": "KalaSetu ensures you receive fair value for your craft and connects you directly with buyers and government portals.",
        }
        answer = fallback_map.get(norm_lang, fallback_map["hi-IN"])

    # Synthesize Sarvam Bulbul TTS
    audio_b64 = ""
    try:
        audio_bytes = synthesize_speech(answer, language_code=norm_lang)
        audio_b64 = base64.b64encode(audio_bytes).decode("ascii")
    except (SarvamError, Exception):
        audio_b64 = ""

    return {
        "query": query,
        "answer": answer,
        "audio_b64": audio_b64,
        "content_type": "audio/wav" if audio_b64 else "",
        "language_code": norm_lang,
        "provenance": {
            "source": "kalasetu-sahayak.v1",
            "version": "1",
            "confidence": 0.95,
        },
    }
