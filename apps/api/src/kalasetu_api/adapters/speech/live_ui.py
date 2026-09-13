LIVE_MIC_HTML = r"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <style>
    body { font-family: ui-sans-serif, system-ui, sans-serif; margin: 0; padding: 12px; background: #fff7ed; color: #1c1917; }
    button { font-size: 16px; padding: 10px 16px; border: 0; border-radius: 10px; cursor: pointer; }
    #go { background: #F97316; color: white; font-weight: 700; }
    #stop { background: #44403c; color: white; }
    #status { margin-top: 10px; min-height: 1.4em; }
    .row { display: flex; gap: 8px; flex-wrap: wrap; }
  </style>
</head>
<body>
  <div class="row">
    <button id="go" type="button">Start live mic</button>
    <button id="stop" type="button" disabled>Stop</button>
  </div>
  <p id="status">Click Start. Allow the microphone. Speak after the agent asks.</p>
  <script>
    const WS_URL = __WS_URL__;
    const statusEl = document.getElementById("status");
    const go = document.getElementById("go");
    const stop = document.getElementById("stop");
    let ws, recCtx, playCtx, proc, stream, playTime = 0, sending = false;

    function setStatus(t) { statusEl.textContent = t; }

    function pcmToB64(int16) {
      const u8 = new Uint8Array(int16.buffer);
      let s = "";
      const CHUNK = 0x8000;
      for (let i = 0; i < u8.length; i += CHUNK) {
        s += String.fromCharCode.apply(null, u8.subarray(i, Math.min(i + CHUNK, u8.length)));
      }
      return btoa(s);
    }

    function playPcm16(b64, rate) {
      const raw = atob(b64);
      const buf = new ArrayBuffer(raw.length);
      const view = new Uint8Array(buf);
      for (let i = 0; i < raw.length; i++) view[i] = raw.charCodeAt(i);
      const int16 = new Int16Array(buf);
      if (!playCtx) playCtx = new AudioContext({ sampleRate: rate || 24000 });
      const f32 = new Float32Array(int16.length);
      for (let i = 0; i < int16.length; i++) f32[i] = int16[i] / 32768;
      const audioBuf = playCtx.createBuffer(1, f32.length, playCtx.sampleRate);
      audioBuf.getChannelData(0).set(f32);
      const src = playCtx.createBufferSource();
      src.buffer = audioBuf;
      src.connect(playCtx.destination);
      const now = playCtx.currentTime;
      if (playTime < now) playTime = now;
      src.start(playTime);
      playTime += audioBuf.duration;
    }

    async function start() {
      stream = await navigator.mediaDevices.getUserMedia({ audio: { echoCancellation: true, noiseSuppression: true, channelCount: 1 } });
      recCtx = new AudioContext({ sampleRate: 16000 });
      const src = recCtx.createMediaStreamSource(stream);
      proc = recCtx.createScriptProcessor(2048, 1, 1);
      proc.onaudioprocess = (ev) => {
        if (!sending || !ws || ws.readyState !== 1) return;
        const f32 = ev.inputBuffer.getChannelData(0);
        const pcm = new Int16Array(f32.length);
        for (let i = 0; i < f32.length; i++) {
          const s = Math.max(-1, Math.min(1, f32[i]));
          pcm[i] = s < 0 ? s * 0x8000 : s * 0x7fff;
        }
        ws.send(JSON.stringify({ type: "pcm", data: pcmToB64(pcm) }));
      };
      src.connect(proc);
      const mute = recCtx.createGain();
      mute.gain.value = 0;
      proc.connect(mute);
      mute.connect(recCtx.destination);
      ws = new WebSocket(WS_URL);
      ws.onopen = () => { sending = true; setStatus("Live. Listening…"); };
      ws.onmessage = (ev) => {
        let msg;
        try { msg = JSON.parse(ev.data); } catch { return; }
        if (msg.type === "pcm") playPcm16(msg.data, 24000);
        if (msg.type === "card_tts") {
          const a = new Audio("data:audio/wav;base64," + msg.data);
          a.play();
        }
        if (msg.type === "status") setStatus(msg.text || "");
        if (msg.type === "error") setStatus("Error: " + msg.detail);
        if (msg.type === "done") { setStatus("Listing approved."); stopLive(); }
      };
      ws.onclose = () => { sending = false; setStatus("Live socket closed."); };
      ws.onerror = () => setStatus("Live socket error.");
      go.disabled = true; stop.disabled = false;
    }

    function stopLive() {
      sending = false;
      try { if (ws && ws.readyState === 1) ws.send(JSON.stringify({ type: "end" })); } catch {}
      try { ws && ws.close(); } catch {}
      try { proc && proc.disconnect(); } catch {}
      try { recCtx && recCtx.close(); } catch {}
      try { stream && stream.getTracks().forEach(t => t.stop()); } catch {}
      go.disabled = false; stop.disabled = true;
    }

    go.onclick = () => start().catch(err => setStatus(String(err)));
    stop.onclick = stopLive;
  </script>
</body>
</html>
"""
