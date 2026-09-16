"use client";

import {
  useEffect,
  useRef,
  useState,
  type ChangeEvent,
  type FormEvent,
} from "react";
import { useRouter } from "next/navigation";
import {
  api,
  currentListingId,
  rememberListing,
  sarvamAudioMimeType,
  supportedVoiceRecordingOptions,
  type Listing,
  type PriceBreakdown,
  type Provenance as ProvenanceData,
} from "@/lib/api-client";
import {
  Action,
  EmptyState,
  Icon,
  PageIntro,
  ProductMedia,
  Provenance,
  Skeleton,
  StatusPill,
} from "@/components/workspace/workspace-ui";

const STUDIO_PRESETS = [
  { id: "white", label: "White", src: "/bg/white.jpg" },
  { id: "linen", label: "Linen", src: "/bg/linen.jpg" },
  { id: "beige", label: "Beige", src: "/bg/beige.jpg" },
  { id: "slate", label: "Slate", src: "/bg/slate.jpg" },
  { id: "jute", label: "Jute", src: "/bg/jute.jpg" },
  { id: "wood", label: "Wood", src: "/bg/wood.jpg" },
] as const;

const EDITABLE_FIELDS = [
  { key: "craft", label: "Craft", type: "text" },
  { key: "material", label: "Material", type: "text" },
  { key: "technique", label: "Technique", type: "text" },
  { key: "colour", label: "Colour", type: "text" },
  { key: "occasion", label: "Occasion", type: "text" },
  { key: "gi", label: "GI status", type: "text" },
  { key: "hours", label: "Hours of work", type: "number" },
  { key: "material_cost_inr", label: "Material cost (₹)", type: "number" },
  { key: "material_source", label: "Material source", type: "text" },
  { key: "effort", label: "Effort", type: "text" },
] as const;

const PRICE_BANDS = [
  {
    key: "floor",
    title: "Minimum sustainable",
    description: "Covers the known material, labour, and overhead costs.",
  },
  {
    key: "recommended",
    title: "Recommended",
    description: "Balances your costs with comparable handmade work.",
  },
  {
    key: "aspirational",
    title: "Higher opportunity",
    description: "A higher test price when the market supports it.",
  },
] as const;

const APPROVAL_CONFIRMATIONS = [
  "The product details are correct.",
  "The listed price is my decision.",
  "The story represents my work accurately.",
  "The public card contains no claims I do not recognise.",
] as const;

const EXPORT_CHANNELS = [
  { id: "gem", label: "GeM" },
  { id: "ondc", label: "ONDC" },
  { id: "ih", label: "India Handmade" },
] as const;

type EditableFieldKey = (typeof EDITABLE_FIELDS)[number]["key"];
type EditableValues = Record<EditableFieldKey, string>;
type PriceBandKey = (typeof PRICE_BANDS)[number]["key"];

function WorkspaceShell({
  children,
}: {
  view: string;
  children: React.ReactNode;
}) {
  return <>{children}</>;
}

function errorMessage(cause: unknown, fallback: string) {
  return cause instanceof Error ? cause.message : fallback;
}

function productImage(listing: Listing | null) {
  return (
    listing?.studioUrl ||
    listing?.originalUrl ||
    listing?.photo_url ||
    listing?.image_url ||
    ""
  );
}

function originalImage(listing: Listing | null) {
  return listing?.originalUrl || listing?.photo_url || listing?.image_url || "";
}

function listingTitle(listing: Listing | null) {
  return listing?.title_en || listing?.title || listing?.title_hi || String(listing?.fields?.craft || "Untitled product");
}

function listingDescription(listing: Listing | null) {
  if (!listing) return "";
  return listing.desc_en || listing.description || listing.desc_hi ||
    `A handcrafted ${String(listing.fields?.craft || "product")} made with ${String(listing.fields?.material || "care")} using ${String(listing.fields?.technique || "traditional techniques")}.`;
}

function persistedValue(value: unknown): unknown {
  if (value && typeof value === "object" && "value" in value) {
    return (value as { value?: unknown }).value;
  }
  return value;
}

function listedPrice(listing: Listing | null) {
  const listed = listing?.prices?.listed?.value;
  if (typeof listed === "number") return listed;
  return typeof listing?.price_hint === "number" ? listing.price_hint : undefined;
}

function formatMoney(value?: number) {
  return typeof value === "number"
    ? `₹${value.toLocaleString("en-IN")}`
    : "Not available";
}

function storedLanguage() {
  if (typeof window === "undefined") return "en-IN";
  return window.localStorage.getItem("kalasetu_language") || "en-IN";
}

function listingProvenance(listing: Listing | null) {
  const values = listing?.provenance;
  return Array.isArray(values) && values.length ? values[values.length - 1] : undefined;
}

function Notice({
  children,
  tone = "status",
}: {
  children: React.ReactNode;
  tone?: "status" | "error";
}) {
  return (
    <p
      className={`ks-notice ks-notice--${tone}`}
      role={tone === "error" ? "alert" : "status"}
    >
      {children}
    </p>
  );
}

export function CapturePage() {
  const router = useRouter();
  const [file, setFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    return () => {
      if (previewUrl) URL.revokeObjectURL(previewUrl);
    };
  }, [previewUrl]);

  const selectFile = (event: ChangeEvent<HTMLInputElement>) => {
    const selected = event.target.files?.[0];
    if (!selected) return;

    if (!selected.type.startsWith("image/")) {
      setError("Choose an image file for your product.");
      event.target.value = "";
      return;
    }

    setFile(selected);
    setPreviewUrl(URL.createObjectURL(selected));
    setError("");
  };

  const removeFile = () => {
    setFile(null);
    setPreviewUrl("");
    setError("");
  };

  const createDraft = async () => {
    if (!file || busy) {
      setError("Choose or take a product photo first.");
      return;
    }

    setBusy(true);
    setError("");

    try {
      const draft = await api.createListing({ fields: {} });
      rememberListing(draft.id);
      await api.enhance(draft.id, {
        file,
        bgPreset: "linen",
      });
      router.push("/studio");
    } catch (cause) {
      setError(errorMessage(cause, "The product photo could not be uploaded."));
    } finally {
      setBusy(false);
    }
  };

  return (
    <WorkspaceShell view="capture">
      <section className="ks-creation-page ks-capture-page">
        <PageIntro
          eyebrow="Step 1 · Capture"
          title="Photograph your product"
          description="Use one clear, complete photo. KalaSetu keeps the original before preparing the studio version."
          aside={<StatusPill tone="neutral">Original always retained</StatusPill>}
        />

        <div className="ks-capture-grid" data-reveal>
          <div className="ks-capture-stage">
            {previewUrl ? (
              <div className="ks-capture-preview">
                <ProductMedia
                  src={previewUrl}
                  alt="Selected product photograph"
                  emptyLabel="Choose a product photo"
                />
                <button
                  className="ks-media-remove"
                  type="button"
                  onClick={removeFile}
                  disabled={busy}
                >
                  <Icon name="close" size={16} />
                  Remove photo
                </button>
              </div>
            ) : (
              <div className="ks-capture-frame">
                <span className="ks-capture-frame__corner" aria-hidden="true" />
                <Icon name="camera" size={38} />
                <h2>Keep the whole product inside the frame</h2>
                <p>Your product remains the focus here.</p>
              </div>
            )}

            <div className="ks-capture-inputs">
              <label className="ks-file-action">
                <Icon name="camera" size={19} />
                <span>Take a photo</span>
                <input
                  type="file"
                  accept="image/*"
                  capture="environment"
                  onChange={selectFile}
                  disabled={busy}
                />
              </label>
              <label className="ks-file-action ks-file-action--secondary">
                <Icon name="upload" size={19} />
                <span>Choose from device</span>
                <input
                  type="file"
                  accept="image/*"
                  onChange={selectFile}
                  disabled={busy}
                />
              </label>
            </div>
          </div>

          <aside className="ks-guidance-card">
            <h2>A strong product photo</h2>
            <ul>
              <li>Use soft, even daylight.</li>
              <li>Show one product and all its edges.</li>
              <li>Hold the camera steady.</li>
              <li>Avoid filters that change the craft colour.</li>
            </ul>
            <p>
              The studio will adjust light only and keep the original if the
              colour-quality gate does not pass.
            </p>
          </aside>
        </div>

        {error ? <Notice tone="error">{error}</Notice> : null}

        <div className="ks-page-actions" data-reveal>
          <Action href="/shop" tone="quiet">
            Save for later
          </Action>
          <Action onClick={createDraft} disabled={!file || busy} icon="arrow">
            {busy ? "Preparing studio…" : "Continue to studio"}
          </Action>
        </div>
      </section>
    </WorkspaceShell>
  );
}

