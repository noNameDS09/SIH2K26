"use client";

import Image from "next/image";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useCallback, useEffect, useRef, useState, type ReactNode } from "react";
import gsap from "gsap";
import { api, clearSession, type Provenance as ProvenanceData } from "@/lib/api-client";

export type WorkspaceView =
  | "home"
  | "capture"
  | "studio"
  | "live"
  | "intelligence"
  | "pricing"
  | "approval"
  | "distribute"
  | "shop"
  | "money"
  | "insights"
  | "settings";

const creationSteps = [
  ["capture", "Capture", "/capture"],
  ["studio", "Studio", "/studio"],
  ["live", "Describe", "/live"],
  ["intelligence", "Review", "/intelligence"],
  ["pricing", "Price", "/pricing"],
  ["approval", "Approve", "/approval"],
  ["distribute", "Published", "/distribute"],
] as const;

const workspaceArtwork: Partial<Record<WorkspaceView, { src: string; alt: string; className: string }>> = {
  home: { src: "/assets/13-pastel-village-path.jpg", alt: "Pastel village path", className: "ks-ambient-art--home" },
  capture: { src: "/assets/illustration-hillside-panel.jpg", alt: "Soft hillside craft landscape", className: "ks-ambient-art--capture" },
  studio: { src: "/assets/15-risograph-craft-stack.png", alt: "Craft stack and material motif", className: "ks-ambient-art--studio" },
  live: { src: "/assets/illustration-artisan-speaking.png", alt: "Artisan speaking about a craft", className: "ks-ambient-art--live" },
  intelligence: { src: "/assets/09-ink-wash-leaf.png", alt: "Ink-wash leaf motif", className: "ks-ambient-art--intelligence" },
  pricing: { src: "/assets/pattern-diamond-jaali.jpg", alt: "Diamond jaali pattern", className: "ks-ambient-art--pricing" },
  approval: { src: "/assets/logo-mark-gateway.png", alt: "KalaSetu gateway mark", className: "ks-ambient-art--approval" },
  distribute: { src: "/assets/illustration-woven-basket.png", alt: "Woven basket illustration", className: "ks-ambient-art--distribute" },
  shop: { src: "/assets/11-kalamkari-tree-peacocks.jpg", alt: "Kalamkari tree and peacock motif", className: "ks-ambient-art--shop" },
  money: { src: "/assets/illustration-artisan-painting.png", alt: "Artisan painting illustration", className: "ks-ambient-art--money" },
  insights: { src: "/assets/01-warli-circle.png", alt: "Warli circle motif", className: "ks-ambient-art--insights" },
  settings: { src: "/assets/04-minimal-line-botanical.png", alt: "Minimal botanical line motif", className: "ks-ambient-art--settings" },
};

const navGroups = [
  {
    label: "Workspace",
    items: [
      ["home", "My workspace", "/", "home"],
      ["capture", "Add product", "/capture", "plus"],
      ["shop", "My catalog", "/shop", "catalog"],
    ],
  },
  {
    label: "Grow",
    items: [
      ["money", "Trade Record", "/money", "chart"],
      ["insights", "Insights", "/insights", "trend"],
    ],
  },
] as const;

