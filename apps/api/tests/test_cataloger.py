from kalasetu_api.engines.cataloger import (
    apply_transcript,
    classify_intent,
    listing_table_rows,
    parse_slot,
    start_session,
)


def test_intent_marathi_confirm_reject():
    assert classify_intent("बरोबर") == "confirm"
    assert classify_intent("theek hai") == "confirm"
    assert classify_intent("चुकीचे") == "reject"
    assert classify_intent("galat") == "reject"
    assert classify_intent("माहित नाही") == "unknown"
    assert classify_intent("पुन्हा") == "repeat"


def test_hours_and_cost_parse_without_gemini():
    hours, conf = parse_slot("hours", "३ तास")
    assert hours == 3
    assert conf >= 0.85
    days, _ = parse_slot("hours", "2 दिवस")
    assert days == 16
    cost, _ = parse_slot("material_cost_inr", "साहित्याला १२०० रुपये")
    assert cost == 1200
    assert parse_slot("gi", "हो")[0] == "yes"
    assert parse_slot("material_source", "दुकानातून")[0] == "shop"
    assert parse_slot("effort", "कुशल काम")[0] == "skilled"
    assert parse_slot("extras", "नाही")[0] == {}


def test_re_read_then_galat_repairs_only_that_slot():
    session = start_session(cluster="varanasi")
    session = apply_transcript(session, "हा रेशमी साडी आहे")
    assert session.phase == "confirming"
    assert session.current_slot == "craft"
    assert "साडी" in (session.slots["craft"].raw or "")
    session = apply_transcript(session, "बरोबर")
    assert session.slots["craft"].confirmed is True
    session = apply_transcript(session, "रेशम")
    session = apply_transcript(session, "चुकीचे")
    assert session.slots["craft"].confirmed is True
    assert session.slots["material"].confirmed is False
    assert session.slots["material"].value is None
    assert session.current_slot == "material"


def test_listing_table_has_price_rows(monkeypatch):
    def fake_gemini(_transcripts):
        return {
            "craft": "saree",
            "material": "silk",
            "technique": "handloom",
            "hours": 10,
            "colour": ["red"],
            "occasion": "festival",
            "gi": "no",
            "material_cost_inr": 900,
            "material_source": "shop",
            "effort": "skilled",
            "title_hi": "रेशमी साड़ी",
            "title_en": "Silk saree",
            "title_mr": "रेशमी साडी",
            "desc_hi": "हाथकरघा रेशम।",
            "desc_en": "Handloom silk saree.",
            "desc_mr": "हातमाग रेशमी साडी.",
            "extras": {},
        }

    monkeypatch.setattr(
        "kalasetu_api.adapters.llm.gemini.generate_listing_json",
        fake_gemini,
    )

    answers = {
        "craft": "साडी",
        "material": "रेशम",
        "technique": "हातमाग",
        "hours": "दहा तास",
        "colour": "लाल",
        "occasion": "सण",
        "gi": "नाही",
        "material_cost_inr": "९००",
        "material_source": "दुकान",
        "effort": "कुशल",
        "extras": "नाही",
    }
    session = start_session(cluster="varanasi")
    for _slot, spoken in answers.items():
        session = apply_transcript(session, spoken)
        session = apply_transcript(session, "बरोबर")

    assert session.phase == "complete"
    assert session.listing is not None
    rows = listing_table_rows(session)
    by_field = {row["field"]: row["value"] for row in rows}
    assert by_field["hours"] == 10
    assert by_field["material_cost_inr"] == 900
    assert by_field["price_recommended_inr"]
    assert by_field["title_en"] == "Silk saree"
    assert "Handloom silk" not in str(by_field["craft"])
    assert session.listing["prices"]["floor"]["provenance"]["source"] == "kalasetu-pricing.v1"
