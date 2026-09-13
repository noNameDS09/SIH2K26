"""
KalaSetu listing tester — same workflow as app/web, Streamlit chrome.

language → mock OTP → profile → photo → Gemini Live cataloger
→ Sarvam card re-read → listing table (fields + price bands).

Gemini Live asks and listens on a socket (FastAPI holds it).
Sarvam TTS reads the card. Price is seed math, never the model.

    cd apps/api
    PYTHONPATH=src .venv/bin/streamlit run streamlit_cataloger.py
"""

from __future__ import annotations

import hashlib
import sys
import time
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

import httpx
import streamlit as st
import streamlit.components.v1 as components

from kalasetu_api.adapters.speech.live_ui import LIVE_MIC_HTML
from kalasetu_api.adapters.speech.sarvam import synthesize_speech, transcribe_audio
from kalasetu_api.config import get_settings
from kalasetu_api.engines.cataloger import (
    SARVAM_LANGUAGES,
    CatalogerSession,
    apply_transcript,
    confirm_current,
    listing_table_rows,
    reject_current,
    start_session,
)
from kalasetu_api.engines.pricing import available_clusters

st.set_page_config(page_title="KalaSetu · Live cataloger", page_icon="🟠", layout="wide")
ORANGE = "#F97316"
API = "http://127.0.0.1:8000"
STAGES = ("language", "otp", "profile", "photo", "live", "table")


