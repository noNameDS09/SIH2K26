"use client";

import Link from "next/link";
import { useEffect, useRef, useState } from "react";
import gsap from "gsap";
import { Icon, ProductMedia, StatusPill } from "@/components/workspace/workspace-ui";
import { useTranslation } from "@/lib/language-context";

type PublicListing = {
  id: string;
  title?: string;
  title_en?: string;
  title_hi?: string;
  title_mr?: string;
  description?: string;
  desc_en?: string;
  desc_hi?: string;
  desc_mr?: string;
  image_url?: string;
  photo_url?: string;
  cluster_name?: string;
  cluster?: string;
  category?: string;
  craft?: string;
  artisan?: { name?: string; cluster?: string } | null;
  listed_price?: number;
  fields?: Record<string, unknown>;
  status?: string;
  signature?: string | null;
  signed_at?: string | null;
  source_label?: string;
  qr_url?: string | null;
  translations?: Record<string, { title?: string; description?: string }>;
};

const tabs = ["Details", "Story", "Care", "Verification"] as const;

function field(listing: PublicListing, ...keys: string[]) {
  for (const key of keys) {
    const value = listing.fields?.[key];
    if (value !== undefined && value !== null && String(value).trim()) return String(value);
  }
  return "";
}

export function PublicListingView({ listing }: { listing: PublicListing }) {
  const root = useRef<HTMLElement>(null);
  const { t, language } = useTranslation();
  const [tab, setTab] = useState<(typeof tabs)[number]>("Details");

  const tr = (listing as { translations?: Record<string, { title?: string; description?: string }> }).translations?.[language];
  const title = tr?.title || (language.startsWith("hi") ? listing.title_hi : undefined) || (language.startsWith("mr") ? (listing.title_mr || listing.title_hi) : undefined) || listing.title || listing.title_en || listing.title_hi || "Untitled craft";
  const description = tr?.description || (language.startsWith("hi") ? listing.desc_hi : undefined) || (language.startsWith("mr") ? (listing.desc_mr || listing.desc_hi) : undefined) || listing.description || listing.desc_en || listing.desc_hi || "";
  const artisanName = listing.artisan?.name || "The artisan";
  const region = listing.cluster_name || listing.artisan?.cluster || listing.cluster || "";
  const material = field(listing, "material", "materials");
  const technique = field(listing, "technique", "making_process", "process");
  const dimensions = field(listing, "dimensions", "size");
  const care = field(listing, "care", "care_instructions");
  const story = field(listing, "story", "what_makes_it_special", "special") || description;

  useEffect(() => {
    const scope = root.current;
    if (!scope || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const context = gsap.context(() => {
      gsap.fromTo("[data-public-reveal]", { autoAlpha: 0, y: 18 }, {
        autoAlpha: 1,
        y: 0,
        duration: 0.6,
        stagger: 0.08,
        ease: "power3.out",
        clearProps: "opacity,visibility,transform",
      });
    }, scope);
    return () => context.revert();
  }, []);

  useEffect(() => {
    const panel = root.current?.querySelector(".pub-detail__panel");
    if (!panel || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    gsap.fromTo(panel, { autoAlpha: 0, x: 10 }, {
      autoAlpha: 1,
      x: 0,
      duration: 0.3,
      ease: "power2.out",
      clearProps: "opacity,visibility,transform",
    });
  }, [tab]);

  return (
    <main className="pub-detail" ref={root}>
      <div className="pub-detail__top" data-public-reveal>
        <Link href="/market"><Icon name="arrow" size={16} />Back to catalog</Link>
        <StatusPill tone={listing.signature ? "success" : "neutral"}>
          {listing.signature ? "Signed listing" : "Public listing"}
        </StatusPill>
      </div>

      <section className="pub-detail__grid">
        <div className="pub-gallery" data-public-reveal>
          <ProductMedia src={listing.image_url || listing.photo_url} alt={title} />
          <div className="pub-gallery__note">
            <span>Provided by the artisan</span>
            <p>Product colours are kept true to the original photograph.</p>
          </div>
        </div>

        <article className="pub-detail__content" data-public-reveal>
          <div className="pub-detail__heading">
            <div>
              <p>{listing.craft || listing.category || "Handmade craft"}</p>
              <h1>{title}</h1>
              <span>By {artisanName}{region ? ` · ${region}` : ""}</span>
            </div>
            <strong>{listing.listed_price ? `₹${Number(listing.listed_price).toLocaleString("en-IN")}` : "Price on request"}</strong>
          </div>

          <div className="pub-tabs" role="tablist" aria-label="Product information">
            {tabs.map((item) => {
              const labelMap: Record<string, string> = {
                Details: t("card.details_tab", "Details"),
                Story: t("card.story_tab", "Story"),
                Care: t("card.care_tab", "Care"),
                Verification: t("card.verification_tab", "Verification"),
              };
              return (
                <button
                  key={item}
                  role="tab"
                  type="button"
                  aria-selected={tab === item}
                  className={tab === item ? "is-active" : undefined}
                  onClick={() => setTab(item)}
                >
                  {labelMap[item] || item}
                </button>
              );
            })}
          </div>

          <section className="pub-detail__panel" role="tabpanel">
            {tab === "Details" ? (
              <dl className="pub-detail-list">
                {material ? <div><dt><Icon name="catalog" />Material</dt><dd>{material}</dd></div> : null}
                {technique ? <div><dt><Icon name="settings" />Technique</dt><dd>{technique}</dd></div> : null}
                {dimensions ? <div><dt><Icon name="image" />Dimensions</dt><dd>{dimensions}</dd></div> : null}
                {region ? <div><dt><Icon name="globe" />Region</dt><dd>{region}</dd></div> : null}
                {care ? <div><dt><Icon name="shield" />Care</dt><dd>{care}</dd></div> : null}
              </dl>
            ) : null}
            {tab === "Story" ? (
              <div className="pub-story">
                <p>{story || "No artisan story has been added to this listing yet."}</p>
                {listing.desc_hi ? <blockquote lang="hi">{listing.desc_hi}</blockquote> : null}
              </div>
            ) : null}
            {tab === "Care" ? (
              <div className="pub-story">
                <h2>Care for this piece</h2>
                <p>{care || "No specific care instructions were provided. Keep the piece clean, dry, and protected from harsh handling."}</p>
              </div>
            ) : null}
            {tab === "Verification" ? (
              <div className="pub-verification">
                <Icon name="shield" size={34} />
                <div>
                  <h2>{listing.signature ? "Signed by KalaSetu" : "Verification pending"}</h2>
                  <p>{listing.signature
                    ? `This record was approved by the artisan${listing.signed_at ? ` on ${new Date(listing.signed_at).toLocaleDateString("en-IN")}` : ""}. The details displayed here are the details that were signed.`
                    : "This public record has not yet been signed."}</p>
                  {listing.signature ? <code>{listing.signature.slice(0, 28)}…</code> : null}
                </div>
              </div>
            ) : null}
          </section>

          <div className="pub-detail__trust">
            <Icon name="shield" size={28} />
            <div>
              <strong>{listing.signature ? "This listing is signed" : "Signature not available"}</strong>
              <p>{listing.signature ? "The artisan reviewed this product record before it became public." : "Check back after the artisan completes approval."}</p>
            </div>
            <button type="button" onClick={() => setTab("Verification")}>View record <Icon name="arrow" size={15} /></button>
          </div>
        </article>
      </section>

      <footer className="pub-detail__footer" aria-hidden="true">
        <span>Crafts connect</span><em>communities.</em>
      </footer>
    </main>
  );
}
