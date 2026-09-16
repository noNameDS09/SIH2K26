"""Agent B — one rule, one sentence, this artisan only.

Ranked rules (first match wins). Empty is allowed. Never generic tips.
"""

from __future__ import annotations

import os
from datetime import datetime, timedelta, timezone
from typing import Any

from kalasetu_api.adapters.firebase import (
    compute_trade_record,
    get_artisan,
    get_public_trends,
    list_artisan_listings,
    list_artisan_sales,
    list_events,
    record_event,
)
from kalasetu_api.adapters.llm.gemini import GeminiError, phrase_advisor_sentence

TEMPLATES: dict[str, dict[str, str]] = {
    "en-IN": {
        "first_publish": "Your first listing is live. Share the QR so buyers can find this piece.",
        "stale_draft": "You have a draft waiting. Finish the photo and price when you can.",
        "underpricing": "Recent sales were below the recommended price. Consider listing closer to ₹{recommended:.0f}.",
        "demand_gap": "Buyers in {cluster} are looking for {rising}. You could add that to a new piece.",
    },
    "hi-IN": {
        "first_publish": "आपकी पहली लिस्टिंग लाइव है। QR शेयर करें ताकि खरीदार इसे ढूँढ सकें।",
        "stale_draft": "एक ड्राफ्ट अधूरा है। जब समय हो, फोटो और दाम पूरा कर दें।",
        "underpricing": "हाल की बिक्री सुझाए दाम से कम रही। ₹{recommended:.0f} के करीब रखने पर सोचें।",
        "demand_gap": "{cluster} में खरीदार {rising} ढूँढ रहे हैं। अगली चीज़ में यह जोड़ सकते हैं।",
    },
    "mr-IN": {
        "first_publish": "तुमची पहिली लिस्टिंग लाइव्ह आहे. QR शेअर करा.",
        "stale_draft": "एक मसुदा अपूर्ण आहे. फोटो आणि किंमत पूर्ण करा.",
        "underpricing": "अलीकडील विक्री सुचवलेल्या किंमतीपेक्षा कमी आहे. ₹{recommended:.0f} जवळ ठेवा.",
        "demand_gap": "{cluster} मध्ये खरेदीदार {rising} शोधत आहेत.",
    },
}


def _parse_iso(value: Any) -> datetime | None:
    if not value:
        return None
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except ValueError:
        return None


def _lang_family(lang: str) -> str:
    code = (lang or "hi-IN").strip()
    if code in TEMPLATES:
        return code
    prefix = code.split("-", 1)[0].lower()
    mapping = {"hi": "hi-IN", "mr": "mr-IN", "en": "en-IN"}
    return mapping.get(prefix, "hi-IN")


def pick_rule(
    *,
    artisan: dict[str, Any],
    listings: list[dict[str, Any]],
    sales: list[dict[str, Any]],
    trends: dict[str, Any] | None,
    events: list[dict[str, Any]],
    now: datetime | None = None,
) -> dict[str, Any] | None:
    now = now or datetime.now(timezone.utc)
    published = [item for item in listings if item.get("status") == "published"]
    drafts = [item for item in listings if item.get("status") != "published"]
    congratulated = any(
        e.get("kind") == "insight.generated"
        and (e.get("payload") or {}).get("rule_id") == "first_publish"
        for e in events
    )

    if len(published) == 1 and not congratulated:
        item = published[0]
        return {
            "rule_id": "first_publish",
            "listing_id": item.get("id"),
            "facts": {"title": item.get("title") or item.get("title_en") or ""},
        }

    cutoff = now - timedelta(hours=24)
    for draft in drafts:
        updated = _parse_iso(draft.get("updatedAt") or draft.get("createdAt"))
        if updated and updated < cutoff:
            return {
                "rule_id": "stale_draft",
                "listing_id": draft.get("id"),
                "facts": {"title": draft.get("title") or draft.get("title_en") or "draft"},
            }

    under = []
    for sale in sales:
        rec = sale.get("recommended")
        amount = sale.get("amount")
        if rec and amount is not None and float(amount) < float(rec) * 0.9:
            under.append(sale)
    if len(under) >= 3:
        rec_val = float(under[0].get("recommended") or 0)
        return {
            "rule_id": "underpricing",
            "listing_id": under[0].get("listingId"),
            "facts": {"recommended": rec_val, "count": len(under)},
        }

    rising = list((trends or {}).get("rising") or [])
    if rising and published:
        seen: set[str] = set()
        for item in published:
            fields = item.get("fields") or {}
            colours = fields.get("colour") or []
            if isinstance(colours, str):
                colours = [colours]
            for colour in colours:
                seen.add(str(colour).lower())
            for tag in item.get("tags") or []:
                seen.add(str(tag).lower())
        missing = [item for item in rising if str(item).lower() not in seen]
        if missing:
            return {
                "rule_id": "demand_gap",
                "listing_id": published[0].get("id"),
                "facts": {
                    "cluster": artisan.get("cluster") or (trends or {}).get("cluster") or "your cluster",
                    "rising": missing[0],
                },
            }
    return None


def _template_sentence(rule: dict[str, Any], lang: str) -> str:
    family = _lang_family(lang)
    template = TEMPLATES.get(family, TEMPLATES["hi-IN"]).get(rule["rule_id"], "")
    try:
        return template.format(**rule.get("facts", {}))
    except (KeyError, ValueError):
        return template


def advise_artisan(uid: str, *, lang: str | None = None, phrase: bool = True, persist: bool = True) -> dict[str, Any]:
    artisan = get_artisan(uid) or {"uid": uid, "lang": "hi-IN", "cluster": "varanasi"}
    listings = list_artisan_listings(uid)
    sales = list_artisan_sales(uid)
    trends = get_public_trends("current")
    events = list_events(uid, kind="insight.generated")
    lang = lang or artisan.get("lang") or "hi-IN"
    rule = pick_rule(
        artisan=artisan,
        listings=listings,
        sales=sales,
        trends=trends,
        events=events,
    )
    now_iso = datetime.now(timezone.utc).isoformat()
    empty_payload = {
        "sentence": "",
        "empty": True,
        "rule_id": None,
        "lang": lang,
        "trade_record": compute_trade_record(uid),
        "provenance": {
            "source": "advisor-rules.v1",
            "version": "1",
            "confidence": 1.0,
            "ts": now_iso,
        },
    }
    if rule is None:
        return empty_payload

    phrased_by = "advisor-templates.v1"
    sentence = _template_sentence(rule, lang)
    allow_gemini = phrase and not os.environ.get("PYTEST_CURRENT_TEST")
    if allow_gemini:
        try:
            sentence = phrase_advisor_sentence(
                rule_id=rule["rule_id"],
                facts=rule.get("facts") or {},
                lang=lang,
            ) or sentence
            phrased_by = "gemini-flash"
        except (GeminiError, Exception):
            pass

    if persist:
        record_event(
            uid=uid,
            listing_id=str(rule.get("listing_id") or ""),
            kind="insight.generated",
            payload={"rule_id": rule["rule_id"], "sentence": sentence},
        )
    return {
        "sentence": sentence,
        "empty": False,
        "rule_id": rule["rule_id"],
        "listing_id": rule.get("listing_id"),
        "lang": lang,
        "trade_record": compute_trade_record(uid),
        "provenance": {
            "source": f"advisor-rules.v1/{rule['rule_id']}",
            "version": "1",
            "confidence": 0.9,
            "ts": now_iso,
            "phrased_by": phrased_by,
        },
    }
