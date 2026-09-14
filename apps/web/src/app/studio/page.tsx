import { RoutePage } from "@/components/route-page";

export default function StudioPage() {
  return <RoutePage config={{ eyebrow: "Create · 02", title: "Give the work room to breathe.", description: "Compare the original with a clean studio version, choose from six bundled surfaces, and see the colour check before continuing.", primaryLabel: "Original · studio", primaryHref: "/live", steps: ["Original", "Studio", "Colour check"], sideTitle: "Natural colour stays sacred.", sideCopy: "The studio image is accepted only when the ΔE quality gate passes. If it fails, the original remains the truth." }} />;
}
