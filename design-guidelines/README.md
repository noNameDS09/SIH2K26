# KalaSetu Web Design Guidelines

Status: locked direction, documentation only  
Scope: KalaSetu web experience  
Locked on: 2026-09-13

This folder is the web design source of truth. It describes how the web experience should look, feel, move, speak, and behave. It does not define backend behavior, database schemas, or mobile-app UI.

## Locked product direction

KalaSetu web is a premium, catalog-first public experience supported by a focused artisan workspace.

- The public web experience is one curated catalog of approximately 20–30 products.
- The primary public action is `View full details`.
- Catalog filters are part of the main experience; they should remain simple and understandable.
- Craft stories support product trust but do not lead the public experience.
- Public catalog voice controls are out of scope. Voice-first interaction belongs to the artisan workflow.
- The web must support Hindi, Marathi, English, Tamil, Bengali, and Kannada.
- Product data is database-driven and may vary. Components must tolerate missing optional fields.
- Product imagery leads every catalog surface. Decorative craft assets support it and never compete with it.

## Navigation boundary

The web must follow the repository's approved web routes and API boundary. The public surfaces are `/market` and `/v/:listingId`. Artisan workflows may use the approved web routes for onboarding, capture, studio, live, intelligence, pricing, approval, distribution, money, insights, and settings.

The browser does not call Sarvam, Gemini, or other model providers directly. Web data and voice workflows go through the FastAPI boundary described by the project guide.

## Guideline files

- [01-visual-direction.md](./01-visual-direction.md) — visual thesis, hierarchy, and anti-goals
- [02-color.md](./02-color.md) — locked web palette and contrast rules
- [03-typography.md](./03-typography.md) — multilingual type system
- [04-layout-and-responsive.md](./04-layout-and-responsive.md) — mobile-first structure and breakpoints
- [05-catalog-and-components.md](./05-catalog-and-components.md) — public catalog, product cards, details, header, footer
- [06-assets-and-imagery.md](./06-assets-and-imagery.md) — craft-inspired asset language and product-media rules
- [07-motion-gsap.md](./07-motion-gsap.md) — GSAP motion principles and limits
- [08-accessibility-i18n.md](./08-accessibility-i18n.md) — low-literacy, accessibility, and localization requirements
- [09-content-trust-and-states.md](./09-content-trust-and-states.md) — copy, verification, provenance, loading, and error states
- [10-quality-gates.md](./10-quality-gates.md) — acceptance checklist before a web surface is considered complete

## Demo content rule

Until real records are supplied, visual work may use only clearly labelled synthetic examples such as `Mock — Handwoven textile` and `Mock — Brass craft object`. Demo content must never be presented as a real artisan, region, verification result, price, or market claim.