export function StudioPage() {
  const [listing, setListing] = useState<Listing | null>(null);
  const [loading, setLoading] = useState(true);
  const [busyPreset, setBusyPreset] = useState("");
  const [selectedPreset, setSelectedPreset] = useState("linen");
  const [showOriginal, setShowOriginal] = useState(false);
  const [cacheStamp, setCacheStamp] = useState(0);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  useEffect(() => {
    const id = currentListingId();
    if (!id) {
      const timer = window.setTimeout(() => setLoading(false), 0);
      return () => window.clearTimeout(timer);
    }

    api
      .getListing(id)
      .then((value) => {
        setListing(value);
        const preset = String(value.bgPreset || "linen").toLowerCase();
        if (STUDIO_PRESETS.some((item) => item.id === preset)) {
          setSelectedPreset(preset);
        }
      })
      .catch((cause) => {
        setError(errorMessage(cause, "The product draft could not be loaded."));
      })
      .finally(() => setLoading(false));
  }, []);

  const applyPreset = async (preset: string) => {
    if (!listing || busyPreset) return;

    setBusyPreset(preset);
    setSelectedPreset(preset);
    setShowOriginal(false);
    setError("");
    setMessage("");

    try {
      const result = await api.enhance(listing.id, {
        bgPreset: preset,
        craft: String(listing.fields?.craft || listing.craft || ""),
      });
      const refreshed = await api.getListing(listing.id);
      setListing({
        ...refreshed,
        originalUrl: result.original_url,
        studioUrl: result.studio_url,
        bgPreset: result.bg_preset,
        deltaE: result.deltaE,
        provenance: result.provenance
          ? [...(refreshed.provenance || []), result.provenance]
          : refreshed.provenance,
      });
      setCacheStamp((value) => value + 1);
      setMessage(
        result.accepted
          ? `Studio ready. Colour difference ΔE ${result.deltaE.toFixed(2)}.`
          : "The colour-quality gate did not pass, so KalaSetu kept the original photo.",
      );
    } catch (cause) {
      setError(errorMessage(cause, "The selected background could not be applied."));
    } finally {
      setBusyPreset("");
    }
  };

  if (loading) {
    return (
      <WorkspaceShell view="studio">
        <section className="ks-creation-page" aria-busy="true">
          <PageIntro
            eyebrow="Step 2 · Studio"
            title="Preparing your image studio"
          />
          <div className="ks-studio-grid" data-reveal>
            <Skeleton className="ks-skeleton--media" />
            <Skeleton className="ks-skeleton--panel" />
          </div>
        </section>
      </WorkspaceShell>
    );
  }

  if (!listing) {
    return (
      <WorkspaceShell view="studio">
        <section className="ks-creation-page">
          <PageIntro
            eyebrow="Step 2 · Studio"
            title="Create a studio-ready image"
          />
          {error ? <Notice tone="error">{error}</Notice> : null}
          <EmptyState
            icon="camera"
            title="No product photo yet"
            description="Capture a product first so the studio can reuse its stored original."
            action={<Action href="/capture">Capture product</Action>}
          />
        </section>
      </WorkspaceShell>
    );
  }

  const original = originalImage(listing);
  const studio = listing.studioUrl || "";
  const selectedImage = showOriginal ? original : studio || original;
  const imageWithStamp =
    selectedImage && cacheStamp
      ? `${selectedImage}${selectedImage.includes("?") ? "&" : "?"}t=${cacheStamp}`
      : selectedImage;
  const delta = typeof listing.deltaE === "number" ? listing.deltaE : undefined;

  return (
    <WorkspaceShell view="studio">
      <section className="ks-creation-page ks-studio-page">
        <PageIntro
          eyebrow="Step 2 · Studio"
          title="Choose a calm product background"
          description="Each preset reprocesses the stored original. The product itself is never generated or recoloured."
          aside={
            delta !== undefined ? (
              <StatusPill tone={delta <= 2 ? "success" : "attention"}>
                ΔE {delta.toFixed(2)}
              </StatusPill>
            ) : (
              <StatusPill tone="neutral">Quality check pending</StatusPill>
            )
          }
        />

        <div className="ks-studio-grid" data-reveal>
          <div className="ks-studio-preview">
            <ProductMedia
              src={imageWithStamp}
              alt={showOriginal ? "Original product photo" : "Studio product photo"}
              emptyLabel="Studio image is not available"
            />
            <div className="ks-compare-control" role="group" aria-label="Compare images">
              <button
                type="button"
                className={showOriginal ? "is-active" : ""}
                onClick={() => setShowOriginal(true)}
                disabled={!original}
                aria-pressed={showOriginal}
              >
                Original
              </button>
              <button
                type="button"
                className={!showOriginal ? "is-active" : ""}
                onClick={() => setShowOriginal(false)}
                disabled={!studio}
                aria-pressed={!showOriginal}
              >
                Studio
              </button>
            </div>
          </div>

          <aside className="ks-studio-controls">
            <div>
              <p className="ks-eyebrow">Six bundled presets</p>
              <h2>Background surface</h2>
            </div>
            <div className="ks-preset-grid">
              {STUDIO_PRESETS.map((preset) => (
                <button
                  key={preset.id}
                  type="button"
                  className={selectedPreset === preset.id ? "is-selected" : ""}
                  onClick={() => applyPreset(preset.id)}
                  disabled={Boolean(busyPreset)}
                  aria-pressed={selectedPreset === preset.id}
                >
                  {/* Bundled decorative preset thumbnail, never a product fallback. */}
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img src={preset.src} alt="" />
                  <span>{preset.label}</span>
                  {busyPreset === preset.id ? <small>Applying…</small> : null}
                </button>
              ))}
            </div>

            <div className="ks-quality-card">
              <Icon name={delta !== undefined && delta <= 2 ? "check" : "info"} />
              <div>
                <strong>
                  {delta === undefined
                    ? "Waiting for quality result"
                    : delta <= 2
                      ? "Colour-quality gate passed"
                      : "Original retained"}
                </strong>
                <p>
                  {delta === undefined
                    ? "Apply a preset to run the studio check."
                    : `Measured colour difference: ΔE ${delta.toFixed(2)}. The allowed maximum is 2.00.`}
                </p>
                <Provenance
                  value={listingProvenance(listing)}
                  label="Studio source"
                />
              </div>
            </div>
          </aside>
        </div>

        {message ? <Notice>{message}</Notice> : null}
        {error ? <Notice tone="error">{error}</Notice> : null}

        <div className="ks-page-actions" data-reveal>
          <Action href="/capture" tone="quiet">
            Replace photo
          </Action>
          <Action href="/live" icon="arrow">
            Use this image
          </Action>
        </div>
      </section>
    </WorkspaceShell>
  );
}

