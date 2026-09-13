"""Listing price bands from fields + seed CSVs. Gemini never sets the price."""

from __future__ import annotations

import csv
from datetime import datetime, timezone
from functools import lru_cache
from pathlib import Path
from typing import Any

_REPO_ROOT = Path(__file__).resolve().parents[5]
_SEED = _REPO_ROOT / "seed"

EFFORT_FACTOR = {"simple": 1.0, "normal": 1.2, "skilled": 1.5}
OVERHEAD_INR = 250.0
DEFAULT_WAGE = 180.0
DEFAULT_MATERIAL_COST = 1000.0
DEFAULT_HOURS = 8.0


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def price_provenance() -> dict[str, Any]:
    return {
        "source": "kalasetu-pricing.v1",
        "version": "1",
        "confidence": 0.91,
        "ts": _now_iso(),
    }


def _norm(value: Any) -> str:
    return str(value or "").strip().lower()


@lru_cache
def _wages() -> list[dict[str, str]]:
    path = _SEED / "wages.csv"
    if not path.is_file():
        return []
    with path.open(encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


@lru_cache
def _materials() -> list[dict[str, str]]:
    path = _SEED / "materials.csv"
    if not path.is_file():
        return []
    with path.open(encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


@lru_cache
def _comparables() -> list[dict[str, str]]:
    path = _SEED / "comparables.csv"
    if not path.is_file():
        return []
    with path.open(encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def available_clusters() -> list[str]:
    names = sorted({row.get("cluster") or "" for row in _wages() if row.get("cluster")})
    return names or ["varanasi"]


def cluster_wage(cluster: str | None, craft: str | None) -> float:
    cluster_n = _norm(cluster)
    craft_n = _norm(craft)
    rows = _wages()
    for row in rows:
        if _norm(row.get("cluster")) == cluster_n and (
            _norm(row.get("craft")) == craft_n or _norm(row.get("craft")) in craft_n
        ):
            return float(row["wage_inr_per_hour"])
    for row in rows:
        if _norm(row.get("craft")) and _norm(row.get("craft")) in craft_n:
            return float(row["wage_inr_per_hour"])
    for row in rows:
        if cluster_n and _norm(row.get("cluster")) == cluster_n:
            return float(row["wage_inr_per_hour"])
    return DEFAULT_WAGE


def typical_material_cost(craft: str | None, material: str | None) -> float | None:
    craft_n = _norm(craft)
    material_n = _norm(material)
    for row in _materials():
        if _norm(row.get("craft")) in craft_n and _norm(row.get("material")) in material_n:
            return float(row["typical_cost_inr"])
    for row in _materials():
        if _norm(row.get("material")) and _norm(row.get("material")) in material_n:
            return float(row["typical_cost_inr"])
    return None


def comparable_band(craft: str | None, cluster: str | None) -> dict[str, float] | None:
    craft_n = _norm(craft)
    cluster_n = _norm(cluster)
    for row in _comparables():
        if _norm(row.get("craft")) in craft_n and (
            not cluster_n or _norm(row.get("cluster")) == cluster_n
        ):
            return {
                "band_low": float(row["band_low_inr"]),
                "band_high": float(row["band_high_inr"]),
                "gi_premium": float(row.get("gi_premium") or 0),
            }
    for row in _comparables():
        if _norm(row.get("craft")) and _norm(row.get("craft")) in craft_n:
            return {
                "band_low": float(row["band_low_inr"]),
                "band_high": float(row["band_high_inr"]),
                "gi_premium": float(row.get("gi_premium") or 0),
            }
    return None


def compute_prices(
    fields: dict[str, Any],
    *,
    cluster: str | None = None,
    listed: float | None = None,
) -> dict[str, Any]:
    """floor / recommended / aspirational. listed is an override if provided."""
    craft = fields.get("craft")
    material = fields.get("material")
    raw_cost = fields.get("material_cost_inr")
    if raw_cost in (None, "", "unknown"):
        material_cost = typical_material_cost(craft, material) or DEFAULT_MATERIAL_COST
    else:
        material_cost = float(raw_cost)
    hours = float(fields.get("hours") or DEFAULT_HOURS)
    wage = cluster_wage(cluster, craft)
    effort_factor = EFFORT_FACTOR.get(_norm(fields.get("effort")) or "normal", 1.2)
    floor = material_cost + (hours * wage * effort_factor) + OVERHEAD_INR
    band = comparable_band(craft, cluster)
    gi = _norm(fields.get("gi"))
    if band:
        recommended = min(max(floor * 1.4, band["band_low"]), band["band_high"])
        gi_premium = band["gi_premium"] if gi == "yes" else 0.0
        aspirational = band["band_high"] * (1 + gi_premium)
    else:
        recommended = max(floor * 1.4, 1800.0)
        aspirational = max(recommended * 1.25, 2800.0)
    listed_value = listed if listed is not None else recommended
    prov = price_provenance()
    return {
        "floor": {"value": round(floor), "provenance": prov},
        "recommended": {"value": round(recommended), "provenance": prov},
        "aspirational": {"value": round(aspirational), "provenance": prov},
        "listed": {"value": round(listed_value), "provenance": prov},
    }
