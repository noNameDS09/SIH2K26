"""Agent C — anonymised cluster trend aggregation.

Clients only read public_trends/current. This job writes it.
If n < 20, seed: true and rising colours come from seed/cluster_seed.json.
"""

from __future__ import annotations

import json
from collections import Counter
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

from kalasetu_api.adapters.firebase import (
    list_all_sales,
    list_published_market_items,
    save_public_trends,
)

_REPO_ROOT = Path(__file__).resolve().parents[5]
_SEED_PATH = _REPO_ROOT / "seed" / "cluster_seed.json"


def load_cluster_seed() -> dict[str, Any]:
    if _SEED_PATH.is_file():
        return json.loads(_SEED_PATH.read_text(encoding="utf-8"))
    return {
        "craft": "saree",
        "cluster": "varanasi",
        "rising": ["maroon", "zari"],
        "n": 0,
        "seed": True,
    }


def _parse_iso(value: Any) -> datetime | None:
    if not value:
        return None
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except ValueError:
        return None


def _colours_from(item: dict[str, Any]) -> list[str]:
    fields = item.get("fields") or {}
    colours = fields.get("colour") or item.get("colour") or []
    if isinstance(colours, str):
        colours = [colours]
    return [str(c).strip().lower() for c in colours if str(c).strip()]


def recompute_public_trends(*, window_days: int = 30) -> dict[str, Any]:
    now = datetime.now(timezone.utc)
    cutoff = now - timedelta(days=window_days)
    sales = list_all_sales()
    recent_sales = []
    for sale in sales:
        ts = _parse_iso(sale.get("confirmedAt"))
        if ts is None or ts >= cutoff:
            recent_sales.append(sale)

    observations: list[dict[str, Any]] = []
    colour_counter: Counter[str] = Counter()
    craft_counter: Counter[str] = Counter()
    cluster_counter: Counter[str] = Counter()

    source_rows = recent_sales
    used_listings = False
    if not source_rows:
        used_listings = True
        for item in list_published_market_items():
            ts = _parse_iso(item.get("updatedAt") or item.get("signedAt") or item.get("signed_at"))
            if ts is not None and ts < cutoff:
                continue
            source_rows.append(item)

    for row in source_rows:
        craft = str(row.get("craft") or (row.get("fields") or {}).get("craft") or "").lower()
        cluster = str(row.get("cluster") or "varanasi").lower()
        if craft:
            craft_counter[craft] += 1
        if cluster:
            cluster_counter[cluster] += 1
        for colour in _colours_from(row):
            colour_counter[colour] += 1
        observations.append(row)

    n = len(observations)
    seed = load_cluster_seed()
    seeded = n < 20
    rising = [name for name, _ in colour_counter.most_common(3)]
    if seeded:
        seed_rising = [str(item).lower() for item in seed.get("rising") or []]
        merged: list[str] = []
        for item in seed_rising + rising:
            if item and item not in merged:
                merged.append(item)
        rising = merged[:4]

    top_craft = craft_counter.most_common(1)[0][0] if craft_counter else seed.get("craft", "saree")
    top_cluster = cluster_counter.most_common(1)[0][0] if cluster_counter else seed.get("cluster", "varanasi")
    now_iso = now.isoformat()
    payload = {
        "craft": top_craft,
        "cluster": top_cluster,
        "rising": rising,
        "n": n,
        "seed": seeded,
        "window": "current",
        "window_days": window_days,
        "source_rows": "listings" if used_listings else "sales",
        "updatedAt": now_iso,
        "provenance": {
            "source": "trend-agg.v1",
            "version": "1",
            "confidence": 0.7 if seeded else 0.9,
            "ts": now_iso,
        },
    }
    if seeded:
        payload["seed_label"] = "Seed — n under 20"
        payload["seed_cluster"] = seed.get("cluster")
        payload["seed_craft"] = seed.get("craft")
    return save_public_trends(payload, window_id="current")
