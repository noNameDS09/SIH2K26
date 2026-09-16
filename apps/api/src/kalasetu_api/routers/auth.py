from __future__ import annotations

import json
import uuid
from datetime import datetime, timezone
from typing import Any

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from pydantic import BaseModel, Field

from kalasetu_api.adapters.firebase import (
    get_artisan,
    get_or_create_artisan,
    mint_custom_token,
    normalize_phone,
    update_artisan,
)
from kalasetu_api.adapters.storage import upload_profile_document
from kalasetu_api.config import get_settings
from kalasetu_api.deps import require_bearer, uid_from_token

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


DOCUMENT_TYPES = {"pm_vishwakarma", "pahchan", "weaver_id", "e_shram", "nfsa_ration"}


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
    firebase_ready = bool(custom_token)

    return {
        "ok": True,
        "uid": uid,
        "phone": artisan.get("phone", normalize_phone(body.phone)),
        "token": f"dev.{uid}",
        "firebase_custom_token": custom_token,
        "firebase_ready": firebase_ready,
        "auth_mode": "firebase" if firebase_ready else "dev",
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


@router.post("/documents")
async def upload_identity_document(
    document_type: str = Form(...),
    details: str = Form("{}"),
    file: UploadFile = File(...),
    token: str = Depends(require_bearer),
) -> dict:
    """Save one artisan proof document and its structured details."""
    document_type = document_type.strip().lower()
    if document_type not in DOCUMENT_TYPES:
        raise HTTPException(status_code=400, detail="Unsupported document type")
    try:
        parsed_details = json.loads(details or "{}")
    except json.JSONDecodeError as exc:
        raise HTTPException(status_code=400, detail="Document details must be valid JSON") from exc
    if not isinstance(parsed_details, dict):
        raise HTTPException(status_code=400, detail="Document details must be an object")

    data = await file.read()
    if not data:
        raise HTTPException(status_code=400, detail="Document file is empty")
    if len(data) > 10 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="Document must be 10 MB or smaller")
    content_type = file.content_type or "application/octet-stream"
    if content_type not in {"application/pdf", "image/jpeg", "image/png", "image/webp"}:
        raise HTTPException(status_code=415, detail="Upload a PDF, JPG, PNG, or WebP file")

    uid = uid_from_token(token)
    artisan = get_artisan(uid)
    if artisan is None:
        raise HTTPException(status_code=404, detail="Artisan not found")
    document_id = uuid.uuid4().hex[:16]
    storage_path = upload_profile_document(
        uid, document_id, file.filename or "document", data, content_type
    )
    if storage_path is None and get_settings().firebase_admin_ready:
        raise HTTPException(status_code=503, detail="Document storage is temporarily unavailable")

    record = {
        "id": document_id,
        "type": document_type,
        "details": parsed_details,
        "filename": file.filename or "document",
        "contentType": content_type,
        "storagePath": storage_path,
        "uploadedAt": datetime.now(timezone.utc).isoformat(),
        "status": "submitted",
    }
    documents = list(artisan.get("documents") or [])
    documents = [item for item in documents if item.get("type") != document_type]
    documents.append(record)
    updated = update_artisan(uid, {"documents": documents, "verificationStatus": "submitted"})
    if updated is None:
        raise HTTPException(status_code=404, detail="Artisan not found")
    return {"ok": True, "document": record, "artisan": updated}
