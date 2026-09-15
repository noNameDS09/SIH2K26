"use client";

import Image from "next/image";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useState, type FormEvent, type ReactNode } from "react";
import {
  api,
  rememberFirebaseSession,
  rememberSession,
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

type AccessView = "language" | "otp" | "onboarding";

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

  const selectLanguage = (code: string, spokenName: string) => {
    setLanguage(code);
    if ("speechSynthesis" in window && "SpeechSynthesisUtterance" in window) {
      window.speechSynthesis.cancel();
      const utterance = new SpeechSynthesisUtterance(spokenName);
      utterance.lang = code;
      window.speechSynthesis.speak(utterance);
    }
  };

  const continueToOtp = () => {
    window.localStorage.setItem("kalasetu_language", language);
    router.push("/otp");
  };

  return (
    <AccessFrame
      eyebrow="Choose language"
      title="Which language feels like home?"
      description="Choose one now. You can change it later in Settings."
    >
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
      router.push("/onboarding");
      router.refresh();
    } catch (cause) {
      setError(errorMessage(cause, "The code could not be verified."));
    } finally {
      setBusy(false);
    }
  };

  return (
    <AccessFrame
      eyebrow="Secure access"
      title={requested ? "Enter your six-digit code" : "Start with your phone number"}
      description="KalaSetu uses the API to request and verify your one-time code."
    >
      <StatusPill tone="mock">Mock — for SIH demo · code 123456</StatusPill>
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
  }, []);

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
          label: "Mock — for SIH demo",
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
              <StatusPill tone="mock">Mock — for SIH demo</StatusPill>
            </div>
            <p>This is self-reported for the demonstration and is not connected to a government registry.</p>
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
            <StatusPill tone="mock">Mock — for SIH demo</StatusPill>
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
  return <OnboardingAccess />;
}