export function LiveCatalogPage() {
  const [listing, setListing] = useState<Listing | null>(null);
  const [session, setSession] = useState<Record<string, unknown>>({});
  const [question, setQuestion] = useState("What is this product called?");
  const [typedAnswer, setTypedAnswer] = useState("");
  const [lastTranscript, setLastTranscript] = useState("");
  const [language, setLanguage] = useState("en-IN");
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [recording, setRecording] = useState(false);
  const [done, setDone] = useState(false);
  const [error, setError] = useState("");
  const [sttProvenance, setSttProvenance] = useState<ProvenanceData | null>(null);
  const [turnProvenance, setTurnProvenance] = useState<ProvenanceData | null>(null);
  const [speakingQuestion, setSpeakingQuestion] = useState(false);
  const recorderRef = useRef<MediaRecorder | null>(null);
  const chunksRef = useRef<Blob[]>([]);
  const streamRef = useRef<MediaStream | null>(null);
  const questionAudioRef = useRef<HTMLAudioElement | null>(null);

  useEffect(() => {
    const languageTimer = window.setTimeout(() => setLanguage(storedLanguage()), 0);
    const id = currentListingId();
    if (!id) {
      const loadingTimer = window.setTimeout(() => setLoading(false), 0);
      return () => {
        window.clearTimeout(languageTimer);
        window.clearTimeout(loadingTimer);
      };
    }

    api
      .getListing(id)
      .then(setListing)
      .catch((cause) => {
        setError(errorMessage(cause, "The product draft could not be loaded."));
      })
      .finally(() => setLoading(false));

    return () => {
      window.clearTimeout(languageTimer);
      if (recorderRef.current?.state === "recording") {
        recorderRef.current.stop();
      }
      streamRef.current?.getTracks().forEach((track) => track.stop());
      questionAudioRef.current?.pause();
    };
  }, []);

  const hearQuestion = async () => {
    if (!question || speakingQuestion) return;
    setSpeakingQuestion(true);
    try {
      const result = await api.tts(question, language);
      questionAudioRef.current?.pause();
      const audio = new Audio(`data:${result.content_type || "audio/wav"};base64,${result.audio_b64}`);
      questionAudioRef.current = audio;
      audio.onended = () => setSpeakingQuestion(false);
      await audio.play();
    } catch (cause) {
      setError(errorMessage(cause, "The question could not be spoken. You can read it on screen."));
      setSpeakingQuestion(false);
    }
  };

  useEffect(() => {
    if (!listing || Object.keys(session).length > 0) return;
    api
      .liveTurn({
        transcript: "",
        language_code: language,
        cluster: String(listing.cluster || listing.artisan?.cluster || ""),
      })
      .then((result) => {
        setSession(result.session || {});
        setQuestion(result.question || "What is this product called?");
      })
      .catch(() => {
        // The typed/voice controls remain usable with the local fallback prompt.
      });
  }, [language, listing, session]);

  const runTurn = async (transcript: string) => {
    const cleanTranscript = transcript.trim();
    if (!cleanTranscript || !listing) return;

    setBusy(true);
    setError("");

    try {
      const result = await api.liveTurn({
        transcript: cleanTranscript,
        language_code: language,
        cluster: String(listing.cluster || listing.artisan?.cluster || ""),
        session,
      });
      const generated = result.listing || {};
      const generatedFields = Object.fromEntries(
        Object.entries((generated.fields as Record<string, unknown> | undefined) || {}).map(
          ([key, value]) => [key, persistedValue(value)],
        ),
      );
      const mergedFields = {
        ...(listing.fields || {}),
        ...(result.fields || {}),
        ...generatedFields,
      };
      const updated = await api.patchListing(listing.id, {
        fields: mergedFields,
        title_en:
          typeof persistedValue(generated.title_en) === "string"
            ? persistedValue(generated.title_en)
            : listing.title_en,
        title_hi:
          typeof persistedValue(generated.title_hi) === "string"
            ? persistedValue(generated.title_hi)
            : listing.title_hi,
        desc_en:
          typeof persistedValue(generated.desc_en) === "string"
            ? persistedValue(generated.desc_en)
            : listing.desc_en,
        desc_hi:
          typeof persistedValue(generated.desc_hi) === "string"
            ? persistedValue(generated.desc_hi)
            : listing.desc_hi,
      });

      setListing(updated);
      setSession(result.session || {});
      setQuestion(
        result.question ||
          (result.done
            ? "Your draft is ready to review."
            : "What else should buyers know?"),
      );
      setLastTranscript(cleanTranscript);
      setTypedAnswer("");
      setDone(result.done);
      setTurnProvenance(result.provenance || null);
    } catch (cause) {
      setError(errorMessage(cause, "The live cataloger could not continue."));
    } finally {
      setBusy(false);
    }
  };

  const submitTypedAnswer = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    void runTurn(typedAnswer);
  };

  const stopRecording = () => {
    if (recorderRef.current?.state === "recording") {
      recorderRef.current.stop();
    }
  };

  const startRecording = async () => {
    if (!listing || busy) return;
    if (typeof MediaRecorder === "undefined" || !navigator.mediaDevices?.getUserMedia) {
      setError("Voice recording is not supported here. Use the typed answer below.");
      return;
    }

    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const recorderOptions = supportedVoiceRecordingOptions();
      if (!recorderOptions) {
        stream.getTracks().forEach((track) => track.stop());
        setError("This browser cannot create a compatible voice recording. You can use the typed answer below.");
        return;
      }
      const recorder = new MediaRecorder(stream, recorderOptions);
      streamRef.current = stream;
      recorderRef.current = recorder;
      chunksRef.current = [];
      setError("");

      recorder.ondataavailable = (event) => {
        if (event.data.size > 0) chunksRef.current.push(event.data);
      };
      recorder.onerror = () => {
        setError("Recording stopped unexpectedly. You can use the typed answer.");
        setRecording(false);
        stream.getTracks().forEach((track) => track.stop());
      };
      recorder.onstop = async () => {
        setRecording(false);
        stream.getTracks().forEach((track) => track.stop());
        streamRef.current = null;

        if (!chunksRef.current.length) {
          setError("No audio was captured. Please try again or type your answer.");
          return;
        }

        setBusy(true);
        try {
          const audio = new Blob(chunksRef.current, { type: sarvamAudioMimeType(recorder.mimeType) });
          const result = await api.stt(audio, language);
          setSttProvenance(result.provenance);
          if (!result.transcript.trim()) {
            throw new Error("We could not hear an answer. Please speak a little longer and try again.");
          }
          await runTurn(result.transcript);
        } catch (cause) {
          setError(errorMessage(cause, "Your speech could not be transcribed."));
          setBusy(false);
        }
      };

      recorder.start();
      setRecording(true);
    } catch (cause) {
      setError(
        errorMessage(
          cause,
          "Microphone access is unavailable. Use the typed answer below.",
        ),
      );
    }
  };

  if (loading) {
    return (
      <WorkspaceShell view="live">
        <section className="ks-creation-page" aria-busy="true">
          <PageIntro eyebrow="Step 3 · Describe" title="Opening the cataloger" />
          <Skeleton className="ks-skeleton--panel" />
        </section>
      </WorkspaceShell>
    );
  }

  if (!listing) {
    return (
      <WorkspaceShell view="live">
        <section className="ks-creation-page">
          <PageIntro
            eyebrow="Step 3 · Describe"
            title="Tell the story in your voice"
          />
          {error ? <Notice tone="error">{error}</Notice> : null}
          <EmptyState
            icon="camera"
            title="Start with a product photo"
            description="The live cataloger needs a product draft before it can save your answers."
            action={<Action href="/capture">Capture product</Action>}
          />
        </section>
      </WorkspaceShell>
    );
  }

  return (
    <WorkspaceShell view="live">
      <section className="ks-creation-page ks-live-page">
        <PageIntro
          eyebrow="Step 3 · Describe"
          title="Tell the product story in your own voice"
          description="Answer one useful question at a time. Type only when speaking is not convenient."
          aside={
            <StatusPill tone={done ? "success" : recording ? "attention" : "neutral"}>
              {done ? "Draft ready" : recording ? "Listening" : language}
            </StatusPill>
          }
        />

        <div className="ks-live-grid" data-reveal>
          <section className="ks-live-question" aria-busy={busy}>
            <p className="ks-eyebrow">KalaSetu asks</p>
            <h2>{question}</h2>
            <button className="ks-text-action" type="button" onClick={() => void hearQuestion()} disabled={speakingQuestion}>
              <Icon name="voice" size={16} />
              {speakingQuestion ? "Speaking question…" : "Hear question aloud"}
            </button>

            <button
              className={`ks-record-button${recording ? " is-recording" : ""}`}
              type="button"
              onClick={recording ? stopRecording : startRecording}
              disabled={busy && !recording}
              aria-pressed={recording}
            >
              <span className="ks-record-button__icon">
                <Icon name={recording ? "close" : "voice"} size={27} />
              </span>
              <strong>
                {recording
                  ? "Finish answer & continue"
                  : busy
                    ? "Preparing the next question…"
                    : "Speak answer"}
              </strong>
              <small>
                {recording
                  ? "Tap once when you have finished. KalaSetu will save this answer and ask the next field."
                  : "Answer this question, then finish to save it and continue."}
              </small>
            </button>

            <div className="ks-live-divider">
              <span>or type as a fallback</span>
            </div>

            <form className="ks-live-form" onSubmit={submitTypedAnswer}>
              <label htmlFor="catalog-answer">Your answer</label>
              <textarea
                id="catalog-answer"
                value={typedAnswer}
                onChange={(event) => setTypedAnswer(event.target.value)}
                placeholder="Type what you would say"
                rows={4}
                disabled={busy || recording || done}
              />
              <button
                className="ks-inline-submit"
                type="submit"
                disabled={!typedAnswer.trim() || busy || recording || done}
              >
                Save answer & next question
                <Icon name="arrow" size={16} />
              </button>
            </form>
          </section>

          <aside className="ks-live-transcript">
            <p className="ks-eyebrow">Last answer</p>
            {lastTranscript ? (
              <blockquote>“{lastTranscript}”</blockquote>
            ) : (
              <p className="ks-muted">Your transcribed answer will appear here.</p>
            )}
            {sttProvenance ? (
              <Provenance value={sttProvenance} label="Transcript source" />
            ) : null}
            {turnProvenance ? (
              <Provenance value={turnProvenance} label="Catalog source" />
            ) : null}
            <div className="ks-live-summary">
              <strong>{Object.keys(listing.fields || {}).length}</strong>
              <span>draft fields collected</span>
            </div>
          </aside>
        </div>

        {error ? <Notice tone="error">{error}</Notice> : null}

        <div className="ks-page-actions" data-reveal>
          <Action href="/studio" tone="quiet">
            Back to studio
          </Action>
          <Action href="/intelligence" disabled={!done} icon="arrow">
            Review draft
          </Action>
        </div>
      </section>
    </WorkspaceShell>
  );
}

