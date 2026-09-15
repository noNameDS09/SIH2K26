export type Provenance = { source: string; version?: string; confidence?: number; ts?: string };
export type Listing = {
  id: string;
  status?: string;
  title?: string;
  title_en?: string;
  title_hi?: string;
  description?: string;
  desc_en?: string;
  desc_hi?: string;
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
  artisan?: { name?: string; cluster?: string };
  provenance?: Provenance[];
  signature?: string;
  qr_url?: string;
  public_url?: string;
  [key: string]: unknown;
};
export type AdvisorResult = { sentence: string; empty: boolean; rule_id?: string | null; listing_id?: string; provenance?: Provenance; trade_record?: Record<string, unknown> };
export type MoneyResult = { sales: Array<Record<string, unknown>>; total_inr: number; count: number; empty: boolean; spoken: string; trade_record: Record<string, unknown> };
export type InsightsResult = { advisor: AdvisorResult; history: Array<Record<string, unknown>>; trends: { rising?: string[]; provenance?: Provenance; [key: string]: unknown }; n?: number; seed?: boolean };

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
  liveTurn: (body: { transcript: string; language_code: string; cluster: string; session?: Record<string, unknown> }) => request<{ session: Record<string, unknown>; question: string; speak: string; done: boolean; listing: Record<string, unknown>; provenance?: Provenance }>("/v1/speech/live/turn", { method: "POST", body: JSON.stringify(body) }),
  stt: async (audio: Blob, languageCode = "en-IN") => { const form = new FormData(); form.set("file", audio, "catalog-answer.webm"); form.set("language_code", languageCode); return request<{ transcript: string; language_code: string; provenance: Provenance }>("/v1/speech/stt", { method: "POST", body: form }); },
  tts: (text: string, languageCode = "en-IN") => request<{ audio_b64: string; content_type: string; provenance: Provenance }>("/v1/speech/tts", { method: "POST", body: JSON.stringify({ text, language_code: languageCode }) }),
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
  price: (id: string) => request<{ prices: Listing["prices"] }>(`/v1/listings/${encodeURIComponent(id)}/price`, { method: "POST" }),
  sign: (id: string) => request<{ listing_id: string; status: string; qr_url: string; public_url: string; signature: string }>(`/v1/listings/${encodeURIComponent(id)}/sign`, { method: "POST" }),
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
