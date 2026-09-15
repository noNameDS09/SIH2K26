"""Cheap Gemini JSON (Flash-Lite). Not Live. One call at the end of an interview."""

from __future__ import annotations

import json
from typing import Any

import httpx

from kalasetu_api.config import Settings, get_settings


class GeminiError(RuntimeError):
    pass


LISTING_SCHEMA: dict[str, Any] = {
    "type": "object",
    "properties": {
        "craft": {"type": "string"},
        "material": {"type": "string"},
        "technique": {"type": "string"},
        "hours": {"type": ["number", "null"]},
        "colour": {"type": "array", "items": {"type": "string"}},
        "occasion": {"type": "string"},
        "gi": {"type": "string", "enum": ["yes", "no", "unsure", ""]},
        "material_cost_inr": {"type": ["integer", "null"]},
        "material_source": {"type": "string", "enum": ["own", "shop", "trader", ""]},
        "effort": {"type": "string", "enum": ["simple", "normal", "skilled", ""]},
        "title_hi": {"type": "string"},
        "title_en": {"type": "string"},
        "title_mr": {"type": "string"},
        "title_local": {"type": "string"},
        "desc_hi": {"type": "string"},
        "desc_en": {"type": "string"},
        "desc_mr": {"type": "string"},
        "desc_local": {"type": "string"},
        "language_code": {"type": "string"},
        "extras": {"type": "object"},
    },
    "required": [
        "craft",
        "material",
        "technique",
        "hours",
        "colour",
        "occasion",
        "gi",
        "material_cost_inr",
        "material_source",
        "effort",
        "title_hi",
        "title_en",
        "title_mr",
        "desc_hi",
        "desc_en",
        "desc_mr",
        "extras",
    ],
}

_SYSTEM = """You normalize one artisan product interview into listing fields.
Do not invent facts. If a slot is empty or they said they do not know, use null / "" / [] / {}.
hours = labour hours. If they gave days, multiply by 8.
material_cost_inr = integer rupees or null.
gi = yes | no | unsure.
material_source = own | shop | trader.
effort = simple | normal | skilled.
colour = short English colour names.
craft, material, technique, occasion = short English keywords (not sentences).
title_* and desc_* must use only the given facts. Hindi, English, and Marathi must always be provided.
If target language is specified, title_local and desc_local must be written fluently in that target language.
extras only holds extra facts they stated (weight, size, GI name, etc)."""


def generate_listing_json(
    slot_transcripts: dict[str, Any],
    *,
    target_language: str = "en-IN",
    settings: Settings | None = None,
) -> dict[str, Any]:
    settings = settings or get_settings()
    if not settings.gemini_api_key:
        raise GeminiError("GEMINI_API_KEY is missing")
    model = settings.gemini_model
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
    prompt = (
        f"Target Artisan Language: {target_language}\n"
        "Interview transcripts keyed by slot. Normalize to the JSON schema.\n\n"
        f"{slot_transcripts}"
    )
    payload = {
        "systemInstruction": {"parts": [{"text": _SYSTEM}]},
        "contents": [{"role": "user", "parts": [{"text": prompt}]}],
        "generationConfig": {
            "temperature": 0,
            "maxOutputTokens": 900,
            "responseMimeType": "application/json",
            "responseSchema": LISTING_SCHEMA,
        },
    }
    headers = {
        "x-goog-api-key": settings.gemini_api_key,
        "Content-Type": "application/json",
    }
    try:
        with httpx.Client(timeout=60.0, trust_env=False) as client:
            response = client.post(url, headers=headers, json=payload)
    except httpx.HTTPError as exc:
        raise GeminiError(f"Gemini network error: {exc}") from exc
    if response.status_code >= 400:
        raise GeminiError(f"Gemini {response.status_code}: {response.text[:500]}")
    body = response.json()
    try:
        text = body["candidates"][0]["content"]["parts"][0]["text"]
    except (KeyError, IndexError, TypeError) as exc:
        raise GeminiError(f"Gemini response missing text: {body}") from exc
    data = json.loads(text)
    if not isinstance(data, dict):
        raise GeminiError("Gemini JSON was not an object")
    return data


def phrase_advisor_sentence(
    *,
    rule_id: str,
    facts: dict[str, Any],
    lang: str = "hi-IN",
    settings: Settings | None = None,
) -> str:
    """Turn one advisor rule object into a single spoken sentence. Empty string on failure."""
    settings = settings or get_settings()
    if not settings.gemini_api_key:
        raise GeminiError("GEMINI_API_KEY is missing")
    model = settings.gemini_model
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
    prompt = (
        f"Language: {lang}\n"
        f"Rule: {rule_id}\n"
        f"Facts: {json.dumps(facts, ensure_ascii=False)}\n"
        "Write ONE short sentence the artisan should hear. No greeting. No extra tips."
    )
    payload = {
        "systemInstruction": {
            "parts": [
                {
                    "text": (
                        "You phrase one business insight for an Indian artisan. "
                        "Return only the sentence in the requested language."
                    )
                }
            ]
        },
        "contents": [{"role": "user", "parts": [{"text": prompt}]}],
        "generationConfig": {"temperature": 0, "maxOutputTokens": 80},
    }
    headers = {
        "x-goog-api-key": settings.gemini_api_key,
        "Content-Type": "application/json",
    }
    try:
        with httpx.Client(timeout=20.0, trust_env=False) as client:
            response = client.post(url, headers=headers, json=payload)
    except httpx.HTTPError as exc:
        raise GeminiError(f"Gemini network error: {exc}") from exc
    if response.status_code >= 400:
        raise GeminiError(f"Gemini {response.status_code}: {response.text[:300]}")
    body = response.json()
    try:
        text = body["candidates"][0]["content"]["parts"][0]["text"]
    except (KeyError, IndexError, TypeError) as exc:
        raise GeminiError(f"Gemini response missing text: {body}") from exc
    return str(text).strip().strip('"')


def translate_text(
    *,
    text: str,
    target_language: str,
    source_language: str = "en",
    settings: Settings | None = None,
) -> str:
    """Translate product title or description into target regional language."""
    clean = text.strip()
    if not clean:
        return ""
    settings = settings or get_settings()
    if not settings.gemini_api_key:
        return clean
    model = settings.gemini_model
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
    prompt = (
        f"Translate the following Indian handicraft product text from {source_language} into {target_language}.\n"
        "Keep cultural terms and craft names (like Saree, Banarasi, Jute, Dokra) natural and authentic.\n"
        "Return ONLY the direct translation with no explanations or punctuation wrapping.\n\n"
        f"{clean}"
    )
    payload = {
        "systemInstruction": {
            "parts": [
                {
                    "text": (
                        "You are a professional translator specializing in Indian handicraft and handloom trade catalogs. "
                        "Translate accurately and respectfully."
                    )
                }
            ]
        },
        "contents": [{"role": "user", "parts": [{"text": prompt}]}],
        "generationConfig": {"temperature": 0.1, "maxOutputTokens": 300},
    }
    headers = {
        "x-goog-api-key": settings.gemini_api_key,
        "Content-Type": "application/json",
    }
    try:
        with httpx.Client(timeout=20.0, trust_env=False) as client:
            response = client.post(url, headers=headers, json=payload)
        if response.status_code == 200:
            body = response.json()
            return str(body["candidates"][0]["content"]["parts"][0]["text"]).strip().strip('"')
    except Exception:
        pass
    return clean

