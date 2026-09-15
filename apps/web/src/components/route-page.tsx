import Link from "next/link";

export type RoutePageConfig = {
  eyebrow: string;
  title: string;
  description: string;
  primaryLabel?: string;
  primaryHref?: string;
  steps?: string[];
  sideTitle?: string;
  sideCopy?: string;
  sideItems?: string[];
};

export function RoutePage({ config }: { config: RoutePageConfig }) {
  return (
    <main className="route-page">
      <section className="route-hero">
        <div><span className="section-mark">{config.eyebrow}</span><h1>{config.title}</h1></div>
        <p className="route-hero-copy">{config.description}</p>
      </section>
      <section className="route-panel">
        <div className="route-panel-main">
          <span className="section-mark">KalaSetu workspace</span>
          <h2>{config.primaryLabel ?? "A calmer path is taking shape."}</h2>
          <p>{config.description}</p>
          {config.steps ? <div className="route-steps" aria-label="Page steps">{config.steps.map((step) => <span className="route-step" key={step}>{step}</span>)}</div> : null}
          {config.primaryHref ? <div className="hero-actions"><Link className="button-primary" href={config.primaryHref}>Continue <span aria-hidden="true">↗</span></Link></div> : null}
        </div>
        <aside className="route-side">
          <h2>{config.sideTitle ?? "Made for the next small step."}</h2>
          <p>{config.sideCopy ?? "This route is part of the KalaSetu web workspace. The connected product flow will live here."}</p>
          {config.sideItems ? <ul>{config.sideItems.map((item) => <li key={item}>{item}</li>)}</ul> : null}
        </aside>
      </section>
    </main>
  );
}
