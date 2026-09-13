from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from kalasetu_api.adapters.firebase import (
    get_artisan,
    get_or_create_artisan,
    mint_custom_token,
    normalize_phone,
    update_artisan,
)
from kalasetu_api.config import get_settings
from kalasetu_api.deps import require_bearer

router = APIRouter(prefix="/v1/auth", tags=["auth"])


class OtpRequest(BaseModel):
    phone: str = Field(min_length=8, max_length=20)


class VerifyRequest(BaseModel):
    phone: str = Field(min_length=8, max_length=20)
    code: str = Field(min_length=4, max_length=8)


class ProfileUpdateRequest(BaseModel):
    name: str | None = None
    lang: str | None = None
    cluster: str | None = None
    pehchan: dict[str, Any] | None = None
    consentAt: str | None = None


def uid_from_token(token: str) -> str:
    if token.startswith("dev."):
        return token.split("dev.", 1)[1]
    return token


@router.post("/otp")
def request_otp(body: OtpRequest) -> dict:
    settings = get_settings()
    if settings.otp_provider != "mock":
        raise HTTPException(
            status_code=status.HTTP_501_NOT_IMPLEMENTED,
            detail="Only mock OTP is wired. Keep OTP_PROVIDER=mock for now.",
        )
    norm_phone = normalize_phone(body.phone)
    return {
        "ok": True,
        "mock": True,
        "label": "Mock — for SIH demo",
        "provider": "mock",
        "phone": norm_phone,
    }


@router.post("/verify")
def verify_otp(body: VerifyRequest) -> dict:
    settings = get_settings()
    if body.code != settings.otp_mock_code:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid OTP")

    # Connect mobile number with persistent UUID in Firestore (or in-memory fallback)
    artisan = get_or_create_artisan(body.phone, settings=settings)
    uid = artisan["uid"]

    # Mint Firebase custom token if Firebase Admin credentials are ready
    custom_token = mint_custom_token(uid, settings=settings)

    return {
        "ok": True,
        "uid": uid,
        "phone": artisan.get("phone", normalize_phone(body.phone)),
        "token": f"dev.{uid}",
        "firebase_custom_token": custom_token,
        "artisan": artisan,
        "label": "Mock — for SIH demo",
    }


@router.get("/me")
def get_current_user(token: str = Depends(require_bearer)) -> dict:
    uid = uid_from_token(token)
    artisan = get_artisan(uid)
    if artisan is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Artisan not found")
    return {"ok": True, "artisan": artisan}


@router.patch("/profile")
def update_current_profile(
    body: ProfileUpdateRequest,
    token: str = Depends(require_bearer),
) -> dict:
    uid = uid_from_token(token)
    updates = {k: v for k, v in body.model_dump().items() if v is not None}
    updated = update_artisan(uid, updates)
    if updated is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Artisan not found")
    return {"ok": True, "artisan": updated}
