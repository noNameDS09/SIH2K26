import type { Metadata } from "next";
import "./globals.css";
import "./workspace.css";
import "./workspace-pages.css";
import { SiteHeader } from "@/components/site-header";
import { LanguageProvider } from "@/lib/language-context";

export const metadata: Metadata = {
  title: "KalaSetu — Bridging artisans to a brighter tomorrow",
  description:
    "A calmer digital bridge for India's artisan communities: voice, craft, and opportunity in one place.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" data-scroll-behavior="smooth">
      <body>
        <LanguageProvider>
          <SiteHeader />
          {children}
        </LanguageProvider>
      </body>
    </html>
  );
}