export function IntelligencePage() {
  const [listing, setListing] = useState<Listing | null>(null);
  const [values, setValues] = useState<EditableValues>(() =>
    Object.fromEntries(EDITABLE_FIELDS.map((field) => [field.key, ""])) as EditableValues,
  );
  const [titleEnglish, setTitleEnglish] = useState("");
  const [titleHindi, setTitleHindi] = useState("");
  const [descriptionEnglish, setDescriptionEnglish] = useState("");
  const [descriptionHindi, setDescriptionHindi] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [dirty, setDirty] = useState(false);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  useEffect(() => {
    const id = currentListingId();
    if (!id) {
      const timer = window.setTimeout(() => setLoading(false), 0);
      return () => window.clearTimeout(timer);
    }

    api
      .getListing(id)
      .then((value) => {
        setListing(value);
        setValues(
          Object.fromEntries(
            EDITABLE_FIELDS.map((field) => {
              const raw = value.fields?.[field.key];
              const display = Array.isArray(raw) ? raw.join(", ") : String(raw ?? "");
              return [field.key, display];
            }),
          ) as EditableValues,
        );
        setTitleEnglish(value.title_en || "");
        setTitleHindi(value.title_hi || "");
        setDescriptionEnglish(value.desc_en || value.description || "");
        setDescriptionHindi(value.desc_hi || "");
      })
      .catch((cause) => {
        setError(errorMessage(cause, "The product draft could not be loaded."));
      })
      .finally(() => setLoading(false));
  }, []);

  const updateField = (key: EditableFieldKey, value: string) => {
    setValues((current) => ({ ...current, [key]: value }));
    setDirty(true);
    setMessage("");
  };

  const saveDraft = async () => {
    if (!listing || saving) return;

    setSaving(true);
    setError("");
    setMessage("");

    const nextFields: Record<string, unknown> = { ...(listing.fields || {}) };
    for (const field of EDITABLE_FIELDS) {
      const raw = values[field.key].trim();
      if (field.key === "colour") {
        nextFields[field.key] = raw
          ? raw.split(",").map((item) => item.trim()).filter(Boolean)
          : [];
      } else if (field.type === "number") {
        nextFields[field.key] = raw ? Number(raw) : null;
      } else {
        nextFields[field.key] = raw || null;
      }
    }

    try {
      const updated = await api.patchListing(listing.id, {
        fields: nextFields,
        title_en: titleEnglish.trim(),
        title_hi: titleHindi.trim(),
        desc_en: descriptionEnglish.trim(),
        desc_hi: descriptionHindi.trim(),
      });
      setListing(updated);
      setDirty(false);
      setMessage("Draft changes saved.");
    } catch (cause) {
      setError(errorMessage(cause, "The draft changes could not be saved."));
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <WorkspaceShell view="intelligence">
        <section className="ks-creation-page" aria-busy="true">
          <PageIntro eyebrow="Step 4 · Review" title="Loading your draft" />
          <div className="ks-review-grid" data-reveal>
            <Skeleton className="ks-skeleton--panel" />
            <Skeleton className="ks-skeleton--media" />
          </div>
        </section>
      </WorkspaceShell>
    );
  }

  if (!listing) {
    return (
      <WorkspaceShell view="intelligence">
        <section className="ks-creation-page">
          <PageIntro eyebrow="Step 4 · Review" title="Review your listing draft" />
          {error ? <Notice tone="error">{error}</Notice> : null}
          <EmptyState
            title="No draft to review"
            description="Describe a product first, then return here to check every detail."
            action={<Action href="/capture">Start a product</Action>}
          />
        </section>
      </WorkspaceShell>
    );
  }

  const completeCount = Object.values(values).filter((value) => value.trim()).length;

  return (
    <WorkspaceShell view="intelligence">
      <section className="ks-creation-page ks-intelligence-page">
        <PageIntro
          eyebrow="Step 4 · Review"
          title="Check every product detail"
          description="Nothing saves while you type. Use the explicit save action when the draft is accurate."
          aside={
            <StatusPill tone={dirty ? "attention" : "success"}>
              {dirty ? "Unsaved changes" : "Draft saved"}
            </StatusPill>
          }
        />

        <div className="ks-review-grid" data-reveal>
          <section className="ks-review-form">
            <div className="ks-completion">
              <span>Catalog details</span>
              <strong>
                {completeCount} of {EDITABLE_FIELDS.length} completed
              </strong>
              <progress value={completeCount} max={EDITABLE_FIELDS.length}>
                {completeCount} of {EDITABLE_FIELDS.length}
              </progress>
            </div>

            <fieldset>
              <legend>Bilingual public card</legend>
              <label>
                English title
                <input
                  value={titleEnglish}
                  onChange={(event) => {
                    setTitleEnglish(event.target.value);
                    setDirty(true);
                  }}
                />
              </label>
              <label>
                Hindi title
                <input
                  value={titleHindi}
                  onChange={(event) => {
                    setTitleHindi(event.target.value);
                    setDirty(true);
                  }}
                  lang="hi"
                />
              </label>
              <label className="ks-field--wide">
                English description
                <textarea
                  value={descriptionEnglish}
                  onChange={(event) => {
                    setDescriptionEnglish(event.target.value);
                    setDirty(true);
                  }}
                  rows={4}
                />
              </label>
              <label className="ks-field--wide">
                Hindi description
                <textarea
                  value={descriptionHindi}
                  onChange={(event) => {
                    setDescriptionHindi(event.target.value);
                    setDirty(true);
                  }}
                  rows={4}
                  lang="hi"
                />
              </label>
            </fieldset>

            <fieldset>
              <legend>Product and costing fields</legend>
              {EDITABLE_FIELDS.map((field) => (
                <label key={field.key}>
                  {field.label}
                  <input
                    type={field.type}
                    min={field.type === "number" ? "0" : undefined}
                    step={field.type === "number" ? "any" : undefined}
                    value={values[field.key]}
                    onChange={(event) => updateField(field.key, event.target.value)}
                  />
                </label>
              ))}
            </fieldset>

            <button
              className="ks-save-draft"
              type="button"
              onClick={saveDraft}
              disabled={!dirty || saving}
            >
              <Icon name="check" size={18} />
              {saving ? "Saving changes…" : "Save draft changes"}
            </button>
          </section>

          <aside className="ks-listing-preview">
            <ProductMedia
              src={productImage(listing)}
              alt={`Preview of ${listingTitle(listing)}`}
              emptyLabel="No product photo is stored"
            />
            <StatusPill tone="neutral">Draft preview</StatusPill>
            <h2>{titleEnglish || titleHindi || "Untitled product"}</h2>
            <p>
              {descriptionEnglish ||
                descriptionHindi ||
                "The confirmed product story will appear here."}
            </p>
            <Provenance
              value={listingProvenance(listing)}
              label="Draft source"
            />
          </aside>
        </div>

        {message ? <Notice>{message}</Notice> : null}
        {error ? <Notice tone="error">{error}</Notice> : null}

        <div className="ks-page-actions" data-reveal>
          <Action href="/live" tone="quiet">
            Add more by voice
          </Action>
          <Action href="/pricing" disabled={dirty || saving} icon="arrow">
            Continue to pricing
          </Action>
        </div>
      </section>
    </WorkspaceShell>
  );
}

