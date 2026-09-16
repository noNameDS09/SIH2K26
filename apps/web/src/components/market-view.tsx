"use client";

import Link from "next/link";
import { useDeferredValue, useEffect, useMemo, useRef, useState } from "react";
import gsap from "gsap";
import { api, type Listing } from "@/lib/api-client";
import { Icon, ProductMedia, Skeleton, StatusPill } from "@/components/workspace/workspace-ui";

function value(item: Listing, ...keys: string[]) {
  for (const key of keys) {
    const found = key.includes(".")
      ? key.split(".").reduce<unknown>((current, part) => (
        typeof current === "object" && current ? (current as Record<string, unknown>)[part] : undefined
      ), item)
      : item[key];
    if (found !== undefined && found !== null && String(found).trim()) return String(found);
  }
  return "";
}

function unique(items: Listing[], getter: (item: Listing) => string) {
  return [...new Set(items.map(getter).filter(Boolean))].sort();
}

export function MarketView() {
  const root = useRef<HTMLElement>(null);
  const [items, setItems] = useState<Listing[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [query, setQuery] = useState("");
  const [category, setCategory] = useState("");
  const [material, setMaterial] = useState("");
  const [region, setRegion] = useState("");
  const deferredQuery = useDeferredValue(query.trim().toLowerCase());

  useEffect(() => {
    api.market()
      .then((result) => setItems(result.items || []))
      .catch((cause) => setError(cause instanceof Error ? cause.message : "The catalog could not be loaded."))
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    const scope = root.current;
    if (!scope || loading || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const context = gsap.context(() => {
      gsap.fromTo("[data-catalog-card]", { autoAlpha: 0, y: 20 }, {
        autoAlpha: 1,
        y: 0,
        duration: 0.5,
        stagger: 0.045,
        ease: "power3.out",
        clearProps: "opacity,visibility,transform",
      });
    }, scope);
    return () => context.revert();
  }, [loading, category, material, region, deferredQuery]);

  const categories = unique(items, (item) => value(item, "category", "craft", "fields.craft"));
  const materials = unique(items, (item) => value(item, "fields.material", "material"));
  const regions = unique(items, (item) => value(item, "cluster_name", "cluster"));

  const filtered = useMemo(() => items.filter((item) => {
    const itemCategory = value(item, "category", "craft", "fields.craft");
    const itemMaterial = value(item, "fields.material", "material");
    const itemRegion = value(item, "cluster_name", "cluster");
    const haystack = [
      value(item, "title", "title_en", "title_hi"),
      itemCategory,
      itemMaterial,
      itemRegion,
      value(item, "description", "desc_en"),
    ].join(" ").toLowerCase();
    return (!deferredQuery || haystack.includes(deferredQuery))
      && (!category || itemCategory === category)
      && (!material || itemMaterial === material)
      && (!region || itemRegion === region);
  }), [items, deferredQuery, category, material, region]);

  const reset = () => {
    setQuery("");
    setCategory("");
    setMaterial("");
    setRegion("");
  };

  return (
    <main className="pub-catalog" ref={root}>
      <section className="pub-catalog__intro">
        <p className="pub-eyebrow">KalaSetu public catalog</p>
        <h1>Craft, carried forward.</h1>
        <p>Explore signed product stories shared directly by artisan communities across India.</p>
      </section>

      <section className="pub-toolbar" aria-label="Catalog search and filters">
        <label className="pub-search">
          <Icon name="search" size={19} />
          <span className="sr-only">Search catalog</span>
          <input
            type="search"
            placeholder="Search products, crafts, materials or regions"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
          />
        </label>
        <span className="pub-result-count">{filtered.length} {filtered.length === 1 ? "product" : "products"}</span>
        <button className="pub-reset" type="button" onClick={reset}>Reset filters</button>
        <div className="pub-filters">
          <label>
            <span>Category</span>
            <select value={category} onChange={(event) => setCategory(event.target.value)}>
              <option value="">All categories</option>
              {categories.map((option) => <option value={option} key={option}>{option}</option>)}
            </select>
          </label>
          <label>
            <span>Material</span>
            <select value={material} onChange={(event) => setMaterial(event.target.value)}>
              <option value="">All materials</option>
              {materials.map((option) => <option value={option} key={option}>{option}</option>)}
            </select>
          </label>
          <label>
            <span>Region</span>
            <select value={region} onChange={(event) => setRegion(event.target.value)}>
              <option value="">All regions</option>
              {regions.map((option) => <option value={option} key={option}>{option}</option>)}
            </select>
          </label>
          <span className="pub-verification-filter"><Icon name="shield" size={17} />Published records</span>
        </div>
      </section>

      {error ? (
        <section className="pub-state" role="alert">
          <Icon name="info" size={28} />
          <h2>The catalog is taking a pause.</h2>
          <p>{error}</p>
          <button type="button" onClick={() => window.location.reload()}>Try again</button>
        </section>
      ) : loading ? (
        <section className="pub-grid" aria-label="Loading published products">
          {Array.from({ length: 8 }, (_, index) => (
            <article className="pub-card pub-card--loading" key={index}>
              <Skeleton className="pub-card__media" />
              <Skeleton /><Skeleton /><Skeleton />
            </article>
          ))}
        </section>
      ) : filtered.length ? (
        <section className="pub-grid" aria-label="Published craft listings">
          {filtered.map((item) => {
            const title = value(item, "title", "title_en", "title_hi") || "Untitled craft";
            const image = value(item, "image_url", "photo_url", "studioUrl", "originalUrl");
            const craft = value(item, "craft", "category", "fields.craft") || "Handmade craft";
            const itemRegion = value(item, "cluster_name", "cluster");
            const artisan = typeof item.artisan === "object" && item.artisan ? item.artisan.name : "";
            const price = item.prices?.listed?.value || item.prices?.recommended?.value || Number(item.listed_price || 0);
            return (
              <article className="pub-card" key={item.id} data-catalog-card>
                <Link href={`/v/${item.id}`} className="pub-card__image" aria-label={`View ${title}`}>
                  <ProductMedia src={image} alt={title} />
                  <StatusPill tone="success">Published</StatusPill>
                </Link>
                <div className="pub-card__copy">
                  <p>{craft}{itemRegion ? ` · ${itemRegion}` : ""}</p>
                  <h2>{title}</h2>
                  {artisan ? <span>By {artisan}</span> : null}
                  <div>
                    <strong>{price ? `₹${Number(price).toLocaleString("en-IN")}` : "Price on request"}</strong>
                    <Link href={`/v/${item.id}`}>View full details <Icon name="arrow" size={16} /></Link>
                  </div>
                </div>
              </article>
            );
          })}
        </section>
      ) : (
        <section className="pub-state">
          <Icon name="search" size={28} />
          <h2>{items.length ? "No crafts match those filters." : "The first collection is being prepared."}</h2>
          <p>{items.length ? "Try removing a filter or using a broader search." : "Published artisan listings will appear here as soon as they are signed."}</p>
          {items.length ? <button type="button" onClick={reset}>Clear filters</button> : null}
        </section>
      )}

      <aside className="pub-catalog__quote" aria-hidden="true">
        <span>One craft.</span><span>One maker.</span><em>A living record.</em>
      </aside>
    </main>
  );
}