export function Icon({ name, size = 20 }: { name: string; size?: number }) {
  const common = {
    fill: "none",
    stroke: "currentColor",
    strokeWidth: 1.8,
    strokeLinecap: "round" as const,
    strokeLinejoin: "round" as const,
  };
  const paths: Record<string, ReactNode> = {
    home: <><path d="m3 11 9-8 9 8" /><path d="M5 10v10h14V10M9 20v-6h6v6" /></>,
    plus: <><circle cx="12" cy="12" r="9" /><path d="M12 8v8M8 12h8" /></>,
    catalog: <><rect x="4" y="4" width="16" height="16" rx="3" /><path d="M8 8h8M8 12h8M8 16h5" /></>,
    chart: <><path d="M4 20h16M6 17V9M11 17V5M16 17v-4M21 17V8" /></>,
    trend: <><path d="m3 17 6-6 4 4 7-9" /><path d="M15 6h5v5" /></>,
    image: <><rect x="3" y="4" width="18" height="16" rx="3" /><circle cx="9" cy="10" r="2" /><path d="m5 18 5-5 3 3 2-2 4 4" /></>,
    voice: <><rect x="9" y="3" width="6" height="12" rx="3" /><path d="M5 11a7 7 0 0 0 14 0M12 18v3M9 21h6" /></>,
    tag: <><path d="M3 5v7l8 8 9-9-8-8H5a2 2 0 0 0-2 2Z" /><circle cx="8" cy="8" r="1" /></>,
    shield: <><path d="M12 3 4 6v5c0 5 3.4 8.4 8 10 4.6-1.6 8-5 8-10V6l-8-3Z" /><path d="m8.5 12 2.2 2.2 4.8-5" /></>,
    send: <><path d="m3 11 18-8-7 18-3-7-8-3Z" /><path d="m11 14 5-6" /></>,
    settings: <><circle cx="12" cy="12" r="3" /><path d="M19 12a7 7 0 0 0-.1-1l2-1.5-2-3.4-2.4 1a7 7 0 0 0-1.7-1L14.5 3h-5l-.4 3.1a7 7 0 0 0-1.7 1l-2.4-1-2 3.4L5 11a7 7 0 0 0 0 2l-2 1.5 2 3.4 2.4-1a7 7 0 0 0 1.7 1l.4 3.1h5l.4-3.1a7 7 0 0 0 1.7-1l2.4 1 2-3.4-2-1.5c.1-.3.1-.7.1-1Z" /></>,
    globe: <><circle cx="12" cy="12" r="9" /><path d="M3 12h18M12 3c3 3.2 3 14.8 0 18M12 3c-3 3.2-3 14.8 0 18" /></>,
    bell: <><path d="M18 9a6 6 0 0 0-12 0c0 6-3 7-3 9h18c0-2-3-3-3-9M10 21h4" /></>,
    camera: <><path d="M4 8h4l2-3h4l2 3h4v11H4V8Z" /><circle cx="12" cy="13" r="3" /></>,
    upload: <><path d="M12 16V4M8 8l4-4 4 4" /><path d="M5 15v4h14v-4" /></>,
    arrow: <><path d="M5 12h14M14 7l5 5-5 5" /></>,
    check: <path d="m5 12 4 4L19 6" />,
    close: <path d="m6 6 12 12M18 6 6 18" />,
    play: <><path d="m9 7 8 5-8 5V7Z" /><circle cx="12" cy="12" r="10" /></>,
    download: <><path d="M12 3v12M7 10l5 5 5-5" /><path d="M5 20h14" /></>,
    search: <><circle cx="10.5" cy="10.5" r="6.5" /><path d="m16 16 5 5" /></>,
    menu: <path d="M4 7h16M4 12h16M4 17h16" />,
    info: <><circle cx="12" cy="12" r="9" /><path d="M12 11v6M12 7h.01" /></>,
    clock: <><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 2" /></>,
    rupee: <><path d="M7 5h10M7 9h10M7 5c6 0 6 8 0 8l8 7" /></>,
    rotate: <><path d="M20 7v5h-5" /><path d="M19 12a8 8 0 1 0-2 5.3" /></>,
  };
  return <svg className="ks-icon" width={size} height={size} viewBox="0 0 24 24" aria-hidden="true" {...common}>{paths[name] ?? paths.info}</svg>;
}

export function Action({
  children,
  href,
  tone = "primary",
  icon,
  onClick,
  disabled,
  type = "button",
}: {
  children: ReactNode;
  href?: string;
  tone?: "primary" | "secondary" | "quiet";
  icon?: string;
  onClick?: () => void;
  disabled?: boolean;
  type?: "button" | "submit";
}) {
  const content = <>{children}{icon ? <Icon name={icon} size={17} /> : null}</>;
  const className = `ks-action ks-action--${tone}`;
  return href ? <Link className={className} href={href} onClick={onClick}>{content}</Link> : (
    <button className={className} type={type} onClick={onClick} disabled={disabled}>{content}</button>
  );
}

export function StatusPill({
  children,
  tone = "neutral",
}: {
  children: ReactNode;
  tone?: "neutral" | "success" | "attention" | "mock";
}) {
  return <span className={`ks-status ks-status--${tone}`}>{tone === "success" ? <Icon name="check" size={13} /> : null}{children}</span>;
}

function humanSource(source: string) {
  if (source.includes("sarvam") || source.includes("speech")) return "Voice input";
  if (source.includes("studio")) return "Image quality check";
  if (source.includes("price")) return "Cost and market evidence";
  if (source.includes("trend")) return "Public market evidence";
  if (source.includes("advisor")) return "Your activity record";
  if (source.includes("trade")) return "Your sales record";
  return "Catalog record";
}

