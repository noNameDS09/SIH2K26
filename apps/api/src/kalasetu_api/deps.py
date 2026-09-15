from __future__ import annotations

from fastapi import Depends, Header, HTTPException

from kalasetu_api.config import get_settings


async def require_bearer(authorization: str | None = Header(default=None)) -> str:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = authorization.split(" ", 1)[1].strip()
    if not token:
        raise HTTPException(status_code=401, detail="Missing bearer token")
    return token


def uid_from_token(token: str) -> str:
    if token.startswith("dev."):
        return token.split("dev.", 1)[1]
    return token


async def current_uid(token: str = Depends(require_bearer)) -> str:
    return uid_from_token(token)


async def require_admin(x_admin_token: str | None = Header(default=None)) -> str:
    expected = get_settings().admin_api_token
    if expected:
        if x_admin_token != expected:
            raise HTTPException(status_code=401, detail="Admin token required")
        return x_admin_token
    return x_admin_token or "dev-admin"
