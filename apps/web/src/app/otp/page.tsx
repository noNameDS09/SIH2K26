import { RoutePage } from "@/components/route-page";

export default function OtpPage() {
  return <RoutePage config={{ eyebrow: "Step 02 · Access", title: "A simple hello before we begin.", description: "Enter a phone number and confirm with the six-digit code. The demo code is 123456.", primaryLabel: "Phone verification", primaryHref: "/onboarding", sideTitle: "A familiar first step.", sideCopy: "A family helper can type this once. After that, the artisan can speak.", sideItems: ["Keypad-first", "Mock — for SIH demo", "No voice OTP"] }} />;
}
