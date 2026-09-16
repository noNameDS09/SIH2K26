# Web Quality Gates

A web surface is not complete until it passes these checks.

## Product and scope

- Public entry point is catalog-first.
- Primary catalog action is `View full details`.
- Catalog is one collection with understandable filters.
- No cart, checkout, payment, or public voice assistant has been added.
- No AI branding, provider terminology, chatbot treatment, or fabricated claims appears.

## Visual system

- Only the confirmed palette is used: Cream, Sage, Brown, and Peach.
- Orange is absent.
- Any derived deep olive/green is used only for accessible text or contrast.
- Product imagery is visually dominant.
- Craft motifs are subtle, consistent, and purposeful.
- Header, navigation, footer, cards, filters, and detail pages share one grammar.

## Responsive and localization

- Tested at 390px mobile and at least 1280px/1440px desktop.
- Compact mobile remains usable.
- All six languages have been checked for wrapping, clipping, line height, and control width.
- Language selection persists across routes.
- No text is baked into imagery.

## Accessibility

- Keyboard and touch navigation work.
- Focus states are visible.
- Interactive targets meet the minimum size.
- Contrast is checked.
- Meaning does not depend on color alone.
- Reduced-motion behavior is implemented.
- Loading, empty, error, unavailable, and pending states are understandable.

## Motion and performance

- GSAP motion is purposeful and bounded.
- No scroll-jacking or animation-gated content.
- Motion can be reduced or removed.
- Product images do not cause layout shift.
- The first viewport remains fast and usable on a mobile connection.

## Trust and data resilience

- Optional product fields can be absent without broken layouts.
- Verification status is never overstated.
- Provenance details are available for computed or assisted values.
- Demo records are clearly labelled.
- Public catalog content is rendered from the API boundary, not hardcoded into visual components.

