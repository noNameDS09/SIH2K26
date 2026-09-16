"""
One-slot artisan cataloger.

Not a chatbot. Gemini Live (or the turn-based tester) asks one slot,
re-reads it, repairs only that slot on galat, then writes bilingual copy.

Price is math on seed CSVs — Gemini never picks a rupee amount.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any

from kalasetu_api.engines.pricing import compute_prices
from kalasetu_api.engines.languages import SARVAM_LANGUAGES, language_label

LANG_MR = "mr-IN"

SLOT_ORDER = (
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
    "extras",
)

QUESTIONS_MR: dict[str, str] = {
    "craft": "हे कोणते उत्पादन आहे? उदाहरणार्थ साडी, दिवा, दागिना.",
    "material": "हे कशाचे बनवले आहे? साहित्य सांगा.",
    "technique": "कशी बनवली? कोणती कला किंवा तंत्र वापरले?",
    "hours": "किती तास किंवा दिवस लागले?",
    "colour": "मुख्य रंग कोणते?",
    "occasion": "हे कधी वापरतात? सण, लग्न, रोज?",
    "gi": "याला जीआय टॅग आहे का? हो, नाही, किंवा माहित नाही.",
    "material_cost_inr": "साहित्याला किती रुपये लागले?",
    "material_source": "साहित्य स्वतःचे होते, दुकानातून, की व्यापाऱ्याकडून?",
    "effort": "काम सोपे होते, सामान्य, की कुशल?",
    "extras": "आणखी काही सांगायचे आहे का? नाही तर नाही म्हणा.",
}

QUESTIONS_HI: dict[str, str] = {
    "craft": "यह कौन सा उत्पाद है? उदाहरण के लिए साड़ी, दीपक या आभूषण।",
    "material": "यह किस चीज़ से बना है? सामग्री बताइए।",
    "technique": "इसे कैसे बनाया? कौन सी कला या तकनीक इस्तेमाल की?",
    "hours": "इसे बनाने में कितने घंटे या दिन लगे?",
    "colour": "मुख्य रंग कौन से हैं?",
    "occasion": "इसे कब इस्तेमाल करते हैं—त्योहार, शादी या रोज़मर्रा में?",
    "gi": "क्या इसे जीआई टैग मिला है? हाँ, नहीं या पता नहीं।",
    "material_cost_inr": "सामग्री पर कितने रुपये खर्च हुए?",
    "material_source": "सामग्री अपनी थी, दुकान से ली या व्यापारी से?",
    "effort": "काम आसान, सामान्य या कुशल कारीगरी वाला था?",
    "extras": "और कुछ बताना चाहते हैं? नहीं हो तो नहीं कहें।",
}

QUESTIONS_EN: dict[str, str] = {
    "craft": "What is this product called? For example, a saree, lamp, or piece of jewellery.",
    "material": "What is it made from? Please tell us the material.",
    "technique": "How did you make it? Which craft or technique did you use?",
    "hours": "How many hours or days did it take to make?",
    "colour": "What are the main colours?",
    "occasion": "When do people use it—for festivals, weddings, or everyday use?",
    "gi": "Does it have a GI tag? Say yes, no, or I do not know.",
    "material_cost_inr": "How many rupees did you spend on the materials?",
    "material_source": "Were the materials your own, bought from a shop, or bought from a trader?",
    "effort": "Was the work simple, regular, or skilled?",
    "extras": "Is there anything else buyers should know? Say no if not.",
}

QUESTIONS_BY_LANGUAGE = {"hi-IN": QUESTIONS_HI, "en-IN": QUESTIONS_EN, "mr-IN": QUESTIONS_MR}

LABELS_MR: dict[str, str] = {
    "craft": "उत्पादन",
    "material": "साहित्य",
    "technique": "तंत्र",
    "hours": "तास",
    "colour": "रंग",
    "occasion": "प्रसंग",
    "gi": "जीआय",
    "material_cost_inr": "साहित्य खर्च",
    "material_source": "साहित्य स्रोत",
    "effort": "कष्ट",
    "extras": "अधिक",
}

LABELS_BY_LANGUAGE = {
    "hi-IN": {
        "craft": "उत्पाद", "material": "सामग्री", "technique": "तकनीक", "hours": "समय",
        "colour": "रंग", "occasion": "अवसर", "gi": "जीआई", "material_cost_inr": "सामग्री खर्च",
        "material_source": "सामग्री स्रोत", "effort": "मेहनत", "extras": "अन्य",
    },
    "en-IN": {
        "craft": "Product", "material": "Material", "technique": "Technique", "hours": "Time",
        "colour": "Colours", "occasion": "Occasion", "gi": "GI tag", "material_cost_inr": "Material cost",
        "material_source": "Material source", "effort": "Effort", "extras": "Other",
    },
    "mr-IN": LABELS_MR,
}

_DEV_DIGITS = str.maketrans("०१२३४५६७८९", "0123456789")
_WORD_NUMBERS = {
    "एक": 1,
    "दोन": 2,
    "तीन": 3,
    "चार": 4,
    "पाच": 5,
    "सहा": 6,
    "सात": 7,
    "आठ": 8,
    "नऊ": 9,
    "दहा": 10,
    "अकरा": 11,
    "बारा": 12,
    "पंधरा": 15,
    "वीस": 20,
    "तीस": 30,
    "चाळीस": 40,
    "पन्नास": 50,
    "शंभर": 100,
    "one": 1,
    "two": 2,
    "three": 3,
    "four": 4,
    "five": 5,
    "six": 6,
    "seven": 7,
    "eight": 8,
    "nine": 9,
    "ten": 10,
}

_CONFIRM = (
    "theek",
    "theek hai",
    "haan",
    "ha",
    "yes",
    "ok",
    "okay",
    "correct",
    "ठीक",
    "ठीक आहे",
    "हो",
    "होय",
    "हाँ",
    "हां",
    "बरोबर",
    "बरोबर आहे",
    "सही",
)
_REJECT = (
    "galat",
    "nahin",
    "nahi",
    "no",
    "wrong",
    "गलत",
    "चुकीचे",
    "चुकीचं",
    "नाही",
    "नको",
    "वेरं",
)
_REPEAT = ("phir se", "peeche", "repeat", "again", "परत", "पुन्हा", "पुन्हा सांगा")
_DONT_KNOW = (
    "unknown",
    "don't know",
    "dont know",
    "not sure",
    "माहित नाही",
    "नकळे",
    "पता नहीं",
    "कळत नाही",
    "समजत नाही",
)
_NO_EXTRAS = ("नाही", "नको", "काही नाही", "nothing", "no", "nahi")


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _fold(text: str) -> str:
    return re.sub(r"\s+", " ", (text or "").strip().lower())


def question_for(language_code: str, slot: str) -> str:
    questions = QUESTIONS_BY_LANGUAGE.get(language_code, QUESTIONS_MR)
    return questions.get(slot, questions["extras"])


def label_for(language_code: str, slot: str) -> str:
    labels = LABELS_BY_LANGUAGE.get(language_code, LABELS_MR)
    return labels.get(slot, slot)


def _provenance(source: str, confidence: float, version: str = "1") -> dict[str, Any]:
    return {
        "source": source,
        "version": version,
        "confidence": confidence,
        "ts": _now_iso(),
    }


def classify_intent(transcript: str) -> str:
    folded = _fold(transcript)
    if not folded:
        return "empty"
    if any(token == folded or folded.startswith(f"{token} ") for token in _REPEAT):
        return "repeat"
    if any(token == folded for token in _DONT_KNOW) or folded in {"माहित नाही", "कळत नाही"}:
        return "unknown"
    if folded in {token.lower() for token in _REJECT} or folded in {"galat hai", "चुकीचे आहे"}:
        return "reject"
    if folded in {token.lower() for token in _CONFIRM} or folded in {"theek hai", "haan ji"}:
        return "confirm"
    # short confirm/reject contained as the whole utterance
    compact = folded.replace(".", "").replace(",", "")
    if compact in {token.lower() for token in _CONFIRM}:
        return "confirm"
    if compact in {token.lower() for token in _REJECT}:
        return "reject"
    if compact in {token.lower() for token in _DONT_KNOW}:
        return "unknown"
    return "answer"


def _first_number(text: str) -> float | None:
    translated = text.translate(_DEV_DIGITS)
    folded = _fold(translated)
    match = re.search(r"(\d+(?:\.\d+)?)", folded)
    if match:
        return float(match.group(1))
    for word, value in _WORD_NUMBERS.items():
        if re.search(rf"(^|\s){re.escape(word)}(\s|$)", folded):
            return float(value)
    return None


def parse_slot(slot: str, transcript: str) -> tuple[Any, float]:
    """Cheap local parse. Gemini only refines once at the end."""
    folded = _fold(transcript.translate(_DEV_DIGITS))
    if slot == "hours":
        number = _first_number(transcript)
        if number is None:
            return transcript.strip(), 0.4
        if any(token in folded for token in ("दिवस", "day", "days")):
            return number * 8, 0.85
        return number, 0.9
    if slot == "material_cost_inr":
        number = _first_number(transcript)
        if number is None:
            return None, 0.3
        return int(round(number)), 0.9
    if slot == "gi":
        if any(token in folded for token in ("unsure", "माहित नाही", "कळत नाही", "पता नहीं")):
            return "unsure", 0.8
        if any(token in folded for token in ("नाही", "नको", "no", "नहीं")):
            return "no", 0.85
        if any(token in folded for token in ("हो", "होय", "yes", "haan", "आहे")):
            return "yes", 0.85
        return "unsure", 0.4
    if slot == "material_source":
        if any(token in folded for token in ("व्यापारी", "trader", "मंडी")):
            return "trader", 0.85
        if any(token in folded for token in ("दुकान", "shop")):
            return "shop", 0.85
        if any(token in folded for token in ("स्वतः", "स्वत:", "own", "घर")):
            return "own", 0.85
        return transcript.strip(), 0.4
    if slot == "effort":
        if any(token in folded for token in ("कुशल", "skilled", "कठीण")):
            return "skilled", 0.85
        if any(token in folded for token in ("सोपे", "simple", "easy")):
            return "simple", 0.85
        if any(token in folded for token in ("सामान्य", "normal")):
            return "normal", 0.85
        return "normal", 0.4
    if slot == "colour":
        parts = re.split(r",| आणि | और | and ", transcript.strip())
        colours = [part.strip() for part in parts if part.strip()]
        return colours, 0.7 if colours else 0.3
    if slot == "extras":
        if folded in {token.lower() for token in _NO_EXTRAS} or folded in {"काही नाही", "नको"}:
            return {}, 0.9
        return {"note": transcript.strip()}, 0.7
    return transcript.strip(), 0.7


def display_value(value: Any) -> str:
    if value is None or value == "":
        return "माहित नाही"
    if value == {}:
        return "नाही"
    if isinstance(value, list):
        return ", ".join(str(item) for item in value)
    return str(value)


def reread_line(slot: str, value: Any, language_code: str = LANG_MR) -> str:
    if language_code == "en-IN":
        return f"{label_for(language_code, slot)}: {display_value(value)}. Is that correct?"
    if language_code == "hi-IN":
        return f"{label_for(language_code, slot)}: {display_value(value)}। क्या यह सही है?"
    return f"{label_for(language_code, slot)}: {display_value(value)}. बरोबर आहे का?"


@dataclass
class SlotState:
    raw: str | None = None
    value: Any = None
    confirmed: bool = False
    provenance: dict[str, Any] | None = None

    def to_dict(self) -> dict[str, Any]:
        return {
            "raw": self.raw,
            "value": self.value,
            "confirmed": self.confirmed,
            "provenance": self.provenance,
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any] | None) -> "SlotState":
        data = data or {}
        return cls(
            raw=data.get("raw"),
            value=data.get("value"),
            confirmed=bool(data.get("confirmed")),
            provenance=data.get("provenance"),
        )


@dataclass
class CatalogerSession:
    language_code: str = LANG_MR
    cluster: str = "varanasi"
    phase: str = "interviewing"
    current_slot: str = "craft"
    slots: dict[str, SlotState] = field(default_factory=dict)
    question: str = QUESTIONS_MR["craft"]
    reread: str | None = None
    speak: str = QUESTIONS_MR["craft"]
    listing: dict[str, Any] | None = None
    error: str | None = None
    artisan_name: str = ""
    photo_attached: bool = False

    def __post_init__(self) -> None:
        for name in SLOT_ORDER:
            self.slots.setdefault(name, SlotState())

    def to_dict(self) -> dict[str, Any]:
        return {
            "language_code": self.language_code,
            "cluster": self.cluster,
            "phase": self.phase,
            "current_slot": self.current_slot,
            "slots": {name: state.to_dict() for name, state in self.slots.items()},
            "question": self.question,
            "reread": self.reread,
            "speak": self.speak,
            "listing": self.listing,
            "error": self.error,
            "artisan_name": self.artisan_name,
            "photo_attached": self.photo_attached,
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any] | None) -> "CatalogerSession":
        data = data or {}
        session = cls(
            language_code=data.get("language_code") or LANG_MR,
            cluster=data.get("cluster") or "varanasi",
            phase=data.get("phase") or "interviewing",
            current_slot=data.get("current_slot") or "craft",
            question=data.get("question") or question_for(data.get("language_code") or LANG_MR, "craft"),
            reread=data.get("reread"),
            speak=data.get("speak") or question_for(data.get("language_code") or LANG_MR, "craft"),
            listing=data.get("listing"),
            error=data.get("error"),
            artisan_name=data.get("artisan_name") or "",
            photo_attached=bool(data.get("photo_attached")),
        )
        raw_slots = data.get("slots") or {}
        for name in SLOT_ORDER:
            session.slots[name] = SlotState.from_dict(raw_slots.get(name))
        return session


def start_session(
    *,
    cluster: str = "varanasi",
    language_code: str = LANG_MR,
    artisan_name: str = "",
    photo_attached: bool = False,
) -> CatalogerSession:
    question = question_for(language_code, "craft")
    return CatalogerSession(
        language_code=language_code,
        cluster=cluster,
        phase="interviewing",
        current_slot="craft",
        question=question,
        speak=question,
        artisan_name=artisan_name,
        photo_attached=photo_attached,
    )


def _next_unconfirmed(session: CatalogerSession) -> str | None:
    for name in SLOT_ORDER:
        if not session.slots[name].confirmed:
            return name
    return None


def _capture(session: CatalogerSession, slot: str, transcript: str, *, unknown: bool = False) -> None:
    state = session.slots[slot]
    state.raw = transcript.strip() or None
    if unknown:
        state.value = None if slot != "colour" else []
        if slot == "extras":
            state.value = {}
        if slot == "gi":
            state.value = "unsure"
        state.provenance = _provenance("sarvam-saaras-v3", 0.35)
    else:
        value, confidence = parse_slot(slot, transcript)
        state.value = value
        state.provenance = _provenance("kalasetu-cataloger.v1", confidence)
    state.confirmed = False
    session.current_slot = slot
    session.phase = "confirming"
    session.reread = reread_line(slot, state.value, session.language_code)
    session.speak = session.reread
    session.question = question_for(session.language_code, slot)


def _ask(session: CatalogerSession, slot: str) -> None:
    session.current_slot = slot
    session.phase = "interviewing"
    session.question = question_for(session.language_code, slot)
    session.reread = None
    session.speak = session.question


def _advance(session: CatalogerSession) -> None:
    nxt = _next_unconfirmed(session)
    if nxt is None:
        session.phase = "copy"
        session.speak = {
            "en-IN": "I have all the details. I am preparing your listing.",
            "hi-IN": "सारी जानकारी मिल गई है। आपकी लिस्टिंग तैयार कर रहा हूँ।",
            "mr-IN": "सगळी माहिती मिळाली. लिस्टिंग तयार करतो.",
        }.get(session.language_code, "I have all the details. I am preparing your listing.")
        session.question = session.speak
        return
    _ask(session, nxt)


def _finalize(session: CatalogerSession) -> CatalogerSession:
    transcripts = {
        name: {"raw": state.raw, "parsed": state.value, "confirmed": state.confirmed}
        for name, state in session.slots.items()
    }
    generated: dict[str, Any] | None = None
    try:
        from kalasetu_api.adapters.llm.gemini import generate_listing_json

        try:
            generated = generate_listing_json(transcripts, target_language=session.language_code)
        except TypeError:
            # Handle mock test functions that only take one parameter (transcripts)
            generated = generate_listing_json(transcripts)
        source = "gemini-flash-catalog.v1"
        confidence = 0.8
    except Exception as exc:  # noqa: BLE001 — tester must still show parsed slots
        session.error = f"Gemini listing copy failed: {exc}"
        generated = None
        source = "kalasetu-cataloger.v1"
        confidence = 0.55

    fields: dict[str, Any] = {}
    for name in SLOT_ORDER:
        parsed = session.slots[name].value
        local_conf = float((session.slots[name].provenance or {}).get("confidence") or 0)
        if parsed not in (None, "", []) and local_conf >= 0.85:
            fields[name] = parsed
        elif generated and generated.get(name) not in (None, "", []):
            fields[name] = generated[name]
        else:
            fields[name] = parsed
        session.slots[name].confirmed = True

    copy_keys = ("title_hi", "title_en", "title_mr", "title_local", "desc_hi", "desc_en", "desc_mr", "desc_local")
    copy = {key: (generated or {}).get(key) or "" for key in copy_keys}
    extras = fields.get("extras") if isinstance(fields.get("extras"), dict) else {}
    if copy["title_mr"]:
        extras = {**extras, "title_mr": copy["title_mr"], "desc_mr": copy["desc_mr"]}
    if copy["title_local"]:
        extras = {**extras, "title_local": copy["title_local"], "desc_local": copy["desc_local"]}
    fields["extras"] = extras

    prices = compute_prices(fields, cluster=session.cluster)
    listing = {
        # Persist user-facing values as plain fields. Provenance stays beside
        # them so pricing, review, and export can consume the same shape.
        "fields": fields,
        "provenance": [
            {"field": key, **(session.slots.get(key, SlotState()).provenance or _provenance(source, confidence))}
            for key in SLOT_ORDER
        ],
        "title_hi": copy["title_hi"],
        "title_en": copy["title_en"],
        "desc_hi": copy["desc_hi"],
        "desc_en": copy["desc_en"],
        "title_local": copy["title_local"] or copy["title_en"],
        "desc_local": copy["desc_local"] or copy["desc_en"],
        "prices": prices,
        "cluster": session.cluster,
        "language_code": session.language_code,
    }
    session.listing = listing
    session.phase = "complete"
    read_title = copy["title_local"] or copy["title_mr"] or copy["title_hi"] or display_value(fields.get("craft"))
    read_desc = copy["desc_local"] or copy["desc_mr"] or copy["desc_hi"]
    session.speak = f"{read_title}. {read_desc}".strip()
    session.question = {
        "en-IN": "Your listing is ready.",
        "hi-IN": "आपकी लिस्टिंग तैयार है।",
        "mr-IN": "लिस्टिंग तयार आहे.",
    }.get(session.language_code, "Your listing is ready.")
    session.reread = session.speak
    return session


def apply_transcript(
    session: CatalogerSession,
    transcript: str,
    *,
    auto_advance: bool = False,
) -> CatalogerSession:
    session.error = None
    intent = classify_intent(transcript)
    slot = session.current_slot

    if session.phase == "complete":
        session.speak = session.reread or session.question
        return session

    if session.phase == "copy":
        return _finalize(session)

    if intent == "empty":
        session.speak = session.question
        return session

    if session.phase == "confirming":
        if intent == "confirm":
            session.slots[slot].confirmed = True
            _advance(session)
            if session.phase == "copy":
                return _finalize(session)
            return session
        if intent == "reject" or intent == "repeat":
            session.slots[slot] = SlotState()
            _ask(session, slot)
            return session
        if intent == "unknown":
            _capture(session, slot, transcript, unknown=True)
            session.slots[slot].confirmed = True
            _advance(session)
            if session.phase == "copy":
                return _finalize(session)
            return session
        # Re-said the field: repair only this slot.
        _capture(session, slot, transcript)
        return session

    # Interviewing is deliberately one question -> one field. The UI does not
    # expose a second confirmation recording, so accepting here prevents the
    # next answer from being written back into the previous slot.
    if intent == "repeat":
        session.speak = session.question
        return session
    if intent == "unknown":
        _capture(session, slot, transcript, unknown=True)
        if auto_advance:
            session.slots[slot].confirmed = True
            _advance(session)
            if session.phase == "copy":
                return _finalize(session)
        return session
    _capture(session, slot, transcript)
    if auto_advance:
        session.slots[slot].confirmed = True
        _advance(session)
        if session.phase == "copy":
            return _finalize(session)
    return session


def confirm_current(session: CatalogerSession) -> CatalogerSession:
    return apply_transcript(session, "बरोबर")


def reject_current(session: CatalogerSession) -> CatalogerSession:
    return apply_transcript(session, "चुकीचे")


def listing_table_rows(session: CatalogerSession) -> list[dict[str, Any]]:
    """Flat rows for the Streamlit / app table — values, not spoken sentences."""
    rows: list[dict[str, Any]] = []
    listing = session.listing or {}
    field_map = listing.get("fields") or {
        name: {"value": state.value, "provenance": state.provenance}
        for name, state in session.slots.items()
        if state.raw is not None or state.value is not None
    }
    for name, payload in field_map.items():
        value = payload.get("value") if isinstance(payload, dict) else payload
        prov = payload.get("provenance") if isinstance(payload, dict) else None
        if name == "colour" and isinstance(value, list):
            shown = ", ".join(value)
        elif name == "extras" and isinstance(value, dict):
            extras = {
                key: item
                for key, item in value.items()
                if key not in {"title_mr", "desc_mr"}
            }
            shown = extras or None
        else:
            shown = value
        rows.append(
            {
                "field": name,
                "value": shown,
                "raw_transcript": session.slots.get(name, SlotState()).raw,
                "source": (prov or {}).get("source"),
                "confidence": (prov or {}).get("confidence"),
            }
        )
    for key in ("title_hi", "title_en", "desc_hi", "desc_en"):
        payload = listing.get(key) or {}
        rows.append(
            {
                "field": key,
                "value": payload.get("value") if isinstance(payload, dict) else payload,
                "raw_transcript": None,
                "source": (payload.get("provenance") or {}).get("source")
                if isinstance(payload, dict)
                else None,
                "confidence": (payload.get("provenance") or {}).get("confidence")
                if isinstance(payload, dict)
                else None,
            }
        )
    extras = (listing.get("fields") or {}).get("extras") or {}
    extra_val = extras.get("value") if isinstance(extras, dict) else extras
    if isinstance(extra_val, dict):
        if extra_val.get("title_mr"):
            rows.append(
                {
                    "field": "title_mr",
                    "value": extra_val.get("title_mr"),
                    "raw_transcript": None,
                    "source": "gemini-flash-catalog.v1",
                    "confidence": 0.8,
                }
            )
        if extra_val.get("desc_mr"):
            rows.append(
                {
                    "field": "desc_mr",
                    "value": extra_val.get("desc_mr"),
                    "raw_transcript": None,
                    "source": "gemini-flash-catalog.v1",
                    "confidence": 0.8,
                }
            )
    prices = listing.get("prices") or {}
    for band in ("floor", "recommended", "aspirational", "listed"):
        payload = prices.get(band) or {}
        rows.append(
            {
                "field": f"price_{band}_inr",
                "value": payload.get("value"),
                "raw_transcript": None,
                "source": (payload.get("provenance") or {}).get("source"),
                "confidence": (payload.get("provenance") or {}).get("confidence"),
            }
        )
    rows.append(
        {
            "field": "cluster",
            "value": session.cluster,
            "raw_transcript": None,
            "source": "tester",
            "confidence": 1.0,
        }
    )
    rows.append(
        {
            "field": "language_code",
            "value": session.language_code,
            "raw_transcript": None,
            "source": "tester",
            "confidence": 1.0,
        }
    )
    rows.append(
        {
            "field": "artisan_name",
            "value": session.artisan_name or None,
            "raw_transcript": None,
            "source": "onboarding",
            "confidence": 1.0,
        }
    )
    rows.append(
        {
            "field": "photo_attached",
            "value": session.photo_attached,
            "raw_transcript": None,
            "source": "capture",
            "confidence": 1.0,
        }
    )
    return rows


def session_field_values(session: CatalogerSession) -> dict[str, Any]:
    """Return the current interview values in the persistence shape."""
    return {
        name: state.value
        for name, state in session.slots.items()
        if state.value not in (None, "", [])
    }


def _coerce_live_value(slot: str, value_text: str, unknown: bool) -> tuple[Any, float]:
    if unknown or not (value_text or "").strip():
        if slot == "colour":
            return [], 0.35
        if slot == "extras":
            return {}, 0.35
        if slot == "gi":
            return "unsure", 0.35
        return None, 0.35
    return parse_slot(slot, value_text)


def apply_live_tool(session: CatalogerSession, name: str, args: dict[str, Any] | None) -> dict[str, Any]:
    """Handle Gemini Live function calls. Price is never taken from the model."""
    args = args or {}
    if name == "propose_slot":
        slot = str(args.get("slot") or session.current_slot)
        if slot not in SLOT_ORDER:
            return {"ok": False, "error": f"unknown slot {slot}"}
        if session.slots[slot].confirmed and not args.get("repair"):
            return {
                "ok": False,
                "error": "slot already confirmed; call repair_slot first",
                "confirmed": True,
            }
        unknown = bool(args.get("unknown"))
        value, confidence = _coerce_live_value(slot, str(args.get("value_text") or ""), unknown)
        state = session.slots[slot]
        state.raw = str(args.get("value_text") or "").strip() or None
        state.value = value
        state.confirmed = False
        state.provenance = _provenance("gemini-live-catalog.v1", confidence)
        session.current_slot = slot
        session.phase = "confirming"
        session.reread = reread_line(slot, state.value, session.language_code)
        session.speak = session.reread
        session.question = question_for(session.language_code, slot)
        return {
            "ok": True,
            "slot": slot,
            "value": state.value,
            "reread": session.reread,
            "instruction": "Speak the reread line, then wait for theek hai / galat.",
        }
    if name == "confirm_slot":
        slot = str(args.get("slot") or session.current_slot)
        if slot not in SLOT_ORDER:
            return {"ok": False, "error": f"unknown slot {slot}"}
        session.slots[slot].confirmed = True
        session.current_slot = slot
        _advance(session)
        if session.phase == "copy":
            return {
                "ok": True,
                "all_slots_confirmed": True,
                "instruction": "Call write_copy now with bilingual titles and descriptions. Do not invent a price.",
            }
        return {
            "ok": True,
            "next_slot": session.current_slot,
            "ask": session.question,
            "instruction": "Ask only the next_slot question in the artisan's language.",
        }
    if name == "repair_slot":
        slot = str(args.get("slot") or session.current_slot)
        if slot not in SLOT_ORDER:
            return {"ok": False, "error": f"unknown slot {slot}"}
        session.slots[slot] = SlotState()
        _ask(session, slot)
        return {
            "ok": True,
            "slot": slot,
            "ask": session.question,
            "instruction": "Ask this slot again. Do not keep the old value.",
        }
    if name == "write_copy":
        return _apply_write_copy(session, args)
    if name == "approve_listing":
        if session.listing is None:
            return {"ok": False, "error": "write_copy first"}
        session.phase = "complete"
        return {"ok": True, "done": True, "instruction": "Stop interviewing. Listing is approved."}
    return {"ok": False, "error": f"unknown tool {name}"}


def _apply_write_copy(session: CatalogerSession, copy: dict[str, Any]) -> dict[str, Any]:
    source = "gemini-live-catalog.v1"
    confidence = 0.85
    fields: dict[str, Any] = {}
    for name in SLOT_ORDER:
        fields[name] = session.slots[name].value
        session.slots[name].confirmed = True
        if session.slots[name].provenance is None:
            session.slots[name].provenance = _provenance(source, 0.5)
    extras = fields.get("extras") if isinstance(fields.get("extras"), dict) else {}
    title_local = (copy.get("title_local") or "").strip()
    desc_local = (copy.get("desc_local") or "").strip()
    if title_local:
        extras = {**extras, "title_local": title_local, "desc_local": desc_local}
    fields["extras"] = extras
    prices = compute_prices(fields, cluster=session.cluster)
    listing = {
        "fields": fields,
        "provenance": [
            {"field": key, **(session.slots[key].provenance or _provenance(source, confidence))}
            for key in SLOT_ORDER
        ],
        "title_hi": copy.get("title_hi") or "",
        "title_en": copy.get("title_en") or "",
        "desc_hi": copy.get("desc_hi") or "",
        "desc_en": copy.get("desc_en") or "",
        "title_local": title_local or copy.get("title_en") or "",
        "desc_local": desc_local or copy.get("desc_en") or "",
        "prices": prices,
        "cluster": session.cluster,
        "language_code": session.language_code,
    }
    session.listing = listing
    session.phase = "approval"
    read_title = title_local or copy.get("title_hi") or display_value(fields.get("craft"))
    read_desc = desc_local or copy.get("desc_hi") or ""
    session.speak = f"{read_title}. {read_desc}".strip()
    session.reread = session.speak
    session.question = "Hear the card. theek hai to approve, galat to repair copy."
    return {
        "ok": True,
        "prices": {
            band: payload.get("value")
            for band, payload in prices.items()
        },
        "card_text": session.speak,
        "instruction": (
            "Read title and description aloud. Also say the three price bands from this tool "
            "response (floor, recommended, aspirational). Do not change those numbers. "
            "Wait for theek hai, then call approve_listing."
        ),
    }