export function Provenance({
  value,
  label = "Source details",
}: {
  value?: ProvenanceData | null;
  label?: string;
}) {
  const [open, setOpen] = useState(false);
  if (!value?.source) return <span className="ks-source ks-source--missing"><Icon name="info" size={14} />Source unavailable</span>;
  return (
    <span className="ks-source-wrap">
      <button className="ks-source" type="button" onClick={() => setOpen((current) => !current)} aria-expanded={open}>
        <Icon name="info" size={14} />{label}
      </button>
      {open ? (
        <span className="ks-source-popover" role="status">
          <strong>{humanSource(value.source)}</strong>
          {typeof value.confidence === "number" ? <span>{Math.round(value.confidence * 100)}% confidence</span> : null}
          {value.ts ? <span>Updated {new Date(value.ts).toLocaleDateString("en-IN")}</span> : null}
        </span>
      ) : null}
    </span>
  );
}

export function PageIntro({
  eyebrow,
  title,
  description,
  aside,
}: {
  eyebrow?: string;
  title: string;
  description?: string;
  aside?: ReactNode;
}) {
  return (
    <header className="ks-page-intro" data-reveal>
      <div>
        {eyebrow ? <p className="ks-eyebrow">{eyebrow}</p> : null}
        <h1>{title}</h1>
        {description ? <p>{description}</p> : null}
      </div>
      {aside ? <div className="ks-page-intro__aside">{aside}</div> : null}
    </header>
  );
}

export function EmptyState({
  icon = "catalog",
  title,
  description,
  action,
}: {
  icon?: string;
  title: string;
  description: string;
  action?: ReactNode;
}) {
  return (
    <div className="ks-empty">
      <span><Icon name={icon} size={28} /></span>
      <h2>{title}</h2>
      <p>{description}</p>
      {action}
    </div>
  );
}

export function Skeleton({ className = "" }: { className?: string }) {
  return <span className={`ks-skeleton ${className}`} aria-hidden="true" />;
}

export function ProductMedia({
  src,
  alt,
  className = "",
  emptyLabel = "No product photo yet",
}: {
  src?: string | null;
  alt: string;
  className?: string;
  emptyLabel?: string;
}) {
  const [loaded, setLoaded] = useState(false);
  const imageRef = useCallback((node: HTMLImageElement | null) => {
    if (node?.complete && node.naturalWidth > 0) setLoaded(true);
  }, []);
  if (!src) {
    return <div className={`ks-media-empty ${className}`}><Icon name="image" size={32} /><span>{emptyLabel}</span></div>;
  }
  return (
    <span className={`ks-product-media ${loaded ? "is-loaded" : ""} ${className}`}>
      {/* API media can be local or remote and is not known at build time. */}
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img ref={imageRef} src={src} alt={alt} onLoad={() => setLoaded(true)} />
    </span>
  );
}

export function CreationRail({ current }: { current: WorkspaceView }) {
  const active = creationSteps.findIndex(([id]) => id === current);
  if (active < 0) return null;
  return (
    <nav className="ks-rail" aria-label="Product creation progress">
      {creationSteps.map(([id, label, href], index) => (
        <Link
          href={href}
          key={id}
          className={`${index === active ? "is-current" : ""}${index < active ? " is-complete" : ""}`}
          aria-current={index === active ? "step" : undefined}
        >
          <span>{index < active ? <Icon name="check" size={14} /> : index + 1}</span>
          <small>{label}</small>
        </Link>
      ))}
    </nav>
  );
}

