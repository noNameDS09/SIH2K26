# Web clients must never call Sarvam directly — only FastAPI /v1/speech/*.

from kalasetu_api.adapters.speech.sarvam import synthesize_speech, transcribe_audio

__all__ = ["synthesize_speech", "transcribe_audio"]
