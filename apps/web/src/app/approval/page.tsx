import { RoutePage } from "@/components/route-page";

export default function ApprovalPage() {
  return <RoutePage config={{ eyebrow: "Create · 06", title: "Hear it before it leaves your hands.", description: "Listen to the full bilingual card, inspect its source details, and approve only when the listing sounds like the work you made.", primaryLabel: "Review and approve", primaryHref: "/distribute", steps: ["Listen", "Inspect", "Approve"], sideTitle: "A signed moment.", sideCopy: "Approval freezes the listing payload before the QR and public projection are created." }} />;
}