export function WorkspaceShell({
  view,
  children,
}: {
  view: WorkspaceView;
  children: ReactNode;
}) {
  const pathname = usePathname();
  const router = useRouter();
  const root = useRef<HTMLDivElement>(null);
  const [menuOpen, setMenuOpen] = useState(false);
  const [profile, setProfile] = useState<{ name?: string; cluster?: string; lang?: string }>({});
  const [speakBusy, setSpeakBusy] = useState(false);
  const [speakEnabled, setSpeakEnabled] = useState(true);

  useEffect(() => {
    document.documentElement.classList.toggle(
      "ks-large-text",
      window.localStorage.getItem("kalasetu_large_text") === "true",
    );
    const timer = window.setTimeout(() => {
      setSpeakEnabled(window.localStorage.getItem("kalasetu_speak_screens") !== "false");
    }, 0);
    api.me().then((result) => setProfile(result.artisan as typeof profile)).catch(() => undefined);
    return () => window.clearTimeout(timer);
  }, []);

  useEffect(() => {
    document.body.classList.add("ks-workspace-active");
    return () => document.body.classList.remove("ks-workspace-active");
  }, []);

  useEffect(() => {
    const scope = root.current;
    if (!scope || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const context = gsap.context(() => {
      gsap.fromTo("[data-reveal]", { autoAlpha: 0, y: 18 }, {
        autoAlpha: 1,
        y: 0,
        duration: 0.55,
        stagger: 0.06,
        ease: "power3.out",
        clearProps: "opacity,visibility,transform",
      });
    }, scope);
    return () => context.revert();
  }, [pathname]);

  const speakPage = async () => {
    const text = root.current?.querySelector("h1")?.textContent;
    if (!text || speakBusy) return;
    setSpeakBusy(true);
    try {
      const result = await api.tts(text, profile.lang || "en-IN");
      await new Audio(`data:${result.content_type};base64,${result.audio_b64}`).play();
    } finally {
      setSpeakBusy(false);
    }
  };

  const signOut = () => {
    clearSession();
    router.push("/");
    router.refresh();
  };

  const displayName = profile.name || "Artisan";
  const initials = displayName.split(/\s+/).map((part) => part[0]).join("").slice(0, 2).toUpperCase();
  const artwork = workspaceArtwork[view];

  return (
    <div className="ks-workspace" ref={root}>
      <aside className={`ks-sidebar${menuOpen ? " is-open" : ""}`}>
        <div className="ks-sidebar__brand">
          <Link href="/" aria-label="KalaSetu workspace home">
            <Image src="/assets/brand/logo-transparent.png" alt="KalaSetu" width={1141} height={535} priority />
          </Link>
          <button type="button" onClick={() => setMenuOpen(false)} aria-label="Close navigation"><Icon name="close" /></button>
        </div>
        <div className="ks-sidebar__scroll">
          {navGroups.map((group) => (
            <nav key={group.label} aria-label={group.label}>
              <p>{group.label}</p>
              {group.items.map(([id, label, href, icon]) => (
                <Link
                  href={href}
                  key={href}
                  className={view === id ? "is-active" : undefined}
                  aria-current={view === id ? "page" : undefined}
                  onClick={() => setMenuOpen(false)}
                >
                  <Icon name={icon} /><span>{label}</span>
                </Link>
              ))}
            </nav>
          ))}
        </div>
        <div className="ks-sidebar__footer">
          <Link href="/settings" className={view === "settings" ? "is-active" : undefined}><Icon name="settings" /><span>Settings</span></Link>
          <p>Your craft.<br /><em>Your story.</em></p>
        </div>
      </aside>
      {menuOpen ? <button className="ks-sidebar-backdrop" aria-label="Close navigation" onClick={() => setMenuOpen(false)} /> : null}
      <div className="ks-main">
        <header className="ks-topbar">
          <button className="ks-menu" type="button" onClick={() => setMenuOpen(true)} aria-label="Open navigation"><Icon name="menu" /></button>
          <Link className="ks-mobile-logo" href="/">
            <Image src="/assets/brand/logo-transparent.png" alt="KalaSetu" width={1141} height={535} />
          </Link>
          <div className="ks-topbar__actions">
            <Link href="/settings" className="ks-language"><Icon name="globe" size={17} />{profile.lang?.split("-")[0]?.toUpperCase() || "EN"}</Link>
            {speakEnabled ? <button type="button" onClick={speakPage} disabled={speakBusy}><Icon name="voice" size={17} />{speakBusy ? "Speaking…" : "Speak"}</button> : null}
            <span className="ks-profile">
              <b>{initials}</b>
              <span><strong>{displayName}</strong><small>{profile.cluster || "Your craft workspace"}</small></span>
            </span>
            <button className="ks-signout" type="button" onClick={signOut}>Sign out</button>
          </div>
        </header>
        {artwork ? (
          <div className={`ks-ambient-art ${artwork.className}`} aria-hidden="true">
            <Image src={artwork.src} alt={artwork.alt} width={760} height={900} />
          </div>
        ) : null}
        <CreationRail current={view} />
        <main className="ks-content">{children}</main>
      </div>
    </div>
  );
}
