export type Provenance = { source: string; version?: string; confidence?: number; ts?: string };
export type Listing = {
  id: string;
  status?: string;
  title?: string;
  title_en?: string;
  title_hi?: string;
  title_mr?: string;
  description?: string;
  desc_en?: string;
  desc_hi?: string;
  desc_mr?: string;
  fields?: Record<string, unknown>;
  prices?: Record<string, { value?: number; provenance?: Provenance }>;
  originalUrl?: string;
  studioUrl?: string;
  photo_url?: string;
  bgPreset?: string;
  deltaE?: number;
  craft?: string;
  image_url?: string;
  cluster?: string;
  cluster_name?: string;
  artisan?: { name?: string; cluster?: string };
  provenance?: Provenance[];
  signature?: string;
  qr_url?: string;
  public_url?: string;
  updatedAt?: string;
  signedAt?: string;
  createdAt?: string;
  translations?: Record<string, { title?: string; description?: string }>;
  [key: string]: unknown;
};
export type AdvisorResult = { sentence: string; empty: boolean; rule_id?: string | null; listing_id?: string; provenance?: Provenance; trade_record?: Record<string, unknown> };
export type MoneyResult = { sales: Array<Record<string, unknown>>; total_inr: number; count: number; empty: boolean; spoken: string; trade_record: Record<string, unknown> };
export type InsightsResult = { advisor: AdvisorResult; history: Array<Record<string, unknown>>; trends: { rising?: string[]; provenance?: Provenance; [key: string]: unknown }; n?: number; seed?: boolean };
export type PriceBreakdown = {
  material_cost_inr: number;
  hours: number;
  wage_inr_per_hour: number;
  effort_factor: number;
  labour_cost_inr: number;
  overhead_inr: number;
  total_cost_inr: number;
  recommended_margin_inr: number;
  provenance?: Provenance;
};

/** Sarvam rejects the WebM/Opus container emitted by MediaRecorder defaults. */
export function supportedVoiceRecordingOptions(): MediaRecorderOptions | null {
  if (typeof MediaRecorder === "undefined") return null;
  const candidates = ["audio/ogg;codecs=opus", "audio/mp4", "audio/aac"];
  const mimeType = candidates.find((candidate) => MediaRecorder.isTypeSupported(candidate));
  return mimeType ? { mimeType } : null;
}

export function audioUploadName(blob: Blob, baseName: string): string {
  const type = blob.type.toLowerCase();
  const extension = type.includes("ogg") || type.includes("opus")
    ? "ogg"
    : type.includes("mp4") || type.includes("m4a") || type.includes("aac")
      ? "m4a"
      : "wav";
  return `${baseName}.${extension}`;
}

export function sarvamAudioMimeType(mimeType: string): string {
  const normalized = mimeType.toLowerCase().split(";", 1)[0];
  if (["audio/ogg", "audio/opus", "audio/mp4", "audio/aac"].includes(normalized)) {
    return normalized;
  }
  return "audio/wav";
}

export type DetectLanguageResult = {
  language_code: string;
  language_name: string;
  transcript: string;
  greeting: string;
  audio_b64: string;
  content_type: string;
  provenance: Provenance;
};

export type VoiceActionResult = {
  intent: "navigation" | "action" | "question" | "empty";
  action: "navigate" | "back" | "read_screen" | "assistant" | "none";
  target?: string | null;
  transcript: string;
  spoken: string;
  answer?: string;
  audio_b64?: string;
  content_type?: string;
  provenance?: Provenance;
};

export type AssistantQueryResult = {
  query: string;
  answer: string;
  audio_b64: string;
  content_type: string;
  language_code: string;
  provenance: Provenance;
};

const API_BASE = (process.env.NEXT_PUBLIC_API_BASE_URL || "http://localhost:8000").replace(/\/$/, "");

function token() {
  if (typeof window === "undefined") return "";
  return window.localStorage.getItem("kalasetu_token") || "";
}

