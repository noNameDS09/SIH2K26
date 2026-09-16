"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { api, currentListingId, type VoiceActionResult } from "@/lib/api-client";
import { useTranslation } from "@/lib/language-context";
import { Icon } from "./workspace-ui";

type VoiceState = "idle" | "listening" | "processing" | "result" | "error";

interface VoiceAssistantDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  onReadScreen: () => void;
}

const VOICE_CHIPS: Record<string, Array<{ text: string; label: string; kind: "nav" | "ask" }>> = {
  "hi-IN": [
    { text: "दुकान खोलो", label: "दुकान खोलो", kind: "nav" },
    { text: "नया उत्पाद जोड़ो", label: "नया उत्पाद जोड़ो", kind: "nav" },
    { text: "कमाई का खाता", label: "कमाई का खाता", kind: "nav" },
    { text: "व्यापार सलाह", label: "व्यापार सलाह", kind: "nav" },
    { text: "मेरा यह दाम कैसे तय हुआ?", label: "दाम कैसे तय हुआ?", kind: "ask" },
    { text: "GI टैग का क्या फायदा है?", label: "GI टैग का क्या फायदा?", kind: "ask" },
    { text: "GeM पोर्टल क्या है?", label: "GeM पोर्टल क्या है?", kind: "ask" },
    { text: "स्क्रीन पढ़कर सुनाओ", label: "स्क्रीन सुनाओ", kind: "nav" },
  ],
  "mr-IN": [
    { text: "दुकान उघडा", label: "दुकान उघडा", kind: "nav" },
    { text: "नवीन उत्पादन", label: "नवीन उत्पादन", kind: "nav" },
    { text: "विक्री खाते", label: "विक्री खाते", kind: "nav" },
    { text: "व्यापार सल्ला", label: "व्यापार सल्ला", kind: "nav" },
    { text: "हा भाव कसा ठरवला गेला?", label: "भाव कसा ठरवला?", kind: "ask" },
    { text: "GI टॅगचा काय फायदा आहे?", label: "GI टॅगचा फायदा?", kind: "ask" },
    { text: "स्क्रीन वाचून दाखवा", label: "स्क्रीन वाचा", kind: "nav" },
  ],
  "ta-IN": [
    { text: "கடை திற", label: "கடை திற", kind: "nav" },
    { text: "புதிய தயாரிப்பு", label: "புதிய தயாரிப்பு", kind: "nav" },
    { text: "விற்பனை பதிவு", label: "விற்பனை பதிவு", kind: "nav" },
    { text: "விலை எப்படி நிர்ணயிக்கப்பட்டது?", label: "விலை நிர்ணயம்?", kind: "ask" },
    { text: "திரையை வாசி", label: "திரையை வாசி", kind: "nav" },
  ],
  "te-IN": [
    { text: "షాప్ తెరువు", label: "షాప్ తెరువు", kind: "nav" },
    { text: "కొత్త ఉత్పత్తి", label: "కొత్త ఉత్పత్తి", kind: "nav" },
    { text: "అమ్మకాల రికార్డు", label: "అమ్మకాల రికార్డు", kind: "nav" },
    { text: "ధర ఎలా నిర్ణయించబడింది?", label: "ధర నిర్ణయం?", kind: "ask" },
  ],
  "bn-IN": [
    { text: "দোকান খুলুন", label: "দোকান খুলুন", kind: "nav" },
    { text: "নতুন পণ্য যোগ করুন", label: "নতুন পণ্য", kind: "nav" },
    { text: "বিক্রির খাতা", label: "বিক্রির খাতা", kind: "nav" },
    { text: "দাম কীভাবে নির্ধারিত হয়েছে?", label: "দাম কীভাবে?", kind: "ask" },
  ],
  "en-IN": [
    { text: "Open shop", label: "Open shop", kind: "nav" },
    { text: "Add product", label: "Add product", kind: "nav" },
    { text: "Trade Record", label: "Trade Record", kind: "nav" },
    { text: "Advisor insights", label: "Advisor insights", kind: "nav" },
    { text: "How is my price calculated?", label: "How is price calculated?", kind: "ask" },
    { text: "What are the benefits of a GI Tag?", label: "GI Tag benefits?", kind: "ask" },
    { text: "Read the screen aloud", label: "Read screen", kind: "nav" },
  ],
};

