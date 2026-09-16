"use client";

import Image from "next/image";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useRef, useState, type FormEvent, type ReactNode } from "react";
import {
  api,
  rememberFirebaseSession,
  rememberSession,
  sarvamAudioMimeType,
  supportedVoiceRecordingOptions,
} from "@/lib/api-client";
import { Action, Icon, StatusPill } from "./workspace-ui";

const LANGUAGES = [
  ["mr-IN", "मराठी", "Marathi"],
  ["hi-IN", "हिन्दी", "Hindi"],
  ["en-IN", "English", "English (India)"],
  ["bn-IN", "বাংলা", "Bengali"],
  ["ta-IN", "தமிழ்", "Tamil"],
  ["te-IN", "తెలుగు", "Telugu"],
  ["ml-IN", "മലയാളം", "Malayalam"],
  ["kn-IN", "ಕನ್ನಡ", "Kannada"],
  ["gu-IN", "ગુજરાતી", "Gujarati"],
  ["pa-IN", "ਪੰਜਾਬੀ", "Punjabi"],
  ["od-IN", "ଓଡ଼ିଆ", "Odia"],
  ["as-IN", "অসমীয়া", "Assamese"],
  ["ur-IN", "اردو", "Urdu"],
  ["sa-IN", "संस्कृत", "Sanskrit"],
  ["ne-IN", "नेपाली", "Nepali"],
  ["kok-IN", "कोंकणी", "Konkani"],
  ["mai-IN", "मैथिली", "Maithili"],
  ["sd-IN", "سنڌي", "Sindhi"],
  ["doi-IN", "डोगरी", "Dogri"],
  ["sat-IN", "ᱥᱟᱱᱛᱟᱲᱤ", "Santali"],
  ["mni-IN", "মৈতৈলোন্", "Manipuri"],
  ["ks-IN", "کٲشُر", "Kashmiri"],
  ["brx-IN", "बर'", "Bodo"],
] as const;

type AccessView = "language" | "otp" | "documents" | "onboarding";

const DOCUMENT_OPTIONS = [
  { id: "pm_vishwakarma", title: "PM Vishwakarma ID Card", fields: ["idNumber", "traditionalTrade", "state", "district"] },
  { id: "pahchan", title: "PAHCHAN Artisan Card", fields: ["cardNumber", "craft", "specialization", "state", "district"] },
  { id: "weaver_id", title: "Weaver ID Card", fields: ["idNumber", "weavingType", "craft", "clusterName", "state", "district"] },
  { id: "e_shram", title: "e-Shram Card", fields: ["uan", "occupation", "subOccupation", "state", "district"] },
  { id: "nfsa_ration", title: "NFSA / Ration Card", fields: ["cardNumber", "cardCategory", "nameOnCard", "familyMembers", "state", "district"] },
] as const;

const DOCUMENT_LABELS: Record<string, string> = {
  idNumber: "ID / Certificate number",
  traditionalTrade: "Traditional trade",
  state: "State",
  district: "District",
  cardNumber: "Card number",
  craft: "Craft / art form",
  specialization: "Sub-craft / specialization",
  weavingType: "Type of weaving",
  clusterName: "Cluster name",
  uan: "e-Shram UAN",
  occupation: "Occupation",
  subOccupation: "Sub-occupation",
  cardCategory: "Card category",
  nameOnCard: "Name on ration card",
  familyMembers: "Number of family members",
};

function errorMessage(cause: unknown, fallback: string) {
  return cause instanceof Error ? cause.message : fallback;
}

function AccessFrame({
  eyebrow,
  title,
  description,
  children,
}: {
  eyebrow: string;
  title: string;
  description: string;
  children: ReactNode;
}) {
  return (
    <main className="ks-access">
      <section className="ks-access-intro" aria-label="KalaSetu introduction">
        <Link className="ks-access-brand" href="/" aria-label="KalaSetu home">
          <Image src="/assets/brand/logo-transparent.png" alt="KalaSetu" width={1141} height={535} priority />
        </Link>
        <div>
          <p className="ks-eyebrow">Your craft. Your story.</p>
          <h2>Turn a photograph and your voice into a listing you control.</h2>
        </div>
        <p>Voice-first cataloging for artisans, with every generated value attributed to its source.</p>
        <Image
          className="ks-access-art"
          src="/assets/heroes/KS-Hero-transparent.png"
          alt=""
          width={1374}
          height={1145}
          priority
        />
      </section>
      <section className="ks-access-card">
        <header>
          <p className="ks-eyebrow">{eyebrow}</p>
          <h1>{title}</h1>
          <p>{description}</p>
        </header>
        {children}
      </section>
    </main>
  );
}

