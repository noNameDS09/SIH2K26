from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field

from kalasetu_api.config import get_settings

router = APIRouter(prefix="/v1/auth", tags=["auth"])


class OtpRequest(BaseModel):
    phone: str = Field(min_length=8, max_length=16)


class VerifyRequest(BaseModel):
    phone: str = Field(min_length=8, max_length=16)
    code: str = Field(min_length=4, max_length=8)


def _uid_for(phone: str) -> str:
    digits = "".join(ch for ch in phone if ch.isdigit())
    return f"artisan_{digits or 'unknown'}"


@router.post("/otp")
def request_otp(body: OtpRequest) -> dict:
    settings = get_settings()
    if settings.otp_provider != "mock":
        raise HTTPException(
            status_code=status.HTTP_501_NOT_IMPLEMENTED,
            detail="Only mock OTP is wired. Keep OTP_PROVIDER=mock for now.",
        )
    return {
        "ok": True,
        "mock": True,
        "label": "Mock — for SIH demo",
        "provider": "mock",
        "phone": body.phone,
    }


@router.post("/verify")
def verify_otp(body: VerifyRequest) -> dict:
    settings = get_settings()
    if body.code != settings.otp_mock_code:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid OTP")
    uid = _uid_for(body.phone)
    return {
        "ok": True,
        "uid": uid,
        "token": f"dev.{uid}",
        "firebase_custom_token": None,
        "label": "Mock — for SIH demo",
    }
