import { RoutePage } from "@/components/route-page";

export default function LanguagePage() {
  return <RoutePage config={{ eyebrow: "Start here", title: "Choose the language that feels like home.", description: "KalaSetu begins with your voice. Pick a language and we will keep the journey clear from this point onward.", primaryLabel: "Language selection", primaryHref: "/otp", sideTitle: "Your words stay yours.", sideCopy: "All supported language choices will persist across the artisan workspace.", sideItems: ["Indic languages + English", "Voice-first after OTP", "Text always available as fallback"] }} />;
}