function VoiceLanguageDetector({
  onDetected,
}: {
  onDetected: (code: string) => void;
}) {
  const router = useRouter();
  const [status, setStatus] = useState<"idle" | "recording" | "detecting" | "detected" | "error">("idle");
  const [detectedData, setDetectedData] = useState<{
    code: string;
    name: string;
    transcript: string;
    greeting: string;
  } | null>(null);
  const [errorMessage, setErrorMessage] = useState("");
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const chunksRef = useRef<Blob[]>([]);
  const timeoutRef = useRef<number | null>(null);

  const startListening = async () => {
    try {
      setStatus("recording");
      setErrorMessage("");
      chunksRef.current = [];
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const recorderOptions = supportedVoiceRecordingOptions();
      if (!recorderOptions) {
        stream.getTracks().forEach((track) => track.stop());
        setStatus("error");
        setErrorMessage("This browser cannot create a compatible voice recording. Please choose a language below.");
        return;
      }
      const recorder = new MediaRecorder(stream, recorderOptions);
      mediaRecorderRef.current = recorder;

      recorder.ondataavailable = (event) => {
        if (event.data.size > 0) chunksRef.current.push(event.data);
      };

      recorder.onstop = async () => {
        stream.getTracks().forEach((track) => track.stop());
        const audioBlob = new Blob(chunksRef.current, { type: sarvamAudioMimeType(recorder.mimeType) });
        if (audioBlob.size === 0) {
          setStatus("error");
          setErrorMessage("कोई आवाज़ नहीं मिली। कृपया दोबारा बोलें। / No voice recorded.");
          return;
        }

        setStatus("detecting");
        try {
          const res = await api.detectLanguage(audioBlob);
          if (res.language_code) {
            setDetectedData({
              code: res.language_code,
              name: res.language_name,
              transcript: res.transcript,
              greeting: res.greeting,
            });
            setStatus("detected");
            onDetected(res.language_code);

            // Play Sarvam Bulbul welcome greeting
            if (res.audio_b64) {
              const audio = new Audio(`data:${res.content_type || "audio/wav"};base64,${res.audio_b64}`);
              void audio.play().catch(() => {});
            }

            // Auto-advance to /otp after brief confirmation
            window.setTimeout(() => {
              window.localStorage.setItem("kalasetu_language", res.language_code);
              window.dispatchEvent(new CustomEvent("kalasetu_lang_change", { detail: res.language_code }));
              router.push("/otp");
            }, 2500);
          } else {
            setStatus("error");
            setErrorMessage("भाषा पहचानी नहीं जा सकी। नीचे से चुनें। / Could not detect language.");
          }
        } catch (err) {
          setStatus("error");
          setErrorMessage(err instanceof Error ? err.message : "पहचान विफल। नीचे से चुनें।");
        }
      };

      recorder.start();
      // Auto-stop after 4 seconds
      timeoutRef.current = window.setTimeout(() => {
        if (recorder.state === "recording") {
          recorder.stop();
        }
      }, 4000);
    } catch {
      setStatus("error");
      setErrorMessage("माइक्रोफ़ोन की अनुमति नहीं मिली। कृपया नीचे सूची से चुनें।");
    }
  };

  const stopListening = () => {
    if (timeoutRef.current) window.clearTimeout(timeoutRef.current);
    if (mediaRecorderRef.current && mediaRecorderRef.current.state === "recording") {
      mediaRecorderRef.current.stop();
    }
  };

  return (
    <div className="ks-voice-lid-card">
      <div className="ks-voice-lid-header">
        <div className="ks-voice-lid-title">
          <Icon name="voice" size={22} />
          <span>बोलकर भाषा चुनें / Speak to Choose</span>
        </div>
        <span className="ks-voice-lid-badge">Sarvam AI Saaras LID</span>
      </div>

      <div className="ks-voice-lid-body">
        {status === "recording" ? (
          <button
            type="button"
            className="ks-voice-lid-btn ks-voice-lid-btn--recording"
            onClick={stopListening}
            aria-label="Stop recording"
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
            className="ks-voice-lid-btn"
            onClick={startListening}
            disabled={status === "detecting"}
            aria-label="Start recording to detect language"
          >
            <Icon name={status === "detecting" ? "rotate" : "voice"} size={26} />
          </button>
        )}

        <div className="ks-voice-lid-text">
          {status === "idle" && (
            <>
              <p className="ks-voice-lid-prompt">माइक दबाएं और अपनी भाषा में एक वाक्य बोलें</p>
              <p className="ks-voice-lid-subtext">{'उदा. "नमस्ते, मैं बुनकर हूँ" / "வணக்கம்" / "নমস্কার"'}</p>
            </>
          )}
          {status === "recording" && (
            <>
              <p className="ks-voice-lid-prompt" style={{ color: "#c2410c" }}>सुन रहे हैं... बोलिए (रोकने के लिए दोबारा दबाएं)</p>
              <p className="ks-voice-lid-subtext">Listening to your voice...</p>
            </>
          )}
          {status === "detecting" && (
            <>
              <p className="ks-voice-lid-prompt">सर्वम एआई द्वारा भाषा पहचानी जा रही है...</p>
              <p className="ks-voice-lid-subtext">Analyzing language with Sarvam Saaras LID...</p>
            </>
          )}
          {status === "detected" && detectedData && (
            <div className="ks-voice-lid-detected">
              <Icon name="check" size={20} />
              <div>
                <p className="ks-voice-lid-prompt">
                  <strong>{detectedData.name}</strong> पहचानी गई!
                </p>
                <p className="ks-voice-lid-subtext">{detectedData.greeting}</p>
              </div>
            </div>
          )}
          {status === "error" && (
            <>
              <p className="ks-voice-lid-prompt" style={{ color: "#b91c1c" }}>{errorMessage}</p>
              <p className="ks-voice-lid-subtext">आप नीचे दी गई सूची से भी चुन सकते हैं।</p>
            </>
          )}
        </div>
      </div>
    </div>
  );
}