def _ensure_api() -> bool:
    try:
        httpx.get(f"{API}/health", timeout=1.0)
        return True
    except Exception:
        pass
    import subprocess

    subprocess.Popen(
        [
            sys.executable,
            "-m",
            "uvicorn",
            "kalasetu_api.main:app",
            "--app-dir",
            "src",
            "--host",
            "127.0.0.1",
            "--port",
            "8000",
        ],
        cwd=str(ROOT),
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    for _ in range(20):
        time.sleep(0.25)
        try:
            httpx.get(f"{API}/health", timeout=1.0)
            return True
        except Exception:
            continue
    return False


def _reset_to(stage: str) -> None:
    st.session_state.stage = stage


def _speak_if_needed(text: str, *, enabled: bool, language_code: str) -> bytes | None:
    if not enabled or not text:
        return None
    cache: dict[str, bytes] = st.session_state.setdefault("tts_cache", {})
    if text in cache:
        return cache[text]
    audio = synthesize_speech(text, language_code=language_code)
    cache[text] = audio
    return audio


settings = get_settings()
if "stage" not in st.session_state:
    st.session_state.stage = "language"
    st.session_state.language_code = "mr-IN"
    st.session_state.cluster = available_clusters()[0] if available_clusters() else "varanasi"
    st.session_state.artisan_name = ""
    st.session_state.otp_digits = ""
    st.session_state.photo = None
    st.session_state.live_id = str(uuid.uuid4())
    st.session_state.fallback_session = None
    st.session_state.use_live = True
    st.session_state.error = None

st.markdown(
    f"<h1 style='color:{ORANGE};margin-bottom:0'>KalaSetu</h1>"
    "<p>Production listing workflow tester · Live cataloger · Marathi default</p>",
    unsafe_allow_html=True,
)

missing = [
    k
    for k, ok in (
        ("SARVAM_API_KEY", bool(settings.sarvam_api_key)),
        ("GEMINI_API_KEY", bool(settings.gemini_api_key)),
    )
    if not ok
]
if missing:
    st.error("Missing keys in repo `.env`: " + ", ".join(missing))

with st.sidebar:
    st.subheader("Tester")
    st.caption(
        "Same jobs as app/web: language → OTP → profile → photo → Live interview → price → approve → listing data."
    )
    st.caption(f"Live model: `{settings.gemini_live_model}`")
    st.session_state.use_live = st.toggle(
        "Gemini Live socket (production path)", value=st.session_state.use_live
    )
    st.caption("Off = Sarvam STT clips + turn cataloger (fallback).")
    st.progress(
        (STAGES.index(st.session_state.stage) + 1) / len(STAGES),
        text=st.session_state.stage,
    )
    if st.button("Restart from language"):
        for key in list(st.session_state.keys()):
            del st.session_state[key]
        st.rerun()

stage = st.session_state.stage

if stage == "language":
    st.info("Pick the language the artisan will speak. Tiles match the app language picker.")
    labels = [f"{code} — {name}" for code, name in SARVAM_LANGUAGES]
    codes = [code for code, _ in SARVAM_LANGUAGES]
    current = (
        codes.index(st.session_state.language_code)
        if st.session_state.language_code in codes
        else 0
    )
    picked = st.selectbox("Language", labels, index=current)
    st.session_state.language_code = codes[labels.index(picked)]
    if st.button("Continue", type="primary"):
        _reset_to("otp")
        st.rerun()
    st.stop()

if stage == "otp":
    st.warning("Mock — for SIH demo. OTP is not voice. Code is 123456.")
    phone = st.text_input("Phone", value="9876543210")
    code = st.text_input("OTP", value=st.session_state.otp_digits, max_chars=6)
    row = st.columns(6)
    for digit in ["1", "2", "3", "4", "5", "6"]:
        if row[int(digit) - 1].button(digit, key=f"d{digit}"):
            st.session_state.otp_digits = (st.session_state.otp_digits + digit)[:6]
            st.rerun()
    row2 = st.columns(6)
    for i, digit in enumerate(["7", "8", "9", "0"]):
        if row2[i].button(digit, key=f"d{digit}"):
            st.session_state.otp_digits = (st.session_state.otp_digits + digit)[:6]
            st.rerun()
    if row2[4].button("⌫"):
        st.session_state.otp_digits = st.session_state.otp_digits[:-1]
        st.rerun()
    entered = code or st.session_state.otp_digits
    if st.button("Verify", type="primary"):
        if entered == settings.otp_mock_code:
            st.session_state.phone = phone
            _reset_to("profile")
            st.rerun()
        st.error("Wrong OTP")
    st.stop()

if stage == "profile":
    st.write("Onboarding (tester): name + cluster. Pehchan/Aadhaar stay mocked on the real app.")
    st.session_state.artisan_name = st.text_input(
        "Artisan name", value=st.session_state.artisan_name
    )
    clusters = available_clusters()
    idx = clusters.index(st.session_state.cluster) if st.session_state.cluster in clusters else 0
    st.session_state.cluster = st.selectbox("Cluster", clusters, index=idx)
    if st.button("Save profile", type="primary"):
        _reset_to("photo")
        st.rerun()
    st.stop()

if stage == "photo":
    st.write("Capture (tester). App sends this through the image studio later. You can skip.")
    cam = st.camera_input("Take product photo")
    upload = st.file_uploader("Or upload", type=["jpg", "jpeg", "png"])
    blob = cam or upload
    if blob is not None:
        st.session_state.photo = blob.getvalue()
        st.image(st.session_state.photo, caption="Original (studio enhance is a separate API)")
    c1, c2 = st.columns(2)
    if c1.button("Use photo and start cataloger", type="primary"):
        _reset_to("live")
        st.rerun()
    if c2.button("Skip photo"):
        st.session_state.photo = None
        _reset_to("live")
        st.rerun()
    st.stop()

lang = st.session_state.language_code
cluster = st.session_state.cluster
name = st.session_state.artisan_name
photo_on = st.session_state.photo is not None

if stage == "live" and st.session_state.use_live:
    api_up = _ensure_api()
    if not api_up:
        st.error("Could not start FastAPI on :8000. Live needs the API to hold the Gemini socket.")
        st.stop()
    st.success(
        "Speak after Start live mic. One question at a time. theek hai confirms, galat repairs that slot."
    )
    sid = st.session_state.live_id
    from urllib.parse import quote

    ws = (
        f"ws://127.0.0.1:8000/v1/speech/live?session_id={sid}"
        f"&language_code={quote(lang)}&cluster={quote(cluster)}&token=dev"
        f"&artisan_name={quote(name)}&photo={'1' if photo_on else '0'}"
    )
    components.html(LIVE_MIC_HTML.replace("__WS_URL__", repr(ws)), height=180)

    @st.fragment(run_every=1.5)
    def _poll_live() -> None:
        try:
            payload = httpx.get(f"{API}/v1/speech/live/state/{sid}", timeout=2.0).json()
        except Exception:
            st.caption("Waiting for Live session…")
            return
        if payload.get("missing") or not payload.get("ok"):
            st.caption("Waiting for Live session… click Start live mic.")
            return
        session = CatalogerSession.from_dict(payload.get("session"))
        rows = payload.get("table") or []
        phase = payload.get("phase")
        st.markdown(f"**Phase:** `{phase}` · **slot:** `{session.current_slot}`")
        if session.question:
            st.info(session.question)
        if session.reread:
            st.warning(session.reread)
        confirmed = sum(1 for state in session.slots.values() if state.confirmed)
        st.metric("Slots confirmed", f"{confirmed} / {len(session.slots)}")
        if rows:
            st.dataframe(rows, use_container_width=True, hide_index=True)
        if phase == "complete":
            st.session_state.fallback_session = session.to_dict()
            st.session_state.stage = "table"
            st.rerun()

    _poll_live()
    if st.button("Show listing table"):
        st.session_state.stage = "table"
        st.rerun()
    st.stop()

if stage == "live":
    if st.session_state.fallback_session is None:
        st.session_state.fallback_session = start_session(
            cluster=cluster,
            language_code=lang,
            artisan_name=name,
            photo_attached=photo_on,
        ).to_dict()
    session = CatalogerSession.from_dict(st.session_state.fallback_session)
    st.info("Fallback: record one answer at a time. Production path is the Live toggle.")
    col_q, col_progress = st.columns([2, 1])
    with col_q:
        st.markdown(f"**Phase:** `{session.phase}` · **slot:** `{session.current_slot}`")
        st.success(session.question)
        if session.reread and session.phase == "confirming":
            st.warning(session.reread)
    with col_progress:
        confirmed = sum(1 for state in session.slots.values() if state.confirmed)
        st.metric("Slots confirmed", f"{confirmed} / {len(session.slots)}")
    if session.speak:
        try:
            audio = _speak_if_needed(session.speak, enabled=True, language_code=lang)
            if audio:
                st.audio(audio, format="audio/wav")
        except Exception as exc:
            st.session_state.error = f"TTS skipped: {exc}"
    if st.session_state.get("error"):
        st.error(st.session_state.error)
    if session.phase != "complete":
        if session.phase == "confirming":
            c1, c2 = st.columns(2)
            if c1.button("बरोबर — confirm", type="primary"):
                st.session_state.fallback_session = confirm_current(session).to_dict()
                st.rerun()
            if c2.button("चुकीचे — repair this slot"):
                st.session_state.fallback_session = reject_current(session).to_dict()
                st.rerun()
        audio_file = st.audio_input("Record your answer (≤30 seconds)")
        if audio_file is not None:
            blob = audio_file.getvalue()
            digest = hashlib.sha1(blob).hexdigest()
            if digest != st.session_state.get("last_audio_hash"):
                st.session_state.last_audio_hash = digest
                try:
                    result = transcribe_audio(
                        blob,
                        filename=getattr(audio_file, "name", None) or "answer.wav",
                        content_type=getattr(audio_file, "type", None) or "audio/wav",
                        language_code=lang,
                    )
                    st.caption(f"STT: {result['transcript']}")
                    st.session_state.fallback_session = apply_transcript(
                        CatalogerSession.from_dict(st.session_state.fallback_session),
                        result["transcript"],
                    ).to_dict()
                    st.session_state.error = None
                except Exception as exc:
                    st.session_state.error = f"STT failed: {exc}"
                st.rerun()
        with st.form("text_answer"):
            typed = st.text_input("Or type the answer")
            if st.form_submit_button("पाठवा") and typed.strip():
                st.session_state.fallback_session = apply_transcript(
                    session, typed.strip()
                ).to_dict()
                st.rerun()
        st.stop()
    st.session_state.stage = "table"
    st.rerun()

# table
st.subheader("Listing data (app payload, not spoken sentences)")
session = None
if st.session_state.fallback_session:
    session = CatalogerSession.from_dict(st.session_state.fallback_session)
else:
    try:
        payload = httpx.get(
            f"{API}/v1/speech/live/state/{st.session_state.live_id}", timeout=2.0
        ).json()
        session = CatalogerSession.from_dict(payload.get("session") or {})
    except Exception:
        session = start_session(cluster=cluster, language_code=lang)
rows = listing_table_rows(session)
st.dataframe(rows, use_container_width=True, hide_index=True)
if session and session.listing:
    with st.expander("Raw listing payload"):
        st.json(
            {
                "fields": {
                    key: payload["value"]
                    for key, payload in session.listing.get("fields", {}).items()
                },
                "titles": {
                    "title_hi": (session.listing.get("title_hi") or {}).get("value"),
                    "title_en": (session.listing.get("title_en") or {}).get("value"),
                    "desc_hi": (session.listing.get("desc_hi") or {}).get("value"),
                    "desc_en": (session.listing.get("desc_en") or {}).get("value"),
                },
                "prices": {
                    band: payload.get("value")
                    for band, payload in (session.listing.get("prices") or {}).items()
                },
            }
        )
if st.session_state.photo:
    st.image(st.session_state.photo, caption="Original photo", width=280)
if st.button("New product"):
    for key in list(st.session_state.keys()):
        del st.session_state[key]
    st.rerun()
