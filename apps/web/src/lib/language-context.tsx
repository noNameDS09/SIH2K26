"use client";

import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  useSyncExternalStore,
} from "react";
import { SARVAM_LANGUAGES, getLanguageInfo, type LanguageInfo } from "./i18n/languages";
import { translate } from "./i18n/translations";
import { api } from "./api-client";

interface LanguageContextValue {
  language: string;
  setLanguage: (code: string) => void;
  t: (key: string, fallback?: string) => string;
  currentLanguage: LanguageInfo;
  availableLanguages: LanguageInfo[];
  isRTL: boolean;
  speakLanguage: (code: string, textToSpeak?: string) => Promise<void>;
  isModalOpen: boolean;
  openModal: () => void;
  closeModal: () => void;
}

const LanguageContext = createContext<LanguageContextValue | null>(null);

const STORAGE_KEY = "kalasetu_language";
const DEFAULT_LANGUAGE = "en-IN";

function subscribe(callback: () => void) {
  window.addEventListener("storage", callback);
  window.addEventListener("kalasetu_lang_change", callback);
  return () => {
    window.removeEventListener("storage", callback);
    window.removeEventListener("kalasetu_lang_change", callback);
  };
}

function getSnapshot(): string {
  if (typeof window === "undefined") return DEFAULT_LANGUAGE;
  return window.localStorage.getItem(STORAGE_KEY) || DEFAULT_LANGUAGE;
}

function getServerSnapshot(): string {
  return DEFAULT_LANGUAGE;
}

export function LanguageProvider({ children }: { children: React.ReactNode }) {
  const currentLang = useSyncExternalStore(subscribe, getSnapshot, getServerSnapshot);
  const [isModalOpen, setIsModalOpen] = useState(false);

  useEffect(() => {
    if (typeof document !== "undefined") {
      document.documentElement.lang = currentLang.split("-")[0];
      const info = getLanguageInfo(currentLang);
      document.documentElement.dir = info.script === "rtl" ? "rtl" : "ltr";
    }
  }, [currentLang]);

  const setLanguage = useCallback((code: string) => {
    if (typeof window === "undefined") return;
    window.localStorage.setItem(STORAGE_KEY, code);
    window.dispatchEvent(new Event("kalasetu_lang_change"));

    // Sync to backend profile in background if logged in
    const token = window.localStorage.getItem("kalasetu_token");
    if (token) {
      api.updateProfile({ lang: code }).catch(() => {
        // Non-blocking sync
      });
    }
  }, []);

  const t = useCallback(
    (key: string, fallback?: string) => {
      return translate(key, currentLang, fallback);
    },
    [currentLang]
  );

  const speakLanguage = useCallback(async (code: string, textToSpeak?: string) => {
    const info = getLanguageInfo(code);
    const phrase = textToSpeak || `${info.nativeName}`;

    // Try Sarvam TTS first via API
    try {
      const res = await api.tts(phrase, code);
      if (res.audio_b64) {
        const audio = new Audio(`data:${res.content_type || "audio/wav"};base64,${res.audio_b64}`);
        await audio.play();
        return;
      }
    } catch {
      // Fallback to browser SpeechSynthesis
    }

    if (typeof window !== "undefined" && "speechSynthesis" in window) {
      window.speechSynthesis.cancel();
      const utterance = new SpeechSynthesisUtterance(phrase);
      utterance.lang = code;
      window.speechSynthesis.speak(utterance);
    }
  }, []);

  const currentLanguageInfo = useMemo(() => getLanguageInfo(currentLang), [currentLang]);
  const isRTL = currentLanguageInfo.script === "rtl";

  const value = useMemo(
    () => ({
      language: currentLang,
      setLanguage,
      t,
      currentLanguage: currentLanguageInfo,
      availableLanguages: SARVAM_LANGUAGES,
      isRTL,
      speakLanguage,
      isModalOpen,
      openModal: () => setIsModalOpen(true),
      closeModal: () => setIsModalOpen(false),
    }),
    [currentLang, setLanguage, t, currentLanguageInfo, isRTL, speakLanguage, isModalOpen]
  );

  return (
    <LanguageContext.Provider value={value}>
      {children}
      {isModalOpen && <GlobalLanguageModal />}
    </LanguageContext.Provider>
  );
}

