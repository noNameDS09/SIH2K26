import Link from "next/link";

export default async function PublicListingPage({ params }: { params: Promise<{ listingId: string }> }) {
  const { listingId } = await params;
  const apiBase = (process.env.NEXT_PUBLIC_API_BASE_URL || "http://localhost:8000").replace(/\/$/, "");
  const response = await fetch(`${apiBase}/v/${encodeURIComponent(listingId)}`, { cache: "no-store" }).catch(() => null);
  const listing = response?.ok ? await response.json() : null;
  const label = listing?.title || listing?.title_en || listingId.replaceAll("-", " ");
  const image = listing?.image_url || listing?.photo_url || "/assets/Landing-Support-2.png";
  return (
    <main className="public-card">
      <div className="public-card-grid">
        <div className="public-card-image"><img src={image} alt={label} /></div>
        <div className="public-card-copy">
          <span className="section-mark">Public listing · {listingId}</span>
          <h1>{label}</h1>
          <p>{listing?.description || listing?.desc_en || "This public card contains the signed product story shared by the artisan."}</p>
          <div className="public-detail-row"><span>{listing?.cluster_name || listing?.cluster || "Artisan cluster"}</span><strong>{listing?.listed_price ? `₹${listing.listed_price}` : "Price to be confirmed"}</strong></div>
          <span className="provenance-note">{listing?.source_label || "KalaSetu verified listing"}</span>
          <div className="hero-actions"><Link className="button-primary" href="/market">Back to the collection <span aria-hidden="true">↗</span></Link></div>
        </div>
      </div>
    </main>
  );
}