function LanguageAccess() {
  const router = useRouter();
  const [language, setLanguage] = useState("en-IN");

  useEffect(() => {
    const timer = window.setTimeout(() => {
      const stored = window.localStorage.getItem("kalasetu_language");
      if (stored && LANGUAGES.some(([code]) => code === stored)) setLanguage(stored);
    }, 0);
    return () => window.clearTimeout(timer);
  }, []);

  const selectLanguage = async (code: string, spokenName: string) => {
    setLanguage(code);
    try {
      const res = await api.tts(spokenName, code);
      if (res.audio_b64) {
        const audio = new Audio(`data:${res.content_type || "audio/wav"};base64,${res.audio_b64}`);
        await audio.play();
        return;
      }
    } catch {
      // Fallback to browser SpeechSynthesis
    }
    if ("speechSynthesis" in window && "SpeechSynthesisUtterance" in window) {
      window.speechSynthesis.cancel();
      const utterance = new SpeechSynthesisUtterance(spokenName);
      utterance.lang = code;
      window.speechSynthesis.speak(utterance);
    }
  };

  const continueToOtp = () => {
    window.localStorage.setItem("kalasetu_language", language);
    window.dispatchEvent(new CustomEvent("kalasetu_lang_change", { detail: language }));
    router.push("/otp");
  };

  return (
    <AccessFrame
      eyebrow="Choose language"
      title="Which language feels like home?"
      description="Speak to automatically detect your language, or pick from the list below."
    >
      <VoiceLanguageDetector onDetected={(code) => setLanguage(code)} />

      <div className="ks-language-grid" role="radiogroup" aria-label="Preferred language">
        {LANGUAGES.map(([code, nativeName, englishName]) => (
          <button
            type="button"
            role="radio"
            aria-checked={language === code}
            className={language === code ? "ks-is-selected" : undefined}
            onClick={() => selectLanguage(code, nativeName)}
            key={code}
          >
            <span>{nativeName}</span>
            <small>{englishName}</small>
            <Icon name="voice" size={17} />
          </button>
        ))}
      </div>
      <div className="ks-access-actions">
        <Action icon="arrow" onClick={continueToOtp}>Continue</Action>
      </div>
    </AccessFrame>
  );
}

