from contextlib import asynccontextmanager
import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from kalasetu_api.config import get_settings
from kalasetu_api.routers import advisor, auth, export, images, listings, sales, speech, speech_live, trends

log = logging.getLogger("kalasetu")


@asynccontextmanager
async def lifespan(_: FastAPI):
    settings = get_settings()
    missing = settings.missing_keys()
    if missing:
        log.warning("API booted with missing keys: %s", ", ".join(missing))
    else:
        log.info("All backbone keys present")
    yield


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(
        title="KalaSetu API",
        version="0.1.0",
        lifespan=lifespan,
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origin_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.include_router(auth.router)
    app.include_router(images.router)
    app.include_router(speech.router)
    app.include_router(speech_live.router)
    app.include_router(listings.router)
    app.include_router(sales.router)
    app.include_router(advisor.router)
    app.include_router(trends.router)
    app.include_router(export.router)

    @app.get("/")
    def root() -> dict:
        return {"service": settings.app_name, "docs": "/docs", "health": "/health"}

    @app.get("/health")
    def health() -> dict:
        return {
            "ok": True,
            "service": settings.app_name,
            "firestore_location": settings.firestore_location,
            "storage_location": settings.firebase_storage_location,
            "wired": settings.key_status(),
            "missing": settings.missing_keys(),
            "storage_bucket": settings.firebase_storage_bucket
            or (f"{settings.firebase_project_id}.firebasestorage.app" if settings.firebase_project_id else None),
        }

    return app


app = create_app()
