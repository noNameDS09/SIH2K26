"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useState, type FormEvent } from "react";
import {
  api,
  clearSession,
  currentListingId,
  rememberListing,
  type AdvisorResult,
  type InsightsResult,
  type Listing,
  type MoneyResult,
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
  WorkspaceShell,
} from "./workspace-ui";

const LANGUAGES = [
  ["mr-IN", "मराठी / Marathi"],
  ["hi-IN", "हिन्दी / Hindi"],
  ["en-IN", "English (India)"],
  ["bn-IN", "বাংলা / Bengali"],
  ["ta-IN", "தமிழ் / Tamil"],
  ["te-IN", "తెలుగు / Telugu"],
  ["ml-IN", "മലയാളം / Malayalam"],
  ["kn-IN", "ಕನ್ನಡ / Kannada"],
  ["gu-IN", "ગુજરાતી / Gujarati"],
  ["pa-IN", "ਪੰਜਾਬੀ / Punjabi"],
  ["od-IN", "ଓଡ଼ିଆ / Odia"],
  ["as-IN", "অসমীয়া / Assamese"],
  ["ur-IN", "اردو / Urdu"],
  ["sa-IN", "संस्कृत / Sanskrit"],
  ["ne-IN", "नेपाली / Nepali"],
  ["kok-IN", "कोंकणी / Konkani"],
  ["mai-IN", "मैथिली / Maithili"],
  ["sd-IN", "سنڌي / Sindhi"],
  ["doi-IN", "डोगरी / Dogri"],
  ["sat-IN", "ᱥᱟᱱᱛᱟᱲᱤ / Santali"],
  ["mni-IN", "মৈতৈলোন্ / Manipuri"],
  ["ks-IN", "کٲشُر / Kashmiri"],
  ["brx-IN", "बर' / Bodo"],
] as const;

function messageFrom(cause: unknown, fallback: string) {
  return cause instanceof Error ? cause.message : fallback;
}

function listingTitle(listing: Listing, lang = "en-IN"): string {
  const tr = (listing as { translations?: Record<string, { title?: string }> }).translations?.[lang];
  if (tr?.title) return String(tr.title);
  if (lang.startsWith("hi") && listing.title_hi) return String(listing.title_hi);
  if (lang.startsWith("mr") && (listing.title_mr || listing.title_hi)) return String(listing.title_mr || listing.title_hi);
  return String(listing.title_en || listing.title_hi || listing.title || "Untitled listing");
}

function listingImage(listing: Listing) {
  return listing.studioUrl || listing.originalUrl || listing.photo_url || listing.image_url;
}

function listingPrice(listing: Listing) {
  const listed = listing.prices?.listed?.value;
  return typeof listed === "number" ? `₹${listed.toLocaleString("en-IN")}` : "Price not set";
}

function listingDate(listing: Listing) {
  const raw = listing.updatedAt || listing.signedAt;
  if (typeof raw !== "string") return "Date unavailable";
  const date = new Date(raw);
  return Number.isNaN(date.valueOf()) ? "Date unavailable" : date.toLocaleDateString("en-IN");
}

function LoadingPage({ view, label }: { view: "home" | "shop" | "money" | "insights" | "settings"; label: string }) {
  return (
    <WorkspaceShell view={view}>
      <div className="ks-management-loading" role="status" aria-label={label}>
        <Skeleton className="ks-management-loading__title" />
        <Skeleton className="ks-management-loading__panel" />
        <Skeleton className="ks-management-loading__panel" />
      </div>
    </WorkspaceShell>
  );
}

function PageError({
  view,
  title,
  error,
  retry,
}: {
  view: "home" | "shop" | "money" | "insights" | "settings";
  title: string;
  error: string;
  retry: () => void;
}) {
  return (
    <WorkspaceShell view={view}>
      <PageIntro title={title} description="The latest information could not be loaded." />
      <div className="ks-management-error" role="alert">
        <Icon name="info" />
        <p>{error}</p>
        <Action onClick={retry}>Try again</Action>
      </div>
    </WorkspaceShell>
  );
}

type HomeData = {
  artisan: Record<string, unknown>;
  listings: Listing[];
  money: MoneyResult;
  advisor: AdvisorResult;
  trends: Awaited<ReturnType<typeof api.trends>>;
};

