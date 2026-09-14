import { RoutePage } from "@/components/route-page";

export default function SettingsPage() {
  return <RoutePage config={{ eyebrow: "Your workspace", title: "Make the workspace feel like yours.", description: "Set language, voice preferences, and export choices without losing your place in the listing journey.", primaryLabel: "Preferences", sideTitle: "Quiet control.", sideCopy: "The interface stays simple, with the details available whenever you want to inspect them.", sideItems: ["Language", "Speak screens", "Export data"] }} />;
}