async function request<T>(path: string, init: RequestInit = {}, auth = true): Promise<T> {
  const headers = new Headers(init.headers);
  if (init.body && !(init.body instanceof FormData)) headers.set("Content-Type", "application/json");
  const bearer = auth ? token() : "";
  if (bearer) headers.set("Authorization", `Bearer ${bearer}`);
  const controller = new AbortController();
  const timeout = window.setTimeout(() => controller.abort(), 15000);
  let response: Response;
  try {
    response = await fetch(`${API_BASE}${path}`, { ...init, headers, signal: controller.signal });
  } catch (cause) {
    if (cause instanceof DOMException && cause.name === "AbortError") {
      throw new Error("The KalaSetu server took too long to respond. Please try again.");
    }
    throw new Error("KalaSetu could not connect to the server. Check that the API is running.");
  } finally {
    window.clearTimeout(timeout);
  }
  const body = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(typeof body.detail === "string" ? body.detail : `Request failed (${response.status})`);
  return body as T;
}

export const api = {
  baseUrl: API_BASE,
  requestOtp: (phone: string) => request<{ ok: boolean; phone: string; label?: string }>("/v1/auth/otp", { method: "POST", body: JSON.stringify({ phone }) }, false),
  verifyOtp: (phone: string, code: string) => request<{ token: string; firebase_custom_token?: string | null; uid: string; artisan: Record<string, unknown> }>("/v1/auth/verify", { method: "POST", body: JSON.stringify({ phone, code }) }, false),
  me: () => request<{ artisan: Record<string, unknown> }>("/v1/auth/me"),
  updateProfile: (body: Record<string, unknown>) => request<{ artisan: Record<string, unknown> }>("/v1/auth/profile", { method: "PATCH", body: JSON.stringify(body) }),
  uploadDocument: async (documentType: string, details: Record<string, string>, file: File) => {
    const form = new FormData();
    form.set("document_type", documentType);
    form.set("details", JSON.stringify(details));
    form.set("file", file);
    return request<{ ok: boolean; document: Record<string, unknown>; artisan: Record<string, unknown> }>("/v1/auth/documents", { method: "POST", body: form });
  },
  createListing: (body: Record<string, unknown>) => request<Listing>("/v1/listings", { method: "POST", body: JSON.stringify(body) }),
  listListings: () => request<{ items: Listing[] }>("/v1/listings"),
  getListing: (id: string) => request<Listing>(`/v1/listings/${encodeURIComponent(id)}`),
  patchListing: (id: string, body: Record<string, unknown>) => request<Listing>(`/v1/listings/${encodeURIComponent(id)}`, { method: "PATCH", body: JSON.stringify(body) }),
  enhance: async (listingId: string, options: { file?: File; bgPreset?: string; craft?: string } = {}) => {
    const form = new FormData();
    if (options.file) form.set("file", options.file);
    form.set("listing_id", listingId);
    form.set("bg_preset", options.bgPreset || "linen");
    form.set("craft", options.craft || "");
    return request<{ accepted: boolean; deltaE: number; original_url: string; studio_url: string; used_studio: boolean; reused_original?: boolean; bg_preset: string; provenance: Provenance }>("/v1/images/enhance", { method: "POST", body: form });
  },
  liveTurn: (body: { transcript: string; language_code: string; cluster: string; session?: Record<string, unknown> }) => request<{ session: Record<string, unknown>; question: string; speak: string; done: boolean; listing: Record<string, unknown> | null; fields?: Record<string, unknown>; provenance?: Provenance }>("/v1/speech/live/turn", { method: "POST", body: JSON.stringify(body) }),
  stt: async (audio: Blob, languageCode = "en-IN") => { const form = new FormData(); form.set("file", audio, audioUploadName(audio, "catalog-answer")); form.set("language_code", languageCode); return request<{ transcript: string; language_code: string; provenance: Provenance }>("/v1/speech/stt", { method: "POST", body: form }); },
  tts: (text: string, languageCode = "en-IN") => request<{ audio_b64: string; content_type: string; provenance: Provenance }>("/v1/speech/tts", { method: "POST", body: JSON.stringify({ text, language_code: languageCode }) }),
  detectLanguage: async (audio: Blob) => {
    const form = new FormData();
    form.set("file", audio, audioUploadName(audio, "language-sample"));
    return request<DetectLanguageResult>("/v1/speech/detect-language", { method: "POST", body: form }, false);
  },
  voiceAction: async (options: { file?: Blob; transcript?: string; language_code?: string; listing_id?: string }) => {
    const form = new FormData();
    if (options.file) form.set("file", options.file, audioUploadName(options.file, "voice-cmd"));
    if (options.transcript) form.set("transcript", options.transcript);
    form.set("language_code", options.language_code || "hi-IN");
    if (options.listing_id) form.set("listing_id", options.listing_id);
    return request<VoiceActionResult>("/v1/speech/voice-action", { method: "POST", body: form });
  },
  queryAssistant: (query: string, languageCode = "hi-IN", listingId?: string) =>
    request<AssistantQueryResult>("/v1/assistant/query", {
      method: "POST",
      body: JSON.stringify({ query, language_code: languageCode, listing_id: listingId }),
    }),
  money: () => request<MoneyResult>("/v1/money"),
  createSale: (listingId: string, amount: number) => request<{ ok: boolean; sale: Record<string, unknown>; trade_record: Record<string, unknown> }>("/v1/sales", { method: "POST", body: JSON.stringify({ listing_id: listingId, amount }) }),
  advisor: () => request<AdvisorResult>("/v1/advisor"),
  insights: () => request<InsightsResult>("/v1/insights"),
  trends: () => request<{ rising?: string[]; n?: number; seed?: boolean; provenance?: Provenance }>("/v1/trends/current", {}, false),
  exportListing: (id: string, channel: string) => request<{
    ok: boolean;
    channel: string;
    channel_name: string;
    schema: string;
    label: string;
    live_write: false;
    listing_id: string;
    exported_at: string;
    record: Record<string, unknown>;
    public: Record<string, unknown>;
    provenance?: Provenance;
  }>(`/v1/listings/${encodeURIComponent(id)}/export`, { method: "POST", body: JSON.stringify({ channel }) }),
  price: (id: string) => request<{ prices: Listing["prices"]; breakdown?: PriceBreakdown }>(`/v1/listings/${encodeURIComponent(id)}/price`, { method: "POST" }),
  sign: (id: string) => request<{ listing_id: string; status: string; qr_url: string; public_url: string; signature: string }>(`/v1/listings/${encodeURIComponent(id)}/sign`, { method: "POST" }),
  translateListing: (id: string, targetLang = "hi-IN") => request<{ listing_id: string; target_lang: string; title: string; description: string; cached: boolean }>(`/v1/listings/${encodeURIComponent(id)}/translate?target_lang=${encodeURIComponent(targetLang)}`, { method: "POST" }, false),
  market: () => request<{ items: Listing[] }>("/v1/market", {}, false),
};

