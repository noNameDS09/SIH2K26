import { RoutePage } from "@/components/route-page";

export default function LivePage() {
  return <RoutePage config={{ eyebrow: "Create · 03", title: "Tell the story in your own voice.", description: "A guided conversation asks one useful question at a time, reads it back, and lets you repair anything that sounds wrong.", primaryLabel: "Voice cataloger", primaryHref: "/intelligence", steps: ["Listen", "Answer", "Confirm"], sideTitle: "Not a chatbot.", sideCopy: "This is a focused catalog interview for one physical product, with a clear fallback to text.", sideItems: ["One missing slot at a time", "Confirm by ear", "Never invent unknown details"] }} />;
}