function OtpAccess() {
  const router = useRouter();
  const [phone, setPhone] = useState("");
  const [code, setCode] = useState("");
  const [requested, setRequested] = useState(false);
  const [busy, setBusy] = useState(false);
  const [notice, setNotice] = useState("");
  const [error, setError] = useState("");

  useEffect(() => {
    const timer = window.setTimeout(() => {
      setPhone(window.sessionStorage.getItem("kalasetu_otp_phone") || "");
    }, 0);
    return () => window.clearTimeout(timer);
  }, []);

  const requestCode = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!phone.trim()) {
      setError("Enter your phone number.");
      return;
    }
    setBusy(true);
    setError("");
    setNotice("");
    try {
      const result = await api.requestOtp(phone.trim());
      window.sessionStorage.setItem("kalasetu_otp_phone", result.phone || phone.trim());
      setPhone(result.phone || phone.trim());
      setRequested(true);
      setNotice(result.label || "Code requested.");
    } catch (cause) {
      setError(errorMessage(cause, "Could not request a code."));
    } finally {
      setBusy(false);
    }
  };

  const pressKey = (key: string) => {
    setError("");
    if (key === "backspace") {
      setCode((current) => current.slice(0, -1));
      return;
    }
    setCode((current) => current.length < 6 ? `${current}${key}` : current);
  };

  const verifyCode = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (code.length !== 6) {
      setError("Enter the complete six-digit code.");
      return;
    }
    setBusy(true);
    setError("");
    try {
      const result = await api.verifyOtp(phone, code);
      rememberSession(result.token, result.uid);
      await rememberFirebaseSession(result.firebase_custom_token);
      window.sessionStorage.removeItem("kalasetu_otp_phone");
      router.push("/documents");
      router.refresh();
    } catch (cause) {
      setError(errorMessage(cause, "The code could not be verified."));
    } finally {
      setBusy(false);
    }
  };

  useEffect(() => {
    if (!requested) return;

    const handleKeyboardInput = (event: KeyboardEvent) => {
      if (/^\d$/.test(event.key)) {
        event.preventDefault();
        setError("");
        setCode((current) => current.length < 6 ? `${current}${event.key}` : current);
        return;
      }

      if (event.key === "Backspace") {
        event.preventDefault();
        setError("");
        setCode((current) => current.slice(0, -1));
        return;
      }

      if (event.key === "Delete") {
        event.preventDefault();
        setError("");
        setCode("");
        return;
      }

      if (event.key === "Enter" && code.length === 6 && !busy) {
        event.preventDefault();
        document.querySelector<HTMLFormElement>(".ks-otp-verify")?.requestSubmit();
      }
    };

    window.addEventListener("keydown", handleKeyboardInput);
    return () => window.removeEventListener("keydown", handleKeyboardInput);
  }, [busy, code.length, requested]);

  return (
    <AccessFrame
      eyebrow="Secure access"
      title={requested ? "Enter your six-digit code" : "Start with your phone number"}
      description="KalaSetu uses the API to request and verify your one-time code."
    >
      {!requested ? (
        <form className="ks-otp-phone" onSubmit={requestCode}>
          <label>
            <span>Phone number</span>
            <input
              type="tel"
              inputMode="tel"
              autoComplete="tel"
              value={phone}
              onChange={(event) => setPhone(event.target.value)}
              placeholder="+91"
              required
            />
          </label>
          <Action type="submit" disabled={busy}>
            {busy ? "Requesting…" : "Request code"}
          </Action>
        </form>
      ) : (
        <form className="ks-otp-verify" onSubmit={verifyCode}>
          <div className="ks-otp-digits" aria-label={`${code.length} of 6 digits entered`}>
            {Array.from({ length: 6 }, (_, index) => (
              <span className={code[index] ? "ks-is-filled" : undefined} key={index}>
                {code[index] ? "•" : ""}
              </span>
            ))}
          </div>
          <div className="ks-otp-keypad" aria-label="Code keypad">
            {["1", "2", "3", "4", "5", "6", "7", "8", "9"].map((key) => (
              <button type="button" onClick={() => pressKey(key)} key={key}>{key}</button>
            ))}
            <button type="button" onClick={() => setCode("")} aria-label="Clear code">Clear</button>
            <button type="button" onClick={() => pressKey("0")}>0</button>
            <button type="button" onClick={() => pressKey("backspace")} aria-label="Delete last digit">
              <Icon name="arrow" />
            </button>
          </div>
          <p className="ks-otp-keyboard-hint">You can also type the code using your keyboard.</p>
          <div className="ks-access-actions">
            <Action
              type="button"
              tone="quiet"
              onClick={() => {
                setRequested(false);
                setCode("");
                setNotice("");
              }}
            >
              Change number
            </Action>
            <Action type="submit" disabled={busy || code.length !== 6}>
              {busy ? "Verifying…" : "Verify and continue"}
            </Action>
          </div>
        </form>
      )}
      {notice ? <p className="ks-access-notice" role="status">{notice}</p> : null}
      {error ? <p className="ks-access-error" role="alert">{error}</p> : null}
    </AccessFrame>
  );
}