export function useTranslation() {
  const context = useContext(LanguageContext);
  if (!context) {
    throw new Error("useTranslation must be used within a LanguageProvider");
  }
  return context;
}

export function GlobalLanguageModal() {
  const { language, setLanguage, availableLanguages, closeModal, speakLanguage, t } =
    useTranslation();

  const handleSelect = (code: string, nativeName: string) => {
    setLanguage(code);
    speakLanguage(code, nativeName);
    closeModal();
  };

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="lang-modal-title"
      style={{
        position: "fixed",
        inset: 0,
        zIndex: 9999,
        display: "grid",
        placeItems: "center",
        backgroundColor: "rgba(35, 27, 18, 0.65)",
        backdropFilter: "blur(6px)",
        padding: "16px",
      }}
      onClick={(e) => {
        if (e.target === e.currentTarget) closeModal();
      }}
    >
      <div
        style={{
          width: "min(100%, 640px)",
          maxHeight: "85vh",
          display: "flex",
          flexDirection: "column",
          backgroundColor: "#FFF9EF",
          border: "1px solid rgba(81, 70, 47, 0.18)",
          borderRadius: "18px",
          boxShadow: "0 24px 60px rgba(0, 0, 0, 0.25)",
          overflow: "hidden",
        }}
      >
        <div
          style={{
            padding: "20px 24px",
            borderBottom: "1px solid rgba(81, 70, 47, 0.12)",
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
          }}
        >
          <div>
            <span
              style={{
                fontSize: "0.75rem",
                textTransform: "uppercase",
                letterSpacing: "0.08em",
                color: "#7E6B4A",
                fontWeight: 600,
              }}
            >
              {t("access.choose_language", "Choose language")}
            </span>
            <h2
              id="lang-modal-title"
              style={{
                margin: "4px 0 0",
                fontSize: "1.4rem",
                color: "#2C2216",
                fontWeight: 700,
              }}
            >
              {t("access.language_title", "Which language feels like home?")}
            </h2>
          </div>
          <button
            type="button"
            onClick={closeModal}
            aria-label="Close modal"
            style={{
              background: "rgba(81, 70, 47, 0.08)",
              border: "none",
              borderRadius: "50%",
              width: "36px",
              height: "36px",
              display: "grid",
              placeItems: "center",
              cursor: "pointer",
              fontSize: "1.2rem",
              color: "#51462F",
            }}
          >
            ×
          </button>
        </div>

        <div
          style={{
            padding: "20px 24px",
            overflowY: "auto",
            display: "grid",
            gridTemplateColumns: "repeat(auto-fill, minmax(130px, 1fr))",
            gap: "10px",
          }}
        >
          {availableLanguages.map((lang) => {
            const isSelected = language === lang.code;
            return (
              <button
                key={lang.code}
                type="button"
                onClick={() => handleSelect(lang.code, lang.nativeName)}
                style={{
                  padding: "12px 14px",
                  borderRadius: "12px",
                  border: isSelected
                    ? "2px solid #D97706"
                    : "1px solid rgba(81, 70, 47, 0.14)",
                  backgroundColor: isSelected ? "#FEF3C7" : "#FFFFFF",
                  textAlign: "left",
                  cursor: "pointer",
                  display: "flex",
                  flexDirection: "column",
                  gap: "4px",
                  transition: "all 0.15s ease",
                }}
              >
                <span
                  style={{
                    fontSize: "1rem",
                    fontWeight: 700,
                    color: isSelected ? "#92400E" : "#2C2216",
                  }}
                >
                  {lang.nativeName}
                </span>
                <span
                  style={{
                    fontSize: "0.75rem",
                    color: "#7E6B4A",
                  }}
                >
                  {lang.englishName}
                </span>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}