export function HomePage() {
  const [data, setData] = useState<HomeData | null>(null);
  const [error, setError] = useState("");
  const [reload, setReload] = useState(0);

  useEffect(() => {
    let active = true;
    Promise.all([
      api.me(),
      api.listListings(),
      api.money(),
      api.advisor(),
      api.trends(),
    ])
      .then(([me, listings, money, advisor, trends]) => {
        if (active) {
          setError("");
          setData({
            artisan: me.artisan,
            listings: listings.items || [],
            money,
            advisor,
            trends,
          });
        }
      })
      .catch((cause) => {
        if (active) setError(messageFrom(cause, "Could not load your workspace."));
      });
    return () => {
      active = false;
    };
  }, [reload]);

  if (error && !data) {
    return (
      <PageError
        view="home"
        title="My workspace"
        error={error}
        retry={() => {
          setError("");
          setReload((value) => value + 1);
        }}
      />
    );
  }
  if (!data) return <LoadingPage view="home" label="Loading your workspace" />;

  const drafts = data.listings.filter((item) => item.status !== "published");
  const published = data.listings.filter((item) => item.status === "published");
  const recent = [...data.listings]
    .sort((left, right) => String(right.updatedAt || "").localeCompare(String(left.updatedAt || "")))
    .slice(0, 3);
  const name = typeof data.artisan.name === "string" ? data.artisan.name : "Artisan";

  return (
    <WorkspaceShell view="home">
      <PageIntro
        eyebrow="My workspace"
        title={`Namaste, ${name}`}
        description="Your catalog, sales record, and current public signals in one place."
        aside={<Action href="/capture" icon="plus">Add product</Action>}
      />

      <section className="ks-home-quick" aria-label="Quick actions" data-reveal>
        <Link href="/capture"><Icon name="camera" /><span><strong>Photograph a product</strong><small>Start a new listing</small></span><Icon name="arrow" size={16} /></Link>
        <Link href="/shop"><Icon name="catalog" /><span><strong>Continue a draft</strong><small>{drafts.length} waiting</small></span><Icon name="arrow" size={16} /></Link>
        <Link href="/money"><Icon name="rupee" /><span><strong>Record a sale</strong><small>Update your own record</small></span><Icon name="arrow" size={16} /></Link>
        <Link href="/insights"><Icon name="trend" /><span><strong>See current signals</strong><small>Advisor and public trends</small></span><Icon name="arrow" size={16} /></Link>
      </section>

      <section className="ks-home-summary" aria-label="Workspace summary" data-reveal>
        <article>
          <span>Published</span>
          <strong>{published.length}</strong>
          <Link href="/shop">Open catalog</Link>
        </article>
        <article>
          <span>Drafts to finish</span>
          <strong>{drafts.length}</strong>
          <Link href="/shop">Review drafts</Link>
        </article>
        <article>
          <span>Self-recorded sales</span>
          <strong>{data.money.count}</strong>
          <small>₹{data.money.total_inr.toLocaleString("en-IN")} total</small>
        </article>
      </section>

      <div className="ks-home-grid" data-reveal>
        <section className="ks-home-advisor">
          <div className="ks-section-heading">
            <div>
              <p className="ks-eyebrow">Business advisor</p>
              <h2>One useful next step</h2>
            </div>
            <Icon name="trend" />
          </div>
          {data.advisor.empty || !data.advisor.sentence ? (
            <p className="ks-home-advisor__quiet">
              Your advisor is quiet for now. A suggestion appears only when your own records support one.
            </p>
          ) : (
            <p className="ks-home-advisor__sentence">{data.advisor.sentence}</p>
          )}
          <Provenance value={data.advisor.provenance} label="Advisor source" />
        </section>

        <section className="ks-home-trends">
          <div className="ks-section-heading">
            <div>
              <p className="ks-eyebrow">Public trend</p>
              <h2>Current rising signals</h2>
            </div>
            <StatusPill tone={data.trends.seed ? "attention" : "neutral"}>
              {data.trends.seed ? "Seed/sample signal" : `${data.trends.n ?? 0} observations`}
            </StatusPill>
          </div>
          {data.trends.rising?.length ? (
            <ul>
              {data.trends.rising.map((item) => <li key={item}>{item}</li>)}
            </ul>
          ) : (
            <p>No public trend signal is available yet.</p>
          )}
          <Provenance value={data.trends.provenance} label="Trend source" />
        </section>
      </div>

      <section className="ks-home-recent" data-reveal>
        <div className="ks-section-heading">
          <div>
            <p className="ks-eyebrow">Recent work</p>
            <h2>Your latest listings</h2>
          </div>
          <Action href="/shop" tone="quiet">View all</Action>
        </div>
        {recent.length ? (
          <div className="ks-home-recent__list">
            {recent.map((listing) => (
              <article key={listing.id}>
                <ProductMedia src={listingImage(listing)} alt={listingTitle(listing)} />
                <div>
                  <StatusPill tone={listing.status === "published" ? "success" : "attention"}>
                    {listing.status === "published" ? "Published" : "Draft"}
                  </StatusPill>
                  <h3>{listingTitle(listing)}</h3>
                  <p>{listingPrice(listing)} · {listingDate(listing)}</p>
                  <Link
                    href={listing.status === "published" ? `/v/${listing.id}` : "/intelligence"}
                    onClick={() => rememberListing(listing.id)}
                  >
                    {listing.status === "published" ? "View public card" : "Resume draft"}
                  </Link>
                </div>
              </article>
            ))}
          </div>
        ) : (
          <EmptyState
            title="No listings yet"
            description="Start with a real product photo and your own description."
            action={<Action href="/capture">Add your first product</Action>}
          />
        )}
      </section>
    </WorkspaceShell>
  );
}