function DocumentVerificationAccess() {
  const router = useRouter();
  const [selected, setSelected] = useState<(typeof DOCUMENT_OPTIONS)[number]["id"]>("pm_vishwakarma");
  const [details, setDetails] = useState<Record<string, string>>({});
  const [file, setFile] = useState<File | null>(null);
  const [consent, setConsent] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    if (!window.localStorage.getItem("kalasetu_token")) router.replace("/language");
  }, [router]);

  const selectedOption = DOCUMENT_OPTIONS.find((option) => option.id === selected) || DOCUMENT_OPTIONS[0];
  const setDocument = (id: (typeof DOCUMENT_OPTIONS)[number]["id"]) => {
    setSelected(id);
    setDetails({});
    setFile(null);
    setError("");
  };

  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!file) {
      setError("Upload a clear photo or PDF of the selected document.");
      return;
    }
    if (!consent) {
      setError("Please consent to saving this document in your KalaSetu profile.");
      return;
    }
    setBusy(true);
    setError("");
    try {
      await api.uploadDocument(selected, details, file);
      router.push("/onboarding");
      router.refresh();
    } catch (cause) {
      setError(errorMessage(cause, "The document could not be saved."));
    } finally {
      setBusy(false);
    }
  };

  return (
    <AccessFrame
      eyebrow="Step 1 of 2 · Verify your craft identity"
      title="Show us the work you already do"
      description="Choose any one document. We use it to understand your artisan identity and connect your profile with the right support."
    >
      <div className="ks-document-options" role="radiogroup" aria-label="Document type">
        {DOCUMENT_OPTIONS.map((option) => (
          <button
            key={option.id}
            type="button"
            className={selected === option.id ? "is-selected" : ""}
            onClick={() => setDocument(option.id)}
            role="radio"
            aria-checked={selected === option.id}
          >
            <span>{option.title}</span>
            <small>{selected === option.id ? "Selected" : "Choose"}</small>
          </button>
        ))}
      </div>
      <form className="ks-document-form" onSubmit={submit}>
        <section className="ks-document-fields" aria-labelledby="document-details-title">
          <div className="ks-document-fields__heading">
            <div>
              <p className="ks-eyebrow">Document details</p>
              <h2 id="document-details-title">{selectedOption.title}</h2>
            </div>
            <StatusPill tone="neutral">Private profile record</StatusPill>
          </div>
          <div className="ks-document-field-grid">
            {selectedOption.fields.map((field) => (
              <label key={field}>
                <span>{DOCUMENT_LABELS[field]}</span>
                {field === "cardCategory" ? (
                  <select value={details[field] || ""} onChange={(event) => setDetails((current) => ({ ...current, [field]: event.target.value }))} required>
                    <option value="">Choose category</option>
                    <option value="AAY">AAY</option>
                    <option value="PHH">PHH</option>
                    <option value="Other">Other</option>
                  </select>
                ) : (
                  <input
                    type={field === "familyMembers" ? "number" : "text"}
                    min={field === "familyMembers" ? "1" : undefined}
                    value={details[field] || ""}
                    onChange={(event) => setDetails((current) => ({ ...current, [field]: event.target.value }))}
                    required
                  />
                )}
              </label>
            ))}
          </div>
          <label className="ks-document-upload">
            <span>Upload document</span>
            <input type="file" accept="application/pdf,image/jpeg,image/png,image/webp" onChange={(event) => setFile(event.target.files?.[0] || null)} required />
            <small>{file ? file.name : "PDF, JPG, PNG, or WebP · max 10 MB"}</small>
          </label>
        </section>
        <label className="ks-onboarding-consent">
          <input type="checkbox" checked={consent} onChange={(event) => setConsent(event.target.checked)} />
          <span>
            <strong>I consent to save this document and its details in my KalaSetu profile.</strong>
            <small>Your document is used for profile verification and support eligibility. It is not shown publicly on listings.</small>
          </span>
        </label>
        <div className="ks-access-actions">
          <Action type="button" tone="quiet" onClick={() => router.push("/onboarding")}>I’ll add this later</Action>
          <Action type="submit" disabled={busy || !consent}>{busy ? "Saving document…" : "Save and continue"}</Action>
        </div>
      </form>
      {error ? <p className="ks-access-error" role="alert">{error}</p> : null}
    </AccessFrame>
  );
}

