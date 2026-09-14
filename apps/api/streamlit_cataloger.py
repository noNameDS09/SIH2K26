"""
KalaSetu Live cataloger tester — jump straight to the mic.

Gemini Live stays open across turns (FastAPI holds the socket).
Price is seed math. Listing table fills as slots confirm.

    cd apps/api
    PYTHONPATH=src .venv/bin/streamlit run streamlit_cataloger.py
"""

from __future__ import annotations

import sys
import time
import uuid
from pathlib import Path
from urllib.parse import quote

ROOT = Path(__file__).resolve().parent
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

import httpx
import streamlit as st
import streamlit.components.v1 as components

from kalasetu_api.adapters.speech.live_ui import LIVE_MIC_HTML
from kalasetu_api.config import get_settings
from kalasetu_api.engines.cataloger import CatalogerSession, listing_table_rows
from kalasetu_api.engines.pricing import available_clusters

st.set_page_config(page_title="KalaSetu · Live cataloger", page_icon="🟠", layout="wide")
ORANGE = "#F97316"
API = "http://127.0.0.1:8000"
LANG = "mr-IN"


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
            "--reload",
            "--reload-dir",
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
    for _ in range(24):
        time.sleep(0.25)
        try:
            httpx.get(f"{API}/health", timeout=1.0)
            return True
        except Exception:
            continue
    return False


settings = get_settings()
if "live_id" not in st.session_state:
    st.session_state.live_id = str(uuid.uuid4())
    st.session_state.cluster = available_clusters()[0] if available_clusters() else "varanasi"

st.markdown(
    f"<h1 style='color:{ORANGE};margin-bottom:0'>KalaSetu</h1>"
    "<p>Marathi live cataloger · click Start conversation · keep speaking until the table fills</p>",
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
    st.caption(f"Live model: `{settings.gemini_live_model}`")
    st.caption("Language locked to Marathi for this tester.")
    clusters = available_clusters()
    idx = clusters.index(st.session_state.cluster) if st.session_state.cluster in clusters else 0
    st.session_state.cluster = st.selectbox("Cluster (wage seed)", clusters, index=idx)
    if st.button("New live session"):
        st.session_state.live_id = str(uuid.uuid4())
        st.rerun()

if not _ensure_api():
    st.error("Could not start FastAPI on :8000. Live needs the API to hold the Gemini socket.")
    st.stop()

sid = st.session_state.live_id
ws = (
    f"ws://127.0.0.1:8000/v1/speech/live?session_id={sid}"
    f"&language_code={quote(LANG)}&cluster={quote(st.session_state.cluster)}&token=dev"
)

mic_col, table_col = st.columns([1, 1])
with mic_col:
    st.info("After the agent asks, wait for “Your turn — speak now.” The socket must stay Live.")

    @st.fragment
    def _mic() -> None:
        components.html(LIVE_MIC_HTML.replace("__WS_URL__", repr(ws)), height=200)

    _mic()

with table_col:

    @st.fragment(run_every=1.5)
    def _poll() -> None:
        try:
            payload = httpx.get(f"{API}/v1/speech/live/state/{sid}", timeout=2.0).json()
        except Exception:
            st.caption("API up. Click Start conversation.")
            return
        if payload.get("missing") or not payload.get("ok"):
            st.caption("Waiting for Live session…")
            return
        session = CatalogerSession.from_dict(payload.get("session"))
        st.markdown(f"**Phase:** `{session.phase}` · **slot:** `{session.current_slot}`")
        confirmed = sum(1 for state in session.slots.values() if state.confirmed)
        st.metric("Slots confirmed", f"{confirmed} / {len(session.slots)}")
        if session.question:
            st.write(session.question)
        if session.reread:
            st.warning(session.reread)
        rows = payload.get("table") or listing_table_rows(session)
        if rows:
            st.dataframe(rows, width="stretch", hide_index=True)

    _poll()