export function PricingPage() {
  const [listing, setListing] = useState<Listing | null>(null);
  const [prices, setPrices] = useState<Listing["prices"]>({});
  const [breakdown, setBreakdown] = useState<PriceBreakdown | null>(null);
  const [selected, setSelected] = useState<PriceBandKey>("recommended");
  const [customPrice, setCustomPrice] = useState("");
  const [useCustomPrice, setUseCustomPrice] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  useEffect(() => {
    const id = currentListingId();
    if (!id) {
      const timer = window.setTimeout(() => setLoading(false), 0);
      return () => window.clearTimeout(timer);
    }

    Promise.all([api.getListing(id), api.price(id)])
      .then(([listingResult, priceResult]) => {
        setListing(listingResult);
        setPrices(priceResult.prices || {});
        setBreakdown(priceResult.breakdown || null);
        const existing = listedPrice(listingResult);
        if (typeof existing === "number") setCustomPrice(String(existing));
      })
      .catch((cause) => {
        setError(errorMessage(cause, "Fair-price options could not be calculated."));
      })
      .finally(() => setLoading(false));
  }, []);

  const chooseBand = (key: PriceBandKey) => {
    setSelected(key);
    setUseCustomPrice(false);
    setSaved(false);
    setMessage("");
  };

  const savePrice = async () => {
    if (!listing || saving) return;

    const customValue = Number(customPrice);
    const selectedValue = prices?.[selected]?.value;
    const value = useCustomPrice ? customValue : selectedValue;

    if (typeof value !== "number" || !Number.isFinite(value) || value <= 0) {
      setError("Choose a calculated price or enter a valid custom price.");
      return;
    }

    setSaving(true);
    setError("");
    setMessage("");

    try {
      const updated = await api.patchListing(listing.id, { price_hint: value });
      const recalculated = await api.price(listing.id);
      setListing(updated);
      setPrices(recalculated.prices || {});
      setBreakdown(recalculated.breakdown || null);
      setCustomPrice(String(value));
      setSaved(true);
      setMessage(`${formatMoney(value)} saved as your public listing price.`);
    } catch (cause) {
      setError(errorMessage(cause, "The selected price could not be saved."));
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <WorkspaceShell view="pricing">
        <section className="ks-creation-page" aria-busy="true">
          <PageIntro eyebrow="Step 5 · Price" title="Calculating a fair range" />
          <Skeleton className="ks-skeleton--panel" />
        </section>
      </WorkspaceShell>
    );
  }

  if (!listing) {
    return (
      <WorkspaceShell view="pricing">
        <section className="ks-creation-page">
          <PageIntro eyebrow="Step 5 · Price" title="Choose your listed price" />
          {error ? <Notice tone="error">{error}</Notice> : null}
          <EmptyState
            icon="rupee"
            title="No draft is ready for pricing"
            description="Complete the product details before calculating a fair range."
            action={<Action href="/intelligence">Review product details</Action>}
          />
        </section>
      </WorkspaceShell>
    );
  }

  return (
    <WorkspaceShell view="pricing">
      <section className="ks-creation-page ks-pricing-page">
        <PageIntro
          eyebrow="Step 5 · Price"
          title="Choose a fair price"
          description="KalaSetu calculates a transparent range. The final listed price remains your decision."
          aside={
            <StatusPill tone={saved ? "success" : "neutral"}>
              {saved ? "Price saved" : "Awaiting your choice"}
            </StatusPill>
          }
        />

        <div className="ks-price-grid" data-reveal>
          {PRICE_BANDS.map((band) => {
            const price = prices?.[band.key];
            const isSelected = !useCustomPrice && selected === band.key;
            return (
              <button
                key={band.key}
                className={isSelected ? "is-selected" : ""}
                type="button"
                onClick={() => chooseBand(band.key)}
                disabled={saving || typeof price?.value !== "number"}
                aria-pressed={isSelected}
              >
                <span className="ks-price-choice">
                  <span aria-hidden="true" />
                  {isSelected ? "Selected" : "Select"}
                </span>
                <h2>{band.title}</h2>
                <strong>{formatMoney(price?.value)}</strong>
                <p>{band.description}</p>
                <Provenance
  value={price?.provenance}
  label="Price source"
  interactive={false}
/>
              </button>
            );
          })}
        </div>

        <section className="ks-custom-price" data-reveal>
          <div>
            <Icon name="rupee" size={24} />
            <span>
              <strong>Set your own price</strong>
              <small>You can override the calculated choices.</small>
            </span>
          </div>
          <label>
            Amount in INR
            <input
              type="number"
              min="1"
              step="1"
              inputMode="numeric"
              value={customPrice}
              onFocus={() => {
                setUseCustomPrice(true);
                setSaved(false);
              }}
              onChange={(event) => {
                setCustomPrice(event.target.value);
                setUseCustomPrice(true);
                setSaved(false);
                setMessage("");
              }}
              aria-describedby="custom-price-note"
            />
          </label>
          <p id="custom-price-note">
            {useCustomPrice ? "Your custom amount will be saved." : "Select this field to use a custom amount."}
          </p>
        </section>

        <section className="ks-price-reason" data-reveal>
          <h2>Why this range?</h2>
          <ul>
            <li>Your entered material cost and work hours</li>
            <li>Your cluster wage and effort level</li>
            <li>Comparable handmade-product bands</li>
          </ul>
        </section>

        {breakdown ? (
          <section className="ks-price-breakdown" data-reveal>
            <div>
              <span>Cost breakdown</span>
              <strong>How this suggestion was calculated</strong>
            </div>
            <dl>
              <div><dt>Materials</dt><dd>{formatMoney(breakdown.material_cost_inr)}</dd></div>
              <div><dt>Work time</dt><dd>{breakdown.hours} hours</dd></div>
              <div><dt>Wage rate</dt><dd>{formatMoney(breakdown.wage_inr_per_hour)} / hour</dd></div>
              <div><dt>Labour</dt><dd>{formatMoney(breakdown.labour_cost_inr)}</dd></div>
              <div><dt>Overhead</dt><dd>{formatMoney(breakdown.overhead_inr)}</dd></div>
              <div className="is-total"><dt>Total cost</dt><dd>{formatMoney(breakdown.total_cost_inr)}</dd></div>
            </dl>
            <Provenance value={breakdown.provenance} label="Breakdown source" />
          </section>
        ) : null}

        {message ? <Notice>{message}</Notice> : null}
        {error ? <Notice tone="error">{error}</Notice> : null}

        <div className="ks-page-actions" data-reveal>
          <Action href="/intelligence" tone="quiet">
            Edit costing details
          </Action>
          <Action onClick={savePrice} disabled={saving} icon="check">
            {saving ? "Saving price…" : "Save this price"}
          </Action>
          <Action href="/approval" disabled={!saved || saving} icon="arrow">
            Continue to approval
          </Action>
        </div>
      </section>
    </WorkspaceShell>
  );
}