type CatalogStatus = "all" | "draft" | "published";
type CatalogSort = "updated" | "title" | "price";

export function CatalogPage() {
  const [items, setItems] = useState<Listing[]>([]);
  const [status, setStatus] = useState<CatalogStatus>("all");
  const [sort, setSort] = useState<CatalogSort>("updated");
  const [query, setQuery] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [reload, setReload] = useState(0);

  useEffect(() => {
    let active = true;
    api.listListings()
      .then((result) => {
        if (active) {
          setError("");
          setItems(result.items || []);
        }
      })
      .catch((cause) => {
        if (active) setError(messageFrom(cause, "Could not load your catalog."));
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, [reload]);

  const visible = useMemo(() => {
    const normalized = query.trim().toLocaleLowerCase();
    return items
      .filter((item) => status === "all" || (item.status || "draft") === status)
      .filter((item) => {
        if (!normalized) return true;
        const craft = typeof item.fields?.craft === "string" ? item.fields.craft : item.craft || "";
        return `${listingTitle(item)} ${craft}`.toLocaleLowerCase().includes(normalized);
      })
      .sort((left, right) => {
        if (sort === "title") return listingTitle(left).localeCompare(listingTitle(right));
        if (sort === "price") {
          return Number(right.prices?.listed?.value || 0) - Number(left.prices?.listed?.value || 0);
        }
        return String(right.updatedAt || "").localeCompare(String(left.updatedAt || ""));
      });
  }, [items, query, sort, status]);

  if (loading) return <LoadingPage view="shop" label="Loading your catalog" />;
  if (error && !items.length) {
    return (
      <PageError
        view="shop"
        title="My catalog"
        error={error}
        retry={() => {
          setLoading(true);
          setError("");
          setReload((value) => value + 1);
        }}
      />
    );
  }

  return (
    <WorkspaceShell view="shop">
      <PageIntro
        eyebrow="My catalog"
        title="Your work, ready to continue"
        description="Search drafts and published cards. Product images appear only when your listing has one."
        aside={<Action href="/capture" icon="plus">Add product</Action>}
      />

      <section className="ks-catalog-controls" aria-label="Catalog controls" data-reveal>
        <div className="ks-catalog-tabs" role="tablist" aria-label="Listing status">
          {(["all", "draft", "published"] as const).map((value) => (
            <button
              type="button"
              role="tab"
              aria-selected={status === value}
              className={status === value ? "ks-is-active" : undefined}
              onClick={() => setStatus(value)}
              key={value}
            >
              {value === "all" ? "All" : value === "draft" ? "Drafts" : "Published"}
              <span>
                {value === "all"
                  ? items.length
                  : items.filter((item) => (item.status || "draft") === value).length}
              </span>
            </button>
          ))}
        </div>
        <label className="ks-catalog-search">
          <span className="ks-visually-hidden">Search listings</span>
          <Icon name="search" size={18} />
          <input
            type="search"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="Search title or craft"
          />
        </label>
        <label className="ks-catalog-sort">
          <span>Sort</span>
          <select value={sort} onChange={(event) => setSort(event.target.value as CatalogSort)}>
            <option value="updated">Recently updated</option>
            <option value="title">Title</option>
            <option value="price">Listed price</option>
          </select>
        </label>
      </section>

      {error ? <p className="ks-inline-error" role="alert">{error}</p> : null}
      {visible.length ? (
        <section className="ks-catalog-grid" aria-label="Listings" data-reveal>
          {visible.map((listing) => (
            <article className="ks-catalog-card" key={listing.id}>
              <ProductMedia src={listingImage(listing)} alt={listingTitle(listing)} />
              <div className="ks-catalog-card__body">
                <StatusPill tone={listing.status === "published" ? "success" : "attention"}>
                  {listing.status === "published" ? "Published" : "Draft"}
                </StatusPill>
                <h2>{listingTitle(listing)}</h2>
                <p>{listingPrice(listing)}</p>
                <small>Updated {listingDate(listing)}</small>
                <Action
                  href={listing.status === "published" ? `/v/${listing.id}` : "/intelligence"}
                  tone={listing.status === "published" ? "quiet" : "primary"}
                  icon="arrow"
                  onClick={() => rememberListing(listing.id)}
                >
                  {listing.status === "published" ? "View card" : "Resume draft"}
                </Action>
              </div>
            </article>
          ))}
        </section>
      ) : (
        <EmptyState
          icon="search"
          title={items.length ? "No matching listings" : "No listings yet"}
          description={items.length ? "Try another search or status tab." : "Add a real product to begin your catalog."}
          action={items.length ? undefined : <Action href="/capture">Add product</Action>}
        />
      )}
    </WorkspaceShell>
  );
}

const TRADE_BARS = [
  ["identity", "Identity details"],
  ["listings", "Published listings"],
  ["sales", "Recorded sales"],
  ["consistency", "Recent activity"],
  ["community", "Catalog participation"],
] as const;

export function MoneyPage() {
  const [money, setMoney] = useState<MoneyResult | null>(null);
  const [listings, setListings] = useState<Listing[]>([]);
  const [listingId, setListingId] = useState("");
  const [amount, setAmount] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [speaking, setSpeaking] = useState(false);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [reload, setReload] = useState(0);

  useEffect(() => {
    let active = true;
    Promise.all([api.money(), api.listListings()])
      .then(([moneyResult, listingResult]) => {
        if (!active) return;
        setError("");
        setMoney(moneyResult);
        setListings(listingResult.items || []);
        setListingId((current) => current || listingResult.items?.[0]?.id || "");
      })
      .catch((cause) => {
        if (active) setError(messageFrom(cause, "Could not load your sales record."));
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, [reload]);

  const recordSale = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const parsed = Number(amount);
    if (!listingId) {
      setError("Choose a listing first.");
      return;
    }
    if (!Number.isFinite(parsed) || parsed <= 0) {
      setError("Enter a sale amount greater than zero.");
      return;
    }
    setSaving(true);
    setError("");
    setNotice("");
    try {
      await api.createSale(listingId, parsed);
      setAmount("");
      setNotice("Sale added to your self-recorded sales.");
      const refreshed = await api.money();
      setMoney(refreshed);
    } catch (cause) {
      setError(messageFrom(cause, "Could not record this sale."));
    } finally {
      setSaving(false);
    }
  };

  const speakSummary = async () => {
    if (!money?.spoken || speaking) return;
    setSpeaking(true);
    setError("");
    try {
      const language = window.localStorage.getItem("kalasetu_language") || "en-IN";
      const result = await api.tts(money.spoken, language);
      await new Audio(`data:${result.content_type};base64,${result.audio_b64}`).play();
    } catch (cause) {
      setError(messageFrom(cause, "Could not play the spoken summary."));
    } finally {
      setSpeaking(false);
    }
  };

  if (loading) return <LoadingPage view="money" label="Loading sales and Trade Record" />;
  if (error && !money) {
    return (
      <PageError
        view="money"
        title="Sales and Trade Record"
        error={error}
        retry={() => {
          setLoading(true);
          setError("");
          setReload((value) => value + 1);
        }}
      />
    );
  }
  if (!money) return null;

  const listingNames = new Map<string, string>(listings.map((listing) => [listing.id, listingTitle(listing)]));

  return (
    <WorkspaceShell view="money">
      <PageIntro
        eyebrow="Money"
        title="Your self-recorded sales"
        description="Only sales you add are shown here. KalaSetu does not collect payments."
        aside={
          <Action tone="secondary" icon="voice" onClick={() => void speakSummary()} disabled={speaking}>
            {speaking ? "Speaking…" : "Hear summary"}
          </Action>
        }
      />

      <section className="ks-money-summary" data-reveal>
        <div>
          <span>Total recorded</span>
          <strong>₹{money.total_inr.toLocaleString("en-IN")}</strong>
          <small>{money.count} {money.count === 1 ? "sale" : "sales"}</small>
        </div>
        <p>{money.spoken}</p>
      </section>

      <div className="ks-money-layout" data-reveal>
        <section className="ks-sales-list">
          <div className="ks-section-heading">
            <div>
              <p className="ks-eyebrow">Sales history</p>
              <h2>Recorded sales</h2>
            </div>
          </div>
          {money.sales.length ? (
            <div className="ks-sales-list__rows">
              {money.sales.map((sale, index) => {
                const id = String(sale.listing_id || sale.listingId || "");
                const rawDate = sale.confirmedAt;
                const date = typeof rawDate === "string" && !Number.isNaN(new Date(rawDate).valueOf())
                  ? new Date(rawDate).toLocaleDateString("en-IN")
                  : "Date unavailable";
                return (
                  <article key={String(sale.id || `${id}-${index}`)}>
                    <div>
                      <strong>{listingNames.get(id) || id || "Listing"}</strong>
                      <small>{date}</small>
                    </div>
                    <b>₹{Number(sale.amount || 0).toLocaleString("en-IN")}</b>
                  </article>
                );
              })}
            </div>
          ) : (
            <EmptyState
              icon="rupee"
              title="No sales recorded"
              description="Add a sale only after you have confirmed it yourself."
            />
          )}
        </section>

        <form className="ks-sale-form" onSubmit={recordSale}>
          <p className="ks-eyebrow">Add a sale</p>
          <h2>Record a confirmed sale</h2>
          <label>
            <span>Listing</span>
            <select value={listingId} onChange={(event) => setListingId(event.target.value)} required>
              <option value="">Choose a listing</option>
              {listings.map((listing) => (
                <option value={listing.id} key={listing.id}>{listingTitle(listing)}</option>
              ))}
            </select>
          </label>
          <label>
            <span>Amount received (₹)</span>
            <input
              type="number"
              min="0.01"
              step="0.01"
              inputMode="decimal"
              value={amount}
              onChange={(event) => setAmount(event.target.value)}
              required
            />
          </label>
          <p>Only the listing and amount are submitted.</p>
          <Action type="submit" disabled={saving || !listings.length}>
            {saving ? "Saving…" : "Save sale"}
          </Action>
        </form>
      </div>

      <section className="ks-trade-record" aria-labelledby="ks-trade-record-title" data-reveal>
        <div className="ks-section-heading">
          <div>
            <p className="ks-eyebrow">Your activity record</p>
            <h2 id="ks-trade-record-title">Trade Record</h2>
          </div>
          <StatusPill tone="neutral">Five activity bars</StatusPill>
        </div>
        <p>These bars summarize supported activity already in your KalaSetu record. They do not decide loans or payments.</p>
        <div className="ks-trade-record__bars">
          {TRADE_BARS.map(([key, label]) => {
            const value = Math.max(0, Math.min(5, Number(money.trade_record[key] || 0)));
            return (
              <div className="ks-trade-bar" key={key}>
                <span>{label}</span>
                <div
                  role="progressbar"
                  aria-label={label}
                  aria-valuemin={0}
                  aria-valuemax={5}
                  aria-valuenow={value}
                >
                  {Array.from({ length: 5 }, (_, index) => (
                    <i className={index < value ? "ks-is-filled" : undefined} key={index} />
                  ))}
                </div>
                <strong>{value}/5</strong>
              </div>
            );
          })}
        </div>
      </section>

      {notice ? <p className="ks-inline-success" role="status">{notice}</p> : null}
      {error ? <p className="ks-inline-error" role="alert">{error}</p> : null}
    </WorkspaceShell>
  );
}

function historyTimestamp(item: Record<string, unknown>) {
  const raw = item.ts || item.createdAt;
  if (typeof raw !== "string") return null;
  const value = new Date(raw).valueOf();
  return Number.isNaN(value) ? null : value;
}

function HistoryChart({ history }: { history: Array<Record<string, unknown>> }) {
  const dated = history
    .map(historyTimestamp)
    .filter((value): value is number => value !== null)
    .sort((left, right) => left - right);
  if (!dated.length) {
    return <p className="ks-insights-chart__empty">No dated advisor history is available.</p>;
  }
  const first = dated[0];
  const last = dated[dated.length - 1];
  const span = Math.max(last - first, 1);
  const points = dated.map((value, index) => {
    const x = 8 + ((value - first) / span) * 84;
    const y = 88 - ((index + 1) / dated.length) * 72;
    return `${x},${y}`;
  }).join(" ");
  return (
    <svg
      className="ks-insights-history-chart"
      viewBox="0 0 100 100"
      role="img"
      aria-label={`${dated.length} dated advisor suggestions over time`}
      preserveAspectRatio="none"
    >
      <path d="M8 88H96M8 12V88" />
      <polyline points={points} />
      {points.split(" ").map((point) => {
        const [cx, cy] = point.split(",");
        return <circle cx={cx} cy={cy} r="2" key={point} />;
      })}
    </svg>
  );
}

function insightProvenance(value: unknown): ProvenanceData | undefined {
  if (!value || typeof value !== "object") return undefined;
  const candidate = value as Record<string, unknown>;
  if (typeof candidate.source !== "string") return undefined;
  return {
    source: candidate.source,
    version: typeof candidate.version === "string" ? candidate.version : undefined,
    confidence: typeof candidate.confidence === "number" ? candidate.confidence : undefined,
    ts: typeof candidate.ts === "string" ? candidate.ts : undefined,
  };
}

export function InsightsPage() {
  const [data, setData] = useState<InsightsResult | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [reload, setReload] = useState(0);

  useEffect(() => {
    let active = true;
    api.insights()
      .then((result) => {
        if (active) {
          setError("");
          setData(result);
        }
      })
      .catch((cause) => {
        if (active) setError(messageFrom(cause, "Could not load your insights."));
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, [reload]);

  if (loading) return <LoadingPage view="insights" label="Loading advisor and public trends" />;
  if (error && !data) {
    return (
      <PageError
        view="insights"
        title="Insights"
        error={error}
        retry={() => {
          setLoading(true);
          setError("");
          setReload((value) => value + 1);
        }}
      />
    );
  }
  if (!data) return null;

  const rising = Array.isArray(data.trends.rising)
    ? data.trends.rising.filter((item): item is string => typeof item === "string")
    : [];
  const trendSource = insightProvenance(data.trends.provenance);

  return (
    <WorkspaceShell view="insights">
      <PageIntro
        eyebrow="Insights"
        title="Signals grounded in real records"
        description="Your advisor uses your activity. Public trends are anonymised and show when seed/sample evidence is included."
      />

      <section className="ks-insights-advisor" data-reveal>
        <div className="ks-section-heading">
          <div>
            <p className="ks-eyebrow">Business advisor</p>
            <h2>Current suggestion</h2>
          </div>
          <Icon name="trend" />
        </div>
        {data.advisor.empty || !data.advisor.sentence ? (
          <p>Your advisor is quiet. No supported suggestion is available from your record yet.</p>
        ) : (
          <blockquote>{data.advisor.sentence}</blockquote>
        )}
        <Provenance value={data.advisor.provenance} label="Advisor source" />
      </section>

      <div className="ks-insights-grid" data-reveal>
        <section className="ks-insights-public">
          <div className="ks-section-heading">
            <div>
              <p className="ks-eyebrow">Public trends</p>
              <h2>Rising signals</h2>
            </div>
            <StatusPill tone={data.seed ? "attention" : "neutral"}>
              {data.seed ? "Seed/sample data" : `${data.n ?? 0} observations`}
            </StatusPill>
          </div>
          <p className="ks-insights-public__note">
            {data.seed
              ? `The current sample has ${data.n ?? 0} observations, so seed evidence is included.`
              : `Based on ${data.n ?? 0} public observations.`}
          </p>
          {rising.length ? (
            <ol className="ks-trend-rank" aria-label="Ordered rising signals">
              {rising.map((item, index) => (
                <li key={item}>
                  <span>{index + 1}</span>
                  <strong>{item}</strong>
                  <i aria-hidden="true" />
                </li>
              ))}
            </ol>
          ) : (
            <EmptyState
              icon="trend"
              title="No public trend yet"
              description="The backend has not returned any rising signal."
            />
          )}
          <small>Ordered signals only; the backend does not provide a magnitude.</small>
          <Provenance value={trendSource} label="Trend source" />
        </section>

        <section className="ks-insights-history">
          <div className="ks-section-heading">
            <div>
              <p className="ks-eyebrow">Your history</p>
              <h2>Advisor suggestions over time</h2>
            </div>
            <strong>{data.history.length}</strong>
          </div>
          <HistoryChart history={data.history} />
          <small>The line is a cumulative count of dated advisor events, not sales or market value.</small>
        </section>
      </div>

      {data.history.length ? (
        <section className="ks-insights-events" data-reveal>
          <h2>Recent advisor history</h2>
          <ul>
            {data.history.slice(0, 5).map((event, index) => {
              const timestamp = historyTimestamp(event);
              const rule = typeof event.payload === "object" && event.payload
                ? (event.payload as Record<string, unknown>).rule_id
                : event.rule_id;
              return (
                <li key={String(event.id || index)}>
                  <span>{timestamp ? new Date(timestamp).toLocaleDateString("en-IN") : "Date unavailable"}</span>
                  <strong>{typeof rule === "string" ? rule.replaceAll("_", " ") : "Advisor suggestion"}</strong>
                </li>
              );
            })}
          </ul>
        </section>
      ) : null}

      {error ? <p className="ks-inline-error" role="alert">{error}</p> : null}
    </WorkspaceShell>
  );
}

export function SettingsPage() {
  const router = useRouter();
  const [language, setLanguage] = useState("en-IN");
  const [speakScreens, setSpeakScreens] = useState(true);
  const [largeText, setLargeText] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [exporting, setExporting] = useState(false);
  const [notice, setNotice] = useState("");
  const [error, setError] = useState("");

  useEffect(() => {
    let active = true;
    const timer = window.setTimeout(() => {
      const storedLanguage = window.localStorage.getItem("kalasetu_language") || "en-IN";
      const storedSpeak = window.localStorage.getItem("kalasetu_speak_screens");
      const storedLarge = window.localStorage.getItem("kalasetu_large_text");
      setLanguage(storedLanguage);
      setSpeakScreens(storedSpeak === null ? true : storedSpeak === "true");
      setLargeText(storedLarge === "true");
      document.documentElement.classList.toggle("ks-large-text", storedLarge === "true");
    }, 0);
    api.me()
      .then((result) => {
        if (!active) return;
        if (typeof result.artisan.lang === "string") setLanguage(result.artisan.lang);
      })
      .catch((cause) => {
        if (active) setError(messageFrom(cause, "Could not load profile settings."));
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
      window.clearTimeout(timer);
    };
  }, []);

  const updateLocalPreference = (key: string, value: boolean) => {
    window.localStorage.setItem(key, String(value));
    if (key === "kalasetu_large_text") document.documentElement.classList.toggle("ks-large-text", value);
  };

  const save = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setSaving(true);
    setError("");
    setNotice("");
    try {
      await api.updateProfile({ lang: language });
      window.localStorage.setItem("kalasetu_language", language);
      window.localStorage.setItem("kalasetu_speak_screens", String(speakScreens));
      window.localStorage.setItem("kalasetu_large_text", String(largeText));
      window.dispatchEvent(new Event("kalasetu_lang_change"));
      setNotice("Preferences saved.");
    } catch (cause) {
      setError(messageFrom(cause, "Could not save your preferences."));
    } finally {
      setSaving(false);
    }
  };

  const exportCurrent = async () => {
    const id = currentListingId();
    if (!id) {
      setError("There is no current listing to export.");
      return;
    }
    setExporting(true);
    setError("");
    setNotice("");
    try {
      const result = await api.exportListing(id, "gem");
      const blob = new Blob([JSON.stringify(result, null, 2)], { type: "application/json" });
      const url = URL.createObjectURL(blob);
      const anchor = document.createElement("a");
      anchor.href = url;
      anchor.download = `kalasetu-${id}-gem-export.json`;
      anchor.click();
      URL.revokeObjectURL(url);
      setNotice(`${result.label}. The labelled mock export was downloaded; nothing was sent.`);
    } catch (cause) {
      setError(messageFrom(cause, "Could not export the current listing."));
    } finally {
      setExporting(false);
    }
  };

  const signOut = () => {
    clearSession();
    router.push("/language");
    router.refresh();
  };

  if (loading) return <LoadingPage view="settings" label="Loading settings" />;

  return (
    <WorkspaceShell view="settings">
      <PageIntro
        eyebrow="Settings"
        title="Make KalaSetu easier to use"
        description="Language is saved to your profile. Reading and text-size preferences stay on this device."
      />

      <form className="ks-settings-form" onSubmit={save} data-reveal>
        <section>
          <div>
            <h2>Language</h2>
            <p>Used for future voice and catalog screens.</p>
          </div>
          <label>
            <span>Preferred language</span>
            <select value={language} onChange={(event) => setLanguage(event.target.value)}>
              {LANGUAGES.map(([code, label]) => (
                <option value={code} key={code}>{label}</option>
              ))}
            </select>
          </label>
        </section>

        <section>
          <div>
            <h2>Accessibility</h2>
            <p>These preferences are persisted locally on this device.</p>
          </div>
          <label className="ks-settings-toggle">
            <span>
              <strong>Speak screens</strong>
              <small>Keep screen-reading controls available.</small>
            </span>
            <input
              type="checkbox"
              checked={speakScreens}
              onChange={(event) => {
                setSpeakScreens(event.target.checked);
                updateLocalPreference("kalasetu_speak_screens", event.target.checked);
              }}
            />
          </label>
          <label className="ks-settings-toggle">
            <span>
              <strong>Large text</strong>
              <small>Increase text size across the workspace.</small>
            </span>
            <input
              type="checkbox"
              checked={largeText}
              onChange={(event) => {
                setLargeText(event.target.checked);
                updateLocalPreference("kalasetu_large_text", event.target.checked);
              }}
            />
          </label>
        </section>

        <section>
          <div>
            <h2>Current listing export</h2>
            <p>Download the supported GeM-shaped JSON for your current listing.</p>
          </div>
          <div className="ks-settings-export">
            <StatusPill tone="mock">Mock — for SIH demo</StatusPill>
            <p>This prepares a labelled file only. It does not send data to GeM.</p>
            <Action type="button" tone="secondary" icon="download" onClick={() => void exportCurrent()} disabled={exporting}>
              {exporting ? "Preparing…" : "Export current listing"}
            </Action>
          </div>
        </section>

        <div className="ks-settings-actions">
          <Action type="submit" disabled={saving}>{saving ? "Saving…" : "Save preferences"}</Action>
          <Action type="button" tone="quiet" onClick={signOut}>Sign out</Action>
        </div>
      </form>

      {notice ? <p className="ks-inline-success" role="status">{notice}</p> : null}
      {error ? <p className="ks-inline-error" role="alert">{error}</p> : null}
    </WorkspaceShell>
  );
}
