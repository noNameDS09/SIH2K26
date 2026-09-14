"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useState } from "react";

type CatalogItem = { id: string; title: string; category: string; cluster: string; description: string; image: string };

const fallbackItems: CatalogItem[] = [
  { id: "mock-handwoven-textile", title: "Mock — Handwoven textile", category: "Handloom & Textiles", cluster: "Varanasi", description: "A synthetic preview record for the KalaSetu show catalog.", image: "/assets/Landing-Support.png" },
  { id: "mock-brass-craft", title: "Mock — Brass craft object", category: "Metal Craft & Dhokra", cluster: "Moradabad", description: "A synthetic preview record for the KalaSetu show catalog.", image: "/assets/heroes/KS-Hero.png" },
  { id: "mock-artisan-work", title: "Mock — Artisan process", category: "Craft story", cluster: "India", description: "A synthetic preview record for the KalaSetu show catalog.", image: "/assets/Landing-Support-2.png" },
];

export function MarketView() {
  const [items, setItems] = useState(fallbackItems);

  useEffect(() => {
    const api = process.env.NEXT_PUBLIC_API_BASE_URL;
    if (!api) return;
    fetch(`${api}/v1/market`)
      .then((response) => response.ok ? response.json() : Promise.reject(new Error("market unavailable")))
      .then((payload) => {
        const nextItems = (payload.items ?? []).slice(0, 30).map((item: Record<string, unknown>) => ({
          id: String(item.id ?? "listing"),
          title: String(item.title ?? item.title_en ?? "Untitled craft"),
          category: String(item.category ?? "Handmade craft"),
          cluster: String(item.cluster_name ?? item.cluster ?? "India"),
          description: String(item.description ?? "A published KalaSetu listing."),
          image: String(item.image_url ?? item.photo_url ?? "/assets/Landing-Support.png"),
        }));
        if (nextItems.length) setItems(nextItems);
      })
      .catch(() => undefined);
  }, []);

  return (
    <main className="market-page">
      <section className="market-hero">
        <div><span className="section-mark">The KalaSetu show catalog</span><h1>Made to be found.</h1></div>
        <p>A living collection of craft, material, and the people who carry each tradition forward.</p>
      </section>
      <div className="market-toolbar" aria-label="Catalog filters"><span className="filter-chip">All craft</span><span className="filter-chip">All regions</span><span className="filter-chip">Verified records</span></div>
      <section className="catalog-grid" aria-label="Published craft listings">
        {items.map((item) => (
          <article className="catalog-card" key={item.id}>
            <div className="catalog-card-media"><Image src={item.image} alt={item.title} width={900} height={650} unoptimized /></div>
            <div className="catalog-card-copy">
              <div className="catalog-meta"><span>{item.category}</span><span>{item.cluster}</span></div>
              <h2>{item.title}</h2><p>{item.description}</p>
              <Link className="catalog-card-link" href={`/v/${item.id}`}>View full details <span aria-hidden="true">↗</span></Link>
            </div>
          </article>
        ))}
      </section>
    </main>
  );
}
