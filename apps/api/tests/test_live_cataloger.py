from kalasetu_api.engines.cataloger import apply_live_tool, start_session


def test_live_propose_confirm_repair_does_not_overwrite_other_slots():
    session = start_session(cluster="varanasi", language_code="mr-IN")
    apply_live_tool(
        session,
        "propose_slot",
        {"slot": "craft", "value_text": "रेशमी साडी"},
    )
    assert session.phase == "confirming"
    apply_live_tool(session, "confirm_slot", {"slot": "craft"})
    assert session.slots["craft"].confirmed is True
    apply_live_tool(
        session,
        "propose_slot",
        {"slot": "material", "value_text": "रेशम"},
    )
    apply_live_tool(session, "confirm_slot", {"slot": "material"})
    blocked = apply_live_tool(
        session,
        "propose_slot",
        {"slot": "craft", "value_text": "brass diya"},
    )
    assert blocked["ok"] is False
    apply_live_tool(session, "repair_slot", {"slot": "material"})
    assert session.slots["material"].confirmed is False
    assert session.slots["craft"].confirmed is True
    assert session.slots["craft"].value


def test_write_copy_sets_prices_from_math_not_model():
    session = start_session(cluster="varanasi", language_code="mr-IN")
    apply_live_tool(
        session, "propose_slot", {"slot": "craft", "value_text": "saree"}
    )
    apply_live_tool(session, "confirm_slot", {"slot": "craft"})
    apply_live_tool(
        session, "propose_slot", {"slot": "hours", "value_text": "10 तास"}
    )
    apply_live_tool(session, "confirm_slot", {"slot": "hours"})
    apply_live_tool(
        session,
        "propose_slot",
        {"slot": "material_cost_inr", "value_text": "1200"},
    )
    apply_live_tool(session, "confirm_slot", {"slot": "material_cost_inr"})
    apply_live_tool(
        session, "propose_slot", {"slot": "effort", "value_text": "skilled"}
    )
    apply_live_tool(session, "confirm_slot", {"slot": "effort"})
    result = apply_live_tool(
        session,
        "write_copy",
        {
            "title_hi": "रेशमी साड़ी",
            "title_en": "Silk saree",
            "desc_hi": "हाथकरघा।",
            "desc_en": "Handloom silk.",
        },
    )
    assert result["ok"] is True
    assert "prices" in result
    assert session.listing["prices"]["floor"]["provenance"]["source"] == "kalasetu-pricing.v1"
    assert session.phase == "approval"
    apply_live_tool(session, "approve_listing", {})
    assert session.phase == "complete"