export function VoiceAssistantDrawer({
  isOpen,
  onClose,
  onReadScreen,
}: VoiceAssistantDrawerProps) {
  const router = useRouter();
  const { currentLanguage } = useTranslation();
  const langCode = currentLanguage.code || "hi-IN";

  const [state, setState] = useState<VoiceState>("idle");
  const [transcript, setTranscript] = useState("");
  const [result, setResult] = useState<VoiceActionResult | null>(null);
  const [errorMessage, setErrorMessage] = useState("");
  const [audioUrl, setAudioUrl] = useState<string | null>(null);

  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const chunksRef = useRef<Blob[]>([]);
  const timeoutRef = useRef<number | null>(null);
  const audioPlayerRef = useRef<HTMLAudioElement | null>(null);

  const stopListening = useCallback(() => {
    if (timeoutRef.current) window.clearTimeout(timeoutRef.current);
    if (mediaRecorderRef.current && mediaRecorderRef.current.state === "recording") {
      mediaRecorderRef.current.stop();
    }
  }, []);

  const handleClose = useCallback(() => {
    stopListening();
    if (audioPlayerRef.current) {
      audioPlayerRef.current.pause();
      audioPlayerRef.current = null;
    }
    setState("idle");
    setTranscript("");
    setResult(null);
    setErrorMessage("");
    setAudioUrl(null);
    onClose();
  }, [onClose, stopListening]);

  // Close on Escape key
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape" && isOpen) {
        handleClose();
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isOpen, handleClose]);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (mediaRecorderRef.current && mediaRecorderRef.current.state === "recording") {
        mediaRecorderRef.current.stop();
      }
      if (timeoutRef.current) window.clearTimeout(timeoutRef.current);
      if (audioPlayerRef.current) {
        audioPlayerRef.current.pause();
        audioPlayerRef.current = null;
      }
    };
  }, []);

  if (!isOpen) return null;

  const playBase64Audio = (b64: string, contentType = "audio/wav") => {
    try {
      if (audioPlayerRef.current) {
        audioPlayerRef.current.pause();
      }
      const audio = new Audio(`data:${contentType};base64,${b64}`);
      audioPlayerRef.current = audio;
      audio.play().catch(() => {});
    } catch {
      // Audio playback failed
    }
  };

  const handleActionExecution = (actionResult: VoiceActionResult) => {
    setResult(actionResult);
    setState("result");

    if (actionResult.audio_b64) {
      setAudioUrl(`data:${actionResult.content_type || "audio/wav"};base64,${actionResult.audio_b64}`);
      playBase64Audio(actionResult.audio_b64, actionResult.content_type || "audio/wav");
    }

    if (actionResult.action === "navigate" && actionResult.target) {
      // Allow audio to start playing, then navigate smoothly
      window.setTimeout(() => {
        handleClose();
        router.push(actionResult.target as string);
      }, 1600);
    } else if (actionResult.action === "read_screen") {
      window.setTimeout(() => {
        handleClose();
        onReadScreen();
      }, 1200);
    } else if (actionResult.action === "back") {
      window.setTimeout(() => {
        handleClose();
        router.back();
      }, 1400);
    }
  };

  const startListening = async () => {
    try {
      setState("listening");
      setErrorMessage("");
      setTranscript("");
      chunksRef.current = [];

      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const recorder = new MediaRecorder(stream);
      mediaRecorderRef.current = recorder;

      recorder.ondataavailable = (event) => {
        if (event.data.size > 0) chunksRef.current.push(event.data);
      };

      recorder.onstop = async () => {
        stream.getTracks().forEach((track) => track.stop());
        const audioBlob = new Blob(chunksRef.current, { type: recorder.mimeType || "audio/webm" });
        if (audioBlob.size === 0) {
          setState("error");
          setErrorMessage("कोई आवाज़ रिकॉर्ड नहीं हुई। कृपया दोबारा बोलें।");
          return;
        }

        setState("processing");
        try {
          const actionResult = await api.voiceAction({
            file: audioBlob,
            language_code: langCode,
            listing_id: currentListingId() || undefined,
          });
          setTranscript(actionResult.transcript);
          handleActionExecution(actionResult);
        } catch (err) {
          setState("error");
          setErrorMessage(err instanceof Error ? err.message : "वॉइस कमांड निष्पादित नहीं हो सका।");
        }
      };

      recorder.start();
      // Record up to 4.5 seconds
      timeoutRef.current = window.setTimeout(() => {
        if (recorder.state === "recording") {
          recorder.stop();
        }
      }, 4500);
    } catch {
      setState("error");
      setErrorMessage("माइक्रोफ़ोन तक पहुँच नहीं मिली। कृपया अनुमति जांचें।");
    }
  };

  const handleChipClick = async (chipText: string) => {
    setState("processing");
    setTranscript(chipText);
    setErrorMessage("");
    try {
      const actionResult = await api.voiceAction({
        transcript: chipText,
        language_code: langCode,
        listing_id: currentListingId() || undefined,
      });
      handleActionExecution(actionResult);
    } catch (err) {
      setState("error");
      setErrorMessage(err instanceof Error ? err.message : "कमांड प्रोसेस नहीं हो सका।");
    }
  };

  const chips = VOICE_CHIPS[langCode] || VOICE_CHIPS["hi-IN"] || [];

  return (
    <div className="ks-voice-modal-backdrop" onClick={handleClose} role="dialog" aria-modal="true">
      <div className="ks-voice-dialog" onClick={(e) => e.stopPropagation()}>
        <div className="ks-voice-dialog-header">
          <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
            <span style={{ fontSize: "1.15rem", fontWeight: 750, color: "var(--ks-ink)" }}>
              कलासेतु सहायक
            </span>
            <span className="ks-voice-lid-badge" style={{ fontSize: "0.72rem" }}>
              Sarvam AI Voice + Gemini Flash
            </span>
          </div>
          <button
            type="button"
            className="ks-voice-dialog-close"
            onClick={handleClose}
            aria-label="Close voice assistant"
          >
            <Icon name="close" size={20} />
          </button>
        </div>

        <div className="ks-voice-mic-hero">
          {state === "listening" ? (
            <button
              type="button"
              className="ks-voice-mic-circle ks-voice-mic-circle--listening"
              onClick={stopListening}
              aria-label="Stop listening"
            >
              <div className="ks-voice-wave-bars">
                <span className="ks-voice-wave-bar" />
                <span className="ks-voice-wave-bar" />
                <span className="ks-voice-wave-bar" />
                <span className="ks-voice-wave-bar" />
                <span className="ks-voice-wave-bar" />
              </div>
            </button>
          ) : (
            <button
              type="button"
              className="ks-voice-mic-circle"
              onClick={startListening}
              disabled={state === "processing"}
              aria-label="Tap to speak"
            >
              <Icon name={state === "processing" ? "rotate" : "voice"} size={32} />
            </button>
          )}

          <div>
            {state === "idle" && (
              <>
                <p style={{ margin: 0, fontWeight: 700, fontSize: "1.05rem", color: "var(--ks-ink)" }}>
                  माइक दबाएं और बोलें
                </p>
                <p style={{ margin: "4px 0 0", fontSize: "0.85rem", color: "var(--ks-ink-soft)" }}>
                  बोलकर ऐप चलाएं या अपने शिल्प और दाम के बारे में कोई भी प्रश्न पूछें।
                </p>
              </>
            )}

            {state === "listening" && (
              <>
                <p style={{ margin: 0, fontWeight: 700, fontSize: "1.05rem", color: "#c2410c" }}>
                  सुन रहे हैं... बोलिए
                </p>
                <p style={{ margin: "4px 0 0", fontSize: "0.85rem", color: "var(--ks-ink-soft)" }}>
                  रोकने के लिए दोबारा टैप करें।
                </p>
              </>
            )}

            {state === "processing" && (
              <>
                <p style={{ margin: 0, fontWeight: 700, fontSize: "1.05rem", color: "var(--ks-ink)" }}>
                  सर्वम एआई द्वारा समझा जा रहा है...
                </p>
                <p style={{ margin: "4px 0 0", fontSize: "0.85rem", color: "var(--ks-ink-soft)" }}>
                  Transcribing & reasoning with Sarvam + Gemini...
                </p>
              </>
            )}

            {state === "error" && (
              <>
                <p style={{ margin: 0, fontWeight: 700, fontSize: "0.95rem", color: "#b91c1c" }}>
                  {errorMessage}
                </p>
                <p style={{ margin: "4px 0 0", fontSize: "0.82rem", color: "var(--ks-ink-soft)" }}>
                  कृपया पुनः प्रयास करें या नीचे दिए गए सुझावों पर टैप करें।
                </p>
              </>
            )}
          </div>
        </div>

        {/* Display result card */}
        {state === "result" && result && (
          <div className="ks-voice-result-card">
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
              <span style={{ fontSize: "0.78rem", fontWeight: 700, color: "var(--ks-ink-soft)", textTransform: "uppercase" }}>
                {result.intent === "navigation" ? "नेविगेशन" : "कलासेतु सहायक का उत्तर"}
              </span>
              {audioUrl ? (
                <button
                  type="button"
                  onClick={() => audioUrl && new Audio(audioUrl).play().catch(() => {})}
                  style={{ background: "none", border: "none", cursor: "pointer", color: "var(--ks-ink)", display: "flex", alignItems: "center", gap: "4px", fontSize: "0.78rem", fontWeight: 600 }}
                >
                  <Icon name="voice" size={14} /> पुनः सुनें
                </button>
              ) : null}
            </div>

            {transcript ? (
              <p style={{ margin: "2px 0 4px", fontSize: "0.85rem", color: "var(--ks-ink-soft)", fontStyle: "italic" }}>
                &ldquo;{transcript}&rdquo;
              </p>
            ) : null}

            <p className="ks-voice-result-spoken">
              {result.spoken || result.answer}
            </p>

            {result.action === "navigate" && result.target ? (
              <p style={{ margin: "6px 0 0", fontSize: "0.82rem", color: "#2563eb", fontWeight: 600 }}>
                {result.target} पर ले जा रहे हैं...
              </p>
            ) : null}
          </div>
        )}

        {/* Suggested Quick Commands & Questions */}
        <div>
          <p style={{ margin: "0 0 8px", fontSize: "0.82rem", fontWeight: 700, color: "var(--ks-ink-soft)", textTransform: "uppercase", letterSpacing: "0.04em" }}>
            त्वरित सुझाव / Quick actions
          </p>
          <div className="ks-voice-suggestions">
            {chips.map((chip) => (
              <button
                type="button"
                className="ks-voice-suggestion-chip"
                key={chip.text}
                onClick={() => handleChipClick(chip.text)}
              >
                {chip.kind === "nav" ? "⚡ " : "💬 "}
                {chip.label}
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
