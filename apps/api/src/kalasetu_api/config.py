from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

from kalasetu_api.engines.studio import studio_deps_ok


def _env_file() -> str | None:
    here = Path(__file__).resolve()
    for candidate in (here.parents[4] / ".env", Path.cwd() / ".env"):
        if candidate.exists():
            return str(candidate)
    for parent in Path.cwd().parents:
        env = parent / ".env"
        if env.exists():
            return str(env)
    return None


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=_env_file(),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_name: str = "kalasetu-api"
    cors_origins: str = (
        "http://localhost:3000,http://127.0.0.1:3000,"
        "http://localhost:8501,http://127.0.0.1:8501"
    )
    cors_origin_regex: str = r"https?://(localhost|127\.0\.0\.1)(:\d+)?$"
    public_base_url: str = "http://localhost:8000"

    otp_provider: str = "mock"
    otp_mock_code: str = "123456"
    twofactor_api_key: str = ""

    sarvam_api_key: str = ""
    sarvam_api_base_url: str = "https://api.sarvam.ai"
    sarvam_tts_speaker: str = "shubh"
    sarvam_tts_sample_rate: int = 16000
    gemini_api_key: str = ""
    gemini_model: str = "gemini-2.5-flash-lite"
    gemini_live_model: str = "gemini-2.5-flash-native-audio-preview-12-2025"

    firebase_project_id: str = ""
    firestore_location: str = "asia-south1"
    firestore_database: str = "(default)"
    firebase_storage_location: str = "us-east1"
    firebase_storage_bucket: str = ""
    google_application_credentials: str = ""

    listing_hmac_secret: str = ""
    admin_api_token: str = ""

    @property
    def cors_origin_list(self) -> list[str]:
        return [item.strip() for item in self.cors_origins.split(",") if item.strip()]

    @property
    def resolved_credentials_path(self) -> Path | None:
        if not self.google_application_credentials:
            return None
        raw = Path(self.google_application_credentials)
        if raw.is_absolute() and raw.is_file():
            return raw
        repo = Path(__file__).resolve().parents[4]
        candidate = (repo / raw).resolve()
        if candidate.is_file():
            return candidate
        cwd_candidate = Path.cwd().joinpath(raw).resolve()
        if cwd_candidate.is_file():
            return cwd_candidate
        return None

    @property
    def firebase_admin_ready(self) -> bool:
        return self.resolved_credentials_path is not None

    def key_status(self) -> dict[str, bool | str]:
        bucket = self.firebase_storage_bucket or (
            f"{self.firebase_project_id}.firebasestorage.app" if self.firebase_project_id else ""
        )
        return {
            "sarvam_api_key": bool(self.sarvam_api_key),
            "gemini_api_key": bool(self.gemini_api_key),
            "firebase_project_id": bool(self.firebase_project_id),
            "firebase_admin": self.firebase_admin_ready,
            "firebase_storage": bool(bucket and self.firebase_admin_ready),
            "listing_hmac_secret": bool(self.listing_hmac_secret),
            "otp_provider": self.otp_provider,
            "studio": studio_deps_ok(),
        }

    def missing_keys(self) -> list[str]:
        status = self.key_status()
        missing = [
            name
            for name, present in status.items()
            if name not in ("otp_provider", "studio", "firebase_storage") and present is False
        ]
        if self.otp_provider == "2factor" and not self.twofactor_api_key:
            missing.append("twofactor_api_key")
        return missing


@lru_cache
def get_settings() -> Settings:
    return Settings()