function OnboardingAccess() {
  const router = useRouter();
  const [name, setName] = useState("");
  const [cluster, setCluster] = useState("");
  const [pehchanId, setPehchanId] = useState("");
  const [consent, setConsent] = useState(false);
  const [busy, setBusy] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    let active = true;
    if (!window.localStorage.getItem("kalasetu_token")) {
      router.replace("/language");
      return () => {
        active = false;
      };
    }

    api.me()
      .then((result) => {
        if (!active) return;
        if (typeof result.artisan.name === "string") setName(result.artisan.name);
        if (typeof result.artisan.cluster === "string") setCluster(result.artisan.cluster);
        const pehchan = result.artisan.pehchan;
        if (pehchan && typeof pehchan === "object" && typeof (pehchan as Record<string, unknown>).id === "string") {
          setPehchanId((pehchan as Record<string, unknown>).id as string);
        }
      })
      .catch((cause) => {
        if (active) setError(errorMessage(cause, "Could not load your profile."));
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, [router]);

  const finish = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!consent) {
      setError("Please give consent before saving these profile details.");
      return;
    }
    setBusy(true);
    setError("");
    try {
      const language = window.localStorage.getItem("kalasetu_language") || "en-IN";
      await api.updateProfile({
        name: name.trim(),
        cluster: cluster.trim(),
        lang: language,
        consentAt: new Date().toISOString(),
        pehchan: {
          id: pehchanId.trim() || undefined,
          source: "self-reported",
          label: "Self-reported profile",
        },
      });
      router.push("/");
      router.refresh();
    } catch (cause) {
      setError(errorMessage(cause, "Could not save your profile."));
    } finally {
      setBusy(false);
    }
  };

  return (
    <AccessFrame
      eyebrow="Your craft identity"
      title="Tell us about you and your work"
      description="These details help keep your listings connected to your artisan profile."
    >
      {loading ? (
        <div className="ks-access-loading" role="status">Loading your profile…</div>
      ) : (
        <form className="ks-onboarding-form" onSubmit={finish}>
          <label>
            <span>Your name</span>
            <input
              value={name}
              onChange={(event) => setName(event.target.value)}
              autoComplete="name"
              required
            />
          </label>
          <label>
            <span>Craft cluster</span>
            <input
              value={cluster}
              onChange={(event) => setCluster(event.target.value)}
              placeholder="Your town, district, or artisan cluster"
              required
            />
          </label>
          <section className="ks-onboarding-identity" aria-labelledby="ks-pehchan-title">
            <div>
              <h2 id="ks-pehchan-title">Pehchan-shaped identity</h2>
              <StatusPill tone="attention">Self-reported</StatusPill>
            </div>
            <p>This information is self-reported and is not connected to a government registry.</p>
            <label>
              <span>Pehchan reference (optional)</span>
              <input value={pehchanId} onChange={(event) => setPehchanId(event.target.value)} />
            </label>
          </section>
          <section className="ks-onboarding-aadhaar" aria-labelledby="ks-aadhaar-title">
            <Icon name="camera" />
            <div>
              <h2 id="ks-aadhaar-title">Aadhaar face verification</h2>
              <p>Not captured or verified in this build.</p>
            </div>
            <StatusPill tone="attention">Not connected</StatusPill>
          </section>
          <label className="ks-onboarding-consent">
            <input
              type="checkbox"
              checked={consent}
              onChange={(event) => setConsent(event.target.checked)}
            />
            <span>
              <strong>I consent to save these details in my KalaSetu profile.</strong>
              <small>This box is intentionally unchecked until you choose it.</small>
            </span>
          </label>
          <div className="ks-access-actions">
            <Action type="submit" disabled={busy || !consent}>
              {busy ? "Saving…" : "Finish and open home"}
            </Action>
          </div>
        </form>
      )}
      {error ? <p className="ks-access-error" role="alert">{error}</p> : null}
    </AccessFrame>
  );
}

export function AccessFlow({ view }: { view: AccessView }) {
  if (view === "language") return <LanguageAccess />;
  if (view === "otp") return <OtpAccess />;
  if (view === "documents") return <DocumentVerificationAccess />;
  return <OnboardingAccess />;
}