export function ApprovalPage() {
  const router = useRouter();
  const [listing, setListing] = useState<Listing | null>(null);
  const [confirmations, setConfirmations] = useState<boolean[]>(
    () => APPROVAL_CONFIRMATIONS.map(() => false),
  );
  const [loading, setLoading] = useState(true);
  const [speaking, setSpeaking] = useState(false);
  const [heardCard, setHeardCard] = useState(false);
  const [signing, setSigning] = useState(false);
  const [signed, setSigned] = useState(false);
  const [error, setError] = useState("");
  const audioRef = useRef<HTMLAudioElement | null>(null);

  useEffect(() => {
    const id = currentListingId();
    if (!id) {
      const timer = window.setTimeout(() => setLoading(false), 0);
      return () => window.clearTimeout(timer);
    }

    api
      .getListing(id)
      .then(setListing)
      .catch((cause) => {
        setError(errorMessage(cause, "The product card could not be loaded."));
      })
      .finally(() => setLoading(false));

    return () => {
      audioRef.current?.pause();
    };
  }, []);

  const listenToCard = async () => {
    if (!listing || speaking) return;

    setSpeaking(true);
    setError("");
    setHeardCard(false);

    const text = [
      listing.title_hi || listing.title_en || listing.title || listing.fields?.craft,
      listingDescription(listing),
      typeof listedPrice(listing) === "number"
        ? `Listed price ${listedPrice(listing)} rupees.`
        : "",
    ]
      .filter(Boolean)
      .join(". ");

    try {
      const result = await api.tts(
        text || "Your KalaSetu product listing is ready for review.",
        storedLanguage(),
      );
      const audio = new Audio(
        `data:${result.content_type};base64,${result.audio_b64}`,
      );
      audioRef.current = audio;
      await audio.play();
      await new Promise<void>((resolve, reject) => {
        audio.onended = () => resolve();
        audio.onerror = () => reject(new Error("The card audio could not be played."));
      });
      setHeardCard(true);
    } catch (cause) {
      setError(errorMessage(cause, "The product card could not be read aloud."));
    } finally {
      setSpeaking(false);
    }
  };

  const allConfirmed = confirmations.every(Boolean);
  const readyToSign = allConfirmed && heardCard;

  const signListing = async () => {
    if (!listing || signing) return;
    if (!allConfirmed) {
      setError("Confirm all four statements before publishing.");
      return;
    }
    if (!heardCard) {
      setError("Listen to the full card before publishing.");
      return;
    }

    setSigning(true);
    setError("");

    try {
      await api.sign(listing.id);
      setSigned(true);
      window.setTimeout(() => router.push("/shop"), 1800);
    } catch (cause) {
      setError(errorMessage(cause, "The listing could not be signed."));
    } finally {
      setSigning(false);
    }
  };

  if (loading) {
    return (
      <WorkspaceShell view="approval">
        <section className="ks-creation-page" aria-busy="true">
          <PageIntro eyebrow="Step 6 · Approve" title="Loading your final card" />
          <Skeleton className="ks-skeleton--panel" />
        </section>
      </WorkspaceShell>
    );
  }

  if (!listing) {
    return (
      <WorkspaceShell view="approval">
        <section className="ks-creation-page">
          <PageIntro eyebrow="Step 6 · Approve" title="Approve your product card" />
          {error ? <Notice tone="error">{error}</Notice> : null}
          <EmptyState
            icon="shield"
            title="No listing is ready to approve"
            description="Finish the product draft and price before publishing."
            action={<Action href="/intelligence">Review draft</Action>}
          />
        </section>
      </WorkspaceShell>
    );
  }

  if (signed) {
    return (
      <WorkspaceShell view="approval">
        <section className="ks-sign-success" role="status" aria-live="polite">
          <div className="ks-sign-success__mark"><Icon name="check" size={34} /></div>
          <p className="ks-eyebrow">KalaSetu verified</p>
          <h1>Signed successfully</h1>
          <p>Your product is now ready in My Catalog. Taking you there…</p>
        </section>
      </WorkspaceShell>
    );
  }

  return (
    <WorkspaceShell view="approval">
      <section className="ks-creation-page ks-approval-page">
        <PageIntro
          eyebrow="Step 6 · Approve"
          title="Hear it before it leaves your hands"
          description="Listen to the complete card, confirm each statement, then sign and publish."
          aside={
            <StatusPill tone={readyToSign ? "success" : "attention"}>
              {readyToSign ? "Ready to sign" : "Review required"}
            </StatusPill>
          }
        />

        <div className="ks-approval-grid" data-reveal>
          <article className="ks-approval-card">
            <ProductMedia
              src={productImage(listing)}
              alt={`Product photograph for ${listingTitle(listing)}`}
              emptyLabel="No product photo is stored"
            />
            <div className="ks-approval-card__body">
              <StatusPill tone="neutral">Final preview</StatusPill>
              <h2>{listingTitle(listing)}</h2>
              <strong>{formatMoney(listedPrice(listing))}</strong>
              <p>
                {listingDescription(listing)}
              </p>
              <Provenance
                value={listing.prices?.listed?.provenance}
                label="Listed price source"
              />
            </div>
          </article>

          <section className="ks-approval-checklist">
            <h2>Your confirmation</h2>
            <p>All four boxes begin unchecked so approval remains your choice.</p>

            <button
              className={`ks-listen-card${heardCard ? " is-complete" : ""}`}
              type="button"
              onClick={listenToCard}
              disabled={speaking || signing}
            >
              <Icon name={heardCard ? "check" : "play"} size={22} />
              <span>
                <strong>
                  {speaking
                    ? "Reading the full card…"
                    : heardCard
                      ? "Full card heard"
                      : "Listen to full card"}
                </strong>
                <small>This must finish before the listing can be signed.</small>
              </span>
            </button>

            <div className="ks-confirmation-list">
              {APPROVAL_CONFIRMATIONS.map((item, index) => (
                <label key={item}>
                  <input
                    type="checkbox"
                    checked={confirmations[index]}
                    onChange={(event) => {
                      setConfirmations((current) =>
                        current.map((value, itemIndex) =>
                          itemIndex === index ? event.target.checked : value,
                        ),
                      );
                      setError("");
                    }}
                    disabled={signing}
                  />
                  <span>{item}</span>
                </label>
              ))}
            </div>
          </section>
        </div>

        {error ? <Notice tone="error">{error}</Notice> : null}

        <div className="ks-page-actions" data-reveal>
          <Action href="/intelligence" tone="quiet">
            Edit listing
          </Action>
          <Action
            onClick={signListing}
            disabled={!readyToSign || signing}
            icon="shield"
          >
            {signing ? "Signing and publishing…" : "Sign and publish"}
          </Action>
        </div>
      </section>
    </WorkspaceShell>
  );
}

