"use client";

import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";

export function SiteHeader() {
  const pathname = usePathname();
  const [open, setOpen] = useState(false);

  return (
    <header className={`site-header${open ? " is-open" : ""}`}>
      <Link className="brand-lockup" href="/" aria-label="KalaSetu home" onClick={() => setOpen(false)}>
        <Image src="/assets/brand/logo.jpeg" alt="KalaSetu" width={142} height={73} priority />
      </Link>
      <nav className="site-nav" aria-label="Primary navigation">
        <Link href="/market" aria-current={pathname === "/market" ? "page" : undefined} onClick={() => setOpen(false)}>The collection</Link>
        <Link href="/#how-it-works" onClick={() => setOpen(false)}>How it works</Link>
        <Link href="/#for-artisans" onClick={() => setOpen(false)}>For artisans</Link>
      </nav>
      <div className="header-actions">
        <Link className="language-chip" href="/language" onClick={() => setOpen(false)}>EN / हिं</Link>
        <Link className="header-link" href="/language" onClick={() => setOpen(false)}>Artisan access</Link>
      </div>
      <button className="menu-toggle" type="button" aria-label={open ? "Close menu" : "Open menu"} aria-expanded={open} onClick={() => setOpen((current) => !current)}>
        <span />
      </button>
    </header>
  );
}
