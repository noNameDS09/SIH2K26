from kalasetu_api.engines.pricing import compute_prices


def test_price_uses_seed_wage_not_gemini():
    prices = compute_prices(
        {
            "craft": "saree",
            "material": "silk",
            "hours": 10,
            "material_cost_inr": 1200,
            "effort": "skilled",
            "gi": "yes",
        },
        cluster="varanasi",
    )
    # 1200 + 10 * 85 * 1.5 + 250 = 2725
    assert prices["floor"]["value"] == 2725
    assert prices["recommended"]["value"] >= prices["floor"]["value"]
    assert prices["aspirational"]["value"] >= prices["recommended"]["value"]
    assert prices["floor"]["provenance"]["source"] == "kalasetu-pricing.v1"
