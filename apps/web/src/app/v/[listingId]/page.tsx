import Image from "next/image";
import Link from "next/link";

export default async function PublicListingPage({ params }: { params: Promise<{ listingId: string }> }) {
  const { listingId } = await params;
  const label = listingId.replaceAll("-", " ");
  return (
    <main className="public-card">
      <div className="public-card-grid">
        <div className="public-card-image"><Image src="/assets/Landing-Support-2.png" alt="Mock — artisan craft process" width={2172} height={724} /></div>
        <div className="public-card-copy">
          <span className="section-mark">Public listing · {listingId}</span>
          <h1>{label}</h1>
          <p>This public card is ready to receive the signed listing record from KalaSetu. Product details, artisan story, and provenance will appear here.</p>
          <span className="provenance-note">Mock — for SIH demo</span>
          <div className="hero-actions"><Link className="button-primary" href="/market">Back to the collection <span aria-hidden="true">↗</span></Link></div>
        </div>
      </div>
    </main>
  );
}
