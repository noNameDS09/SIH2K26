"""Gemini Live WebSocket — FastAPI holds the socket (web + Streamlit tester)."""

from __future__ import annotations

import asyncio
import base64
import logging
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from fastapi.responses import HTMLResponse

from kalasetu_api.adapters.llm.gemini_live import (
    gemini_live_client,
    live_connect_config,
    live_model_name,
    live_system_instruction,
    tool_args,
)
from kalasetu_api.adapters.speech.live_ui import LIVE_MIC_HTML
from kalasetu_api.adapters.speech.sarvam import synthesize_speech
from kalasetu_api.config import get_settings
from kalasetu_api.engines.cataloger import (
    CatalogerSession,
    apply_live_tool,
    listing_table_rows,
    start_session,
)

log = logging.getLogger("kalasetu.live")
router = APIRouter(prefix="/v1/speech", tags=["speech-live"])

LIVE_STATE: dict[str, CatalogerSession] = {}


def get_live_state(session_id: str) -> CatalogerSession | None:
    return LIVE_STATE.get(session_id)


@router.get("/live/state/{session_id}")
async def live_state(session_id: str) -> dict:
    session = LIVE_STATE.get(session_id)
    if session is None:
        return {"ok": False, "missing": True}
    return {
        "ok": True,
        "session": session.to_dict(),
        "table": listing_table_rows(session),
        "done": session.phase == "complete",
        "phase": session.phase,
    }


@router.get("/live/ui")
async def live_ui(
    session_id: str,
    language_code: str = "mr-IN",
    cluster: str = "varanasi",
    token: str = "dev",
) -> HTMLResponse:
    ws = (
        f"ws://127.0.0.1:8000/v1/speech/live?session_id={session_id}"
        f"&language_code={language_code}&cluster={cluster}&token={token}"
    )
    html = LIVE_MIC_HTML.replace("__WS_URL__", repr(ws))
    return HTMLResponse(html)


@router.websocket("/live")
async def live_socket(ws: WebSocket) -> None:
    await ws.accept()
    query = ws.query_params
    token = query.get("token") or ""
    if not token:
        await ws.close(code=1008)
        return
    session_id = query.get("session_id") or "default"
    language_code = query.get("language_code") or "mr-IN"
    cluster = query.get("cluster") or "varanasi"
    artisan_name = query.get("artisan_name") or ""
    photo_attached = query.get("photo") == "1"

    catalog = start_session(
        cluster=cluster,
        language_code=language_code,
        artisan_name=artisan_name,
        photo_attached=photo_attached,
    )
    LIVE_STATE[session_id] = catalog
    settings = get_settings()

    try:
        client = gemini_live_client(settings)
        model = live_model_name(settings)
        instruction = live_system_instruction(
            language_code=language_code,
            cluster=cluster,
            artisan_name=artisan_name,
        )
        config = live_connect_config(instruction)
        await ws.send_json({"type": "status", "text": "Connecting Gemini Live…"})
        async with client.aio.live.connect(model=model, config=config) as live:
            await ws.send_json({"type": "status", "text": "Live. Agent will ask the first slot."})
            await live.send_client_content(
                turns={
                    "role": "user",
                    "parts": [
                        {
                            "text": (
                                f"Begin now. Speak {language_code}. "
                                "Ask only the first missing slot."
                            )
                        }
                    ],
                },
                turn_complete=True,
            )

            async def from_browser() -> None:
                try:
                    while True:
                        message = await ws.receive_json()
                        kind = message.get("type")
                        if kind == "end":
                            await live.send_realtime_input(audio_stream_end=True)
                            break
                        if kind == "text" and message.get("text"):
                            await live.send_client_content(
                                turns={
                                    "role": "user",
                                    "parts": [{"text": message["text"]}],
                                },
                                turn_complete=True,
                            )
                        if kind == "pcm" and message.get("data"):
                            raw = base64.b64decode(message["data"])
                            await live.send_realtime_input(
                                audio={"data": raw, "mime_type": "audio/pcm;rate=16000"}
                            )
                except WebSocketDisconnect:
                    return
                except Exception as exc:
                    log.warning("browser pump stopped: %s", exc)

            async def from_gemini() -> None:
                from google.genai import types

                async for response in live.receive():
                    data = getattr(response, "data", None)
                    if data:
                        payload = data if isinstance(data, (bytes, bytearray)) else None
                        if payload:
                            await ws.send_json(
                                {
                                    "type": "pcm",
                                    "data": base64.b64encode(payload).decode("ascii"),
                                }
                            )
                    tool_call = getattr(response, "tool_call", None)
                    if not tool_call:
                        continue
                    function_responses = []
                    card_text = None
                    for fc in tool_call.function_calls or []:
                        result = apply_live_tool(catalog, fc.name, tool_args(fc))
                        LIVE_STATE[session_id] = catalog
                        if fc.name == "write_copy" and catalog.speak:
                            card_text = catalog.speak
                        function_responses.append(
                            types.FunctionResponse(
                                id=fc.id,
                                name=fc.name,
                                response=result,
                            )
                        )
                    await live.send_tool_response(function_responses=function_responses)
                    await ws.send_json(
                        {
                            "type": "state",
                            "session": catalog.to_dict(),
                            "table": listing_table_rows(catalog),
                            "phase": catalog.phase,
                        }
                    )
                    if card_text:
                        try:
                            wav = synthesize_speech(
                                card_text, language_code=catalog.language_code
                            )
                            await ws.send_json(
                                {
                                    "type": "card_tts",
                                    "data": base64.b64encode(wav).decode("ascii"),
                                    "content_type": "audio/wav",
                                }
                            )
                        except Exception as exc:
                            log.warning("Sarvam card TTS skipped: %s", exc)
                    if catalog.phase == "complete":
                        await ws.send_json({"type": "done"})

            t_browser = asyncio.create_task(from_browser())
            t_gemini = asyncio.create_task(from_gemini())
            done, pending = await asyncio.wait(
                {t_browser, t_gemini},
                return_when=asyncio.FIRST_COMPLETED,
            )
            for task in pending:
                task.cancel()
    except WebSocketDisconnect:
        pass
    except Exception as exc:
        log.exception("Live session failed")
        try:
            await ws.send_json({"type": "error", "detail": str(exc)})
        except Exception:
            pass
    finally:
        try:
            await ws.close()
        except Exception:
            pass
