import { RoutePage } from "@/components/route-page";

export default function PricingPage() {
  return <RoutePage config={{ eyebrow: "Create · 05", title: "Price the time, not just the object.", description: "See the floor, recommended, aspirational, and listed values shaped by material cost, labour, effort, cluster, and comparable work.", primaryLabel: "Three-band pricing", primaryHref: "/approval", steps: ["Floor", "Recommended", "Aspirational", "Listed"], sideTitle: "You keep the final say.", sideCopy: "The recommendation is a guide. An override remains your decision and is stored as the listed price." }} />;
}