export function DistributionPage() {
  const [listing, setListing] = useState<Listing | null>(null);
  const [loading, setLoading] = useState(true);
  const [sharing, setSharing] = useState(false);
  const [downloading, setDownloading] = useState(false);
  const [exporting, setExporting] = useState("");
  const [exportStatuses, setExportStatuses] = useState<Record<string, string>>({});
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  useEffect(() => {
    const id = currentListingId();
    if (!id) {
      setLoading(false);
      return;
    }

    api
      .getListing(id)
      .then(setListing)
      .catch((cause) => {
        setError(errorMessage(cause, "The published listing could not be loaded."));
      })
      .finally(() => setLoading(false));
  }, []);

  const publicUrl = listing?.public_url || "";

  const copyLink = async () => {
    if (!publicUrl) {
      setError("The signed public link is not available yet.");
      return;
    }

    try {
      await navigator.clipboard.writeText(publicUrl);
      setMessage("Public link copied.");
      setError("");
    } catch (cause) {
      setError(errorMessage(cause, "The public link could not be copied."));
    }
  };

  const shareListing = async () => {
    if (!publicUrl || !listing) {
      setError("The signed public link is not available yet.");
      return;
    }

    if (!navigator.share) {
      await copyLink();
      return;
    }

    setSharing(true);
    setError("");
    try {
      await navigator.share({
        title: listingTitle(listing),
        text: "View this artisan product on KalaSetu.",
        url: publicUrl,
      });
      setMessage("Share sheet opened.");
    } catch (cause) {
      if (cause instanceof DOMException && cause.name === "AbortError") return;
      setError(errorMessage(cause, "The listing could not be shared."));
    } finally {
      setSharing(false);
    }
  };

  const downloadQr = async () => {
    if (!listing?.qr_url) {
      setError("The signed QR code is not available yet.");
      return;
    }

    setDownloading(true);
    setError("");
    try {
      const response = await fetch(listing.qr_url);
      if (!response.ok) throw new Error("The QR code download failed.");
      const blob = await response.blob();
      const objectUrl = URL.createObjectURL(blob);
      const anchor = document.createElement("a");
      anchor.href = objectUrl;
      anchor.download = `kalasetu-${listing.id}-qr.png`;
      document.body.appendChild(anchor);
      anchor.click();
      anchor.remove();
      URL.revokeObjectURL(objectUrl);
      setMessage("QR code downloaded.");
    } catch (cause) {
      setError(errorMessage(cause, "The QR code could not be downloaded."));
    } finally {
      setDownloading(false);
    }
  };

  const prepareExport = async (channel: string) => {
    if (!listing || exporting) return;

    setExporting(channel);
    setError("");
    try {
      const result = await api.exportListing(listing.id, channel);
      const blob = new Blob([JSON.stringify(result, null, 2)], {
        type: "application/json",
      });
      const objectUrl = URL.createObjectURL(blob);
      const anchor = document.createElement("a");
      anchor.href = objectUrl;
      anchor.download = `kalasetu-${listing.id}-${channel}-export.json`;
      document.body.appendChild(anchor);
      anchor.click();
      anchor.remove();
      URL.revokeObjectURL(objectUrl);
      setExportStatuses((current) => ({
        ...current,
        [channel]: `${result.label} prepared and downloaded. Nothing was sent.`,
      }));
    } catch (cause) {
      setExportStatuses((current) => ({
        ...current,
        [channel]: errorMessage(cause, "Export preparation failed."),
      }));
    } finally {
      setExporting("");
    }
  };

  if (loading) {
    return (
      <WorkspaceShell view="distribute">
        <section className="ks-creation-page" aria-busy="true">
          <PageIntro eyebrow="Step 7 · Published" title="Loading distribution tools" />
          <Skeleton className="ks-skeleton--panel" />
        </section>
      </WorkspaceShell>
    );
  }

  if (!listing) {
    return (
      <WorkspaceShell view="distribute">
        <section className="ks-creation-page">
          <PageIntro
            eyebrow="Step 7 · Published"
            title="Share your signed listing"
          />
          {error ? <Notice tone="error">{error}</Notice> : null}
          <EmptyState
            icon="send"
            title="No published listing found"
            description="Sign a product card before opening its sharing and export tools."
            action={<Action href="/approval">Return to approval</Action>}
          />
        </section>
      </WorkspaceShell>
    );
  }

  const isSigned =
    listing.status === "published" &&
    Boolean(listing.signature) &&
    Boolean(listing.qr_url) &&
    Boolean(publicUrl);

  if (!isSigned) {
    return (
      <WorkspaceShell view="distribute">
        <section className="ks-creation-page">
          <PageIntro
            eyebrow="Step 7 · Published"
            title="Finish signing this listing"
          />
          <EmptyState
            icon="shield"
            title="This listing is not signed yet"
            description="Distribution stays locked until the API returns the published status, signature, QR code, and public link."
            action={<Action href="/approval">Review and sign</Action>}
          />
        </section>
      </WorkspaceShell>
    );
  }

  return (
    <WorkspaceShell view="distribute">
      <section className="ks-creation-page ks-distribution-page">
        <div className="ks-published-banner" data-reveal>
          <span>
            <Icon name="check" size={24} />
          </span>
          <div>
            <p className="ks-eyebrow">Signed and published</p>
            <h1>Your product card is live</h1>
            <p>Share the same verified public card by link or QR code.</p>
          </div>
          <StatusPill tone="success">Published</StatusPill>
        </div>

        <div className="ks-distribution-grid" data-reveal>
          <article className="ks-published-product">
            <ProductMedia
              src={productImage(listing)}
              alt={`Published product ${listingTitle(listing)}`}
              emptyLabel="No published product photo"
            />
            <div>
              <h2>{listingTitle(listing)}</h2>
              <strong>{formatMoney(listedPrice(listing))}</strong>
              <p>{String(listing.cluster || listing.artisan?.cluster || "")}</p>
              <small>Listing {listing.id}</small>
            </div>
          </article>

          <section className="ks-qr-card">
            <ProductMedia
              src={listing.qr_url}
              alt={`QR code for ${listingTitle(listing)}`}
              className="ks-qr-media"
              emptyLabel="Signed QR code unavailable"
            />
            <div>
              <h2>Public link and QR</h2>
              <p>Anyone with this code can open the public product card.</p>
              <div className="ks-share-actions">
                <button
                  type="button"
                  onClick={shareListing}
                  disabled={sharing}
                >
                  <Icon name="send" size={17} />
                  {sharing ? "Opening share…" : "Share"}
                </button>
                <button type="button" onClick={copyLink}>
                  <Icon name="catalog" size={17} />
                  Copy link
                </button>
                <button
                  type="button"
                  onClick={downloadQr}
                  disabled={downloading}
                >
                  <Icon name="download" size={17} />
                  {downloading ? "Downloading…" : "Download QR"}
                </button>
              </div>
            </div>
          </section>

          <aside className="ks-signature-card">
            <Icon name="shield" size={25} />
            <h2>Signed listing</h2>
            <dl>
              <div>
                <dt>Status</dt>
                <dd>Published</dd>
              </div>
              <div>
                <dt>Signature</dt>
                <dd>Verified</dd>
              </div>
              <div>
                <dt>Public card</dt>
                <dd>Ready</dd>
              </div>
            </dl>
          </aside>
        </div>

        <section className="ks-export-section" data-reveal>
          <div>
            <p className="ks-eyebrow">Channel-ready records</p>
            <h2>Prepare external channel exports</h2>
            <p>
              These APIs prepare channel-specific records for review. Nothing is
              sent to an external marketplace from this workspace yet.
            </p>
          </div>
          <div className="ks-export-grid">
            {EXPORT_CHANNELS.map((channel) => (
              <article key={channel.id}>
                <StatusPill tone="attention">Review required</StatusPill>
                <h3>{channel.label}</h3>
                <button
                  type="button"
                  onClick={() => prepareExport(channel.id)}
                  disabled={Boolean(exporting)}
                >
                  {exporting === channel.id ? "Preparing…" : "Prepare export"}
                </button>
                {exportStatuses[channel.id] ? (
                  <small role="status">{exportStatuses[channel.id]}</small>
                ) : null}
              </article>
            ))}
          </div>
        </section>

        {message ? <Notice>{message}</Notice> : null}
        {error ? <Notice tone="error">{error}</Notice> : null}

        <div className="ks-page-actions" data-reveal>
          <Action href={`/v/${listing.id}`} tone="secondary" icon="arrow">
            View public card
          </Action>
          <Action href="/shop" icon="check">
            Done
          </Action>
        </div>
      </section>
    </WorkspaceShell>
  );
}
