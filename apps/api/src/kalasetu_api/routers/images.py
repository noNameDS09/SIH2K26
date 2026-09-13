from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status

from kalasetu_api.deps import require_bearer

router = APIRouter(tags=["images"])


@router.post("/v1/images/enhance")
async def enhance(
    file: UploadFile = File(...),
    bg_preset: str = Form("linen"),
    listing_id: str = Form(...),
    _: str = Depends(require_bearer),
) -> dict:
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Studio enhance not wired yet",
    )
