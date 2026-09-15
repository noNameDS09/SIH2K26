"use client";

import type { ComponentType } from "react";
import { AccessFlow } from "@/components/workspace/access-pages";
import {
  ApprovalPage,
  CapturePage,
  DistributionPage,
  IntelligencePage,
  LiveCatalogPage,
  PricingPage,
  StudioPage,
} from "@/components/workspace/creation-pages";
import {
  CatalogPage,
  HomePage,
  InsightsPage,
  MoneyPage,
  SettingsPage,
} from "@/components/workspace/management-pages";
import { WorkspaceShell, type WorkspaceView } from "@/components/workspace/workspace-ui";

export type ArtisanWorkspaceView = WorkspaceView | "language" | "otp" | "onboarding";

const pages: Record<WorkspaceView, ComponentType> = {
  home: HomePage,
  capture: CapturePage,
  studio: StudioPage,
  live: LiveCatalogPage,
  intelligence: IntelligencePage,
  pricing: PricingPage,
  approval: ApprovalPage,
  distribute: DistributionPage,
  shop: CatalogPage,
  money: MoneyPage,
  insights: InsightsPage,
  settings: SettingsPage,
};

export function ArtisanWorkspace({ view }: { view: ArtisanWorkspaceView }) {
  if (view === "language" || view === "otp" || view === "onboarding") {
    return <AccessFlow view={view} />;
  }
  const Page = pages[view];
  if (view === "home" || view === "shop" || view === "money" || view === "insights" || view === "settings") {
    return <Page />;
  }
  return (
    <WorkspaceShell view={view}>
      <Page />
    </WorkspaceShell>
  );
}
