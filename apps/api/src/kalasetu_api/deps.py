from __future__ import annotations

from fastapi import Depends, Header, HTTPException


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
