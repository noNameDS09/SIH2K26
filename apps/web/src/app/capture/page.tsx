import { RoutePage } from "@/components/route-page";

export default function CapturePage() {
  return <RoutePage config={{ eyebrow: "Create · 01", title: "Start with what is in your hands.", description: "Take a clear product photograph or upload one from the phone. The frame guide keeps the object honest and useful.", primaryLabel: "Capture a product", primaryHref: "/studio", steps: ["Camera", "Upload", "Frame guide"], sideTitle: "One product at a time.", sideCopy: "The app and web workspace share the same listing shape, so a published record can travel between them." }} />;
}
