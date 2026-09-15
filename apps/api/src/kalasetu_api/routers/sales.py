from __future__ import annotations

from pydantic import BaseModel, Field

from fastapi import APIRouter, Depends, HTTPException, status

from kalasetu_api.adapters.firebase import (
    compute_trade_record,
    get_listing,
    list_artisan_sales,
    save_sale,
)
from kalasetu_api.deps import current_uid

router = APIRouter(tags=["sales"])


class SalePayload(BaseModel):
    listing_id: str
    amount: float = Field(gt=0)


def _spoken(total: float, count: int, lang: str = "en-IN") -> str:
    if count == 0:
        if str(lang).startswith("hi"):
            return "अभी तक कोई बिक्री नहीं हुई।"
        if str(lang).startswith("mr"):
            return "अजून विक्री झाली नाही."
        return "No sales yet."
    if str(lang).startswith("hi"):
        return f"{count} बिक्री, कुल ₹{total:.0f}।"
    if str(lang).startswith("mr"):
        return f"{count} विक्री, एकूण ₹{total:.0f}."
    return f"{count} sales, ₹{total:.0f} in total."


@router.post("/v1/sales")
async def create_sale(body: SalePayload, uid: str = Depends(current_uid)) -> dict:
    listing = get_listing(body.listing_id, uid=uid)
    if listing is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Listing not found")
    sale = save_sale(uid=uid, listing_id=body.listing_id, amount=body.amount)
    return {"ok": True, "sale": sale, "trade_record": compute_trade_record(uid)}


@router.get("/v1/sales")
async def my_sales(uid: str = Depends(current_uid)) -> dict:
    items = list_artisan_sales(uid)
    total = sum(float(item.get("amount") or 0) for item in items)
    return {"items": items, "total_inr": total, "count": len(items)}


@router.get("/v1/money")
async def money(uid: str = Depends(current_uid)) -> dict:
    items = list_artisan_sales(uid)
    total = sum(float(item.get("amount") or 0) for item in items)
    trade = compute_trade_record(uid)
    from kalasetu_api.adapters.firebase import get_artisan

    artisan = get_artisan(uid) or {}
    spoken = _spoken(total, len(items), artisan.get("lang") or "en-IN")
    return {
        "sales": items,
        "total_inr": total,
        "count": len(items),
        "empty": len(items) == 0,
        "spoken": spoken,
        "trade_record": trade,
    }


@router.get("/v1/trade-record")
async def trade_record(uid: str = Depends(current_uid)) -> dict:
    record = compute_trade_record(uid)
    return {"trade_record": record, "label": "Trade Record"}
