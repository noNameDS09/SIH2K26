"use client";

import { useSyncExternalStore } from "react";
import { LandingPage } from "@/components/landing-page";
import { ArtisanWorkspace } from "@/components/artisan-workspace";

export function HomeGate() {
  const signedIn = useSyncExternalStore(
    () => () => undefined,
    () => Boolean(window.localStorage.getItem("kalasetu_token")),
    () => false,
  );
  return signedIn ? <ArtisanWorkspace view="home" /> : <LandingPage />;
}
