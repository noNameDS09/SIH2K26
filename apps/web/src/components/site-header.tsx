"use client";

import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";
import { useTranslation } from "@/lib/language-context";

export function SiteHeader() {
  const pathname = usePathname();
  const [open, setOpen] = useState(false);
  const { t, currentLanguage, openModal } = useTranslation();
  const workspaceRoutes = ["/language", "/otp", "/onboarding", "/capture", "/studio", "/live", "/intelligence", "/pricing", "/approval", "/distribute", "/shop", "/money", "/insights", "/settings"];

  if (workspaceRoutes.includes(pathname)) return null;

  return (
    <header className={`site-header${open ? " is-open" : ""}`}>
      <Link className="brand-lockup" href="/" aria-label="KalaSetu home" onClick={() => setOpen(false)}>
        <Image src="/assets/brand/logo-transparent.png" alt="KalaSetu" width={1141} height={535} priority />
      </Link>
      <nav className="site-nav" aria-label="Primary navigation">
        <Link href="/" aria-current={pathname === "/" ? "page" : undefined} onClick={() => setOpen(false)}>{t("nav.home", "Home")}</Link>
        <Link href="/market" aria-current={pathname === "/market" ? "page" : undefined} onClick={() => setOpen(false)}>{t("nav.market", "Public catalog")}</Link>
        <Link href="/#how-it-works" onClick={() => setOpen(false)}>{t("nav.how_it_works", "How it works")}</Link>
        <Link href="/about" aria-current={pathname === "/about" ? "page" : undefined} onClick={() => setOpen(false)}>{t("nav.about", "About")}</Link>
      </nav>
      <div className="header-actions">
        <button
          type="button"
          className="language-chip"
          onClick={() => {
            setOpen(false);
            openModal();
          }}
          title={t("nav.switch_language", "Switch language")}
          style={{ cursor: "pointer", display: "inline-flex", alignItems: "center", gap: "6px" }}
        >
          <span>🌐</span>
          <span>{currentLanguage.nativeName}</span>
        </button>
        <Link className="header-link" href="/language" onClick={() => setOpen(false)}>{t("nav.enter_artisan", "Enter as Artisan")} <span aria-hidden="true">→</span></Link>
      </div>
      <button className="menu-toggle" type="button" aria-label={open ? t("nav.close_menu", "Close menu") : t("nav.open_menu", "Open menu")} aria-expanded={open} onClick={() => setOpen((current) => !current)}>
        <span />
      </button>
    </header>
  );
}