export function rememberSession(tokenValue: string, uid: string) {
  if (typeof window === "undefined") return;
  window.localStorage.setItem("kalasetu_token", tokenValue);
  window.localStorage.setItem("kalasetu_uid", uid);
}

export async function rememberFirebaseSession(customToken: string | null | undefined) {
  const { consumeCustomToken } = await import("@/lib/firebase-client");
  try {
    const mode = await consumeCustomToken(customToken);
    if (typeof window !== "undefined") window.localStorage.setItem("kalasetu_auth_mode", mode);
    return mode;
  } catch {
    if (typeof window !== "undefined") window.localStorage.setItem("kalasetu_auth_mode", "dev");
    return "dev";
  }
}

export function currentListingId() {
  if (typeof window === "undefined") return "";
  return window.localStorage.getItem("kalasetu_listing_id") || "";
}

export function rememberListing(id: string) {
  if (typeof window !== "undefined") window.localStorage.setItem("kalasetu_listing_id", id);
}

export function clearSession() {
  if (typeof window === "undefined") return;
  window.localStorage.removeItem("kalasetu_token");
  window.localStorage.removeItem("kalasetu_uid");
  window.localStorage.removeItem("kalasetu_auth_mode");
  void import("@/lib/firebase-client").then(({ signOutFirebase }) => signOutFirebase()).catch(() => undefined);
}
