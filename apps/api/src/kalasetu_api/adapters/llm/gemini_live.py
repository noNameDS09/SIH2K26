"""Gemini Live cataloger — cheapest native-audio Live model.

FastAPI holds the socket (same as web). Streamlit / web clients send PCM.
Price is never generated here; tools call cataloger math.
"""

from __future__ import annotations

from typing import Any

from kalasetu_api.config import Settings, get_settings
from kalasetu_api.engines.cataloger import SLOT_ORDER, language_label

LIVE_MODEL_DEFAULT = "gemini-2.5-flash-native-audio-preview-12-2025"

LIVE_TOOLS: list[dict[str, Any]] = [
    {
        "function_declarations": [
            {
                "name": "propose_slot",
                "description": (
                    "Store one listing slot after the artisan answered. "
                    "Then speak the reread from the tool response and wait."
                ),
                "parameters": {
                    "type": "object",
                    "properties": {
                        "slot": {"type": "string", "enum": list(SLOT_ORDER)},
                        "value_text": {
                            "type": "string",
                            "description": "What they said, not a selling price.",
                        },
                        "unknown": {"type": "boolean"},
                    },
                    "required": ["slot", "value_text"],
                },
            },
            {
                "name": "confirm_slot",
                "description": "Call when they said theek hai / haan / yes for the current slot.",
                "parameters": {
                    "type": "object",
                    "properties": {"slot": {"type": "string", "enum": list(SLOT_ORDER)}},
                    "required": ["slot"],
                },
            },
            {
                "name": "repair_slot",
                "description": "Call when they said galat / nahin / wrong. Clears only that slot.",
                "parameters": {
                    "type": "object",
                    "properties": {"slot": {"type": "string", "enum": list(SLOT_ORDER)}},
                    "required": ["slot"],
                },
            },
            {
                "name": "write_copy",
                "description": (
                    "After every slot is confirmed, write bilingual listing copy. "
                    "Never invent a rupee price. The server returns price bands."
                ),
                "parameters": {
                    "type": "object",
                    "properties": {
                        "title_hi": {"type": "string"},
                        "title_en": {"type": "string"},
                        "desc_hi": {"type": "string"},
                        "desc_en": {"type": "string"},
                        "title_local": {"type": "string"},
                        "desc_local": {"type": "string"},
                    },
                    "required": ["title_hi", "title_en", "desc_hi", "desc_en"],
                },
            },
            {
                "name": "approve_listing",
                "description": "Call after they approve the spoken card (theek hai).",
                "parameters": {"type": "object", "properties": {}},
            },
        ]
    }
]


def live_system_instruction(
    *,
    language_code: str,
    cluster: str,
    artisan_name: str = "",
) -> str:
    name = artisan_name or "the artisan"
    lang = language_label(language_code)
    slots = ", ".join(SLOT_ORDER)
    return f"""You are KalaSetu Agent A, a live product cataloger. Not a chatbot. Not a shop.

Interview {name} about ONE physical handmade product.
Speak only in {lang} ({language_code}). Short sentences. One question at a time.
Cluster for labour context: {cluster}.

Slots in this order: {slots}.
hours = labour hours (if they give days, treat 1 day = 8 hours).
gi = yes, no, or unsure.
material_source = own, shop, or trader.
effort = simple, normal, or skilled.
Do not invent. If they don't know, propose_slot with unknown=true.

Workflow:
1. Ask the next missing slot.
2. When they answer, call propose_slot, then SPEAK the reread string from the tool, wait.
3. theek hai / haan / yes → confirm_slot.
4. galat / nahin / they re-say the field → repair_slot (or propose_slot with repair if the tool allows), then ask again. Change ONLY that slot.
5. After all slots, call write_copy. NEVER output a selling price yourself.
6. Speak the card (title + description) and the three price bands the tool returned. Wait.
7. theek hai → approve_listing. Then stop.

Grammar they may use: phir se / peeche = ask again; galat = repair this slot; daam = they will hear prices after costing, you still must not invent daam.
Live answers are free-form, not commands.
"""


def live_connect_config(system_instruction: str) -> dict[str, Any]:
    return {
        "response_modalities": ["AUDIO"],
        "system_instruction": system_instruction,
        "tools": LIVE_TOOLS,
        "speech_config": {
            "voice_config": {
                "prebuilt_voice_config": {"voice_name": "Aoede"},
            }
        },
        "context_window_compression": {
            "trigger_tokens": 10000,
            "sliding_window": {"target_tokens": 4000},
        },
    }


def gemini_live_client(settings: Settings | None = None):
    settings = settings or get_settings()
    if not settings.gemini_api_key:
        raise RuntimeError("GEMINI_API_KEY is missing")
    from google import genai

    return genai.Client(
        api_key=settings.gemini_api_key,
        http_options={"api_version": "v1beta"},
    )


def live_model_name(settings: Settings | None = None) -> str:
    settings = settings or get_settings()
    return settings.gemini_live_model or LIVE_MODEL_DEFAULT


def tool_args(function_call: Any) -> dict[str, Any]:
    args = getattr(function_call, "args", None) or {}
    if hasattr(args, "model_dump"):
        return args.model_dump()
    if isinstance(args, dict):
        return args
    try:
        return dict(args)
    except Exception:
        return {}
