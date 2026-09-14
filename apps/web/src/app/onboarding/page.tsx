import { RoutePage } from "@/components/route-page";

export default function OnboardingPage() {
  return <RoutePage config={{ eyebrow: "Step 03 · Pehchan", title: "Let the work meet the person.", description: "Add the artisan profile, cluster, consent, and Pehchan-shaped details that make the record feel grounded.", primaryLabel: "Artisan profile", primaryHref: "/capture", sideTitle: "Identity with dignity.", sideCopy: "The Aadhaar camera step is a clearly labelled mock for the SIH demo; it is never presented as live government verification.", sideItems: ["Pehchan-shaped fields", "Mock Aadhaar badge", "Consent before capture"] }} />;
}
