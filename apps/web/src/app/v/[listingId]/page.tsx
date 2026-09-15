import Link from "next/link";
import { PublicListingView } from "@/components/public-listing-view";

export default async function PublicListingPage({ params }: { params: Promise<{ listingId: string }> }) {
  const { listingId } = await params;
  const apiBase = (process.env.NEXT_PUBLIC_API_BASE_URL || "http://localhost:8000").replace(/\/$/, "");
  const response = await fetch(`${apiBase}/v/${encodeURIComponent(listingId)}`, { cache: "no-store" }).catch(() => null);
  const listing = response?.ok ? await response.json() : null;
  if (!listing) {
    return (
      <main className="pub-not-found">
        <p>Public listing</p>
        <h1>This craft record is not available.</h1>
        <span>It may still be a draft, or the link may have changed.</span>
        <Link href="/market">Return to the catalog</Link>
      </main>
    );
  }
  return <PublicListingView listing={listing} />;
}
