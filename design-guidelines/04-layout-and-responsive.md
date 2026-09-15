# Layout and Responsive Behavior

The website is mobile-first, with desktop treated as a full-quality experience rather than a stretched mobile layout.

## Target widths

- Baseline mobile: 390px viewport.
- Compact mobile: approximately 320px must remain usable.
- Tablet: fluid transition around 768px.
- Desktop: full layout from approximately 1024px upward.
- Review desktop composition at 1280px and 1440px.

## Structural rules

- Use a consistent spacing rhythm and generous breathing room around headings.
- Keep content columns readable; do not create excessively wide text lines.
- Use CSS logical properties so layout remains language-safe.
- Prefer fluid grids and intrinsic sizing over fixed-width assumptions.
- Never let a filter row, product name, verification mark, or language label overflow.
- Keep primary actions within thumb reach on mobile.
- Use large product media and a calm metadata block beneath it.
- Do not make every section a floating rounded container; use open composition, rules, whitespace, and occasional framed panels.

## Header and footer

The header should remain low-density and recognizable:

- KalaSetu logo placeholder until the approved logo asset is added.
- Catalog navigation.
- Language selector.
- Clear route to artisan access where appropriate.
- No public voice control.

On mobile, collapse navigation into a simple menu while keeping language selection and the primary catalog route easy to reach.

The footer should provide language, support, verification explanation, legal links, and route navigation without becoming a second catalog.

## Mobile behavior

- Product cards become a single-column flow or a deliberate two-column grid only when text remains readable.
- Filters open in a clear sheet or page-level panel, with selected filters visible and removable.
- Product detail media appears before long descriptions.
- Avoid hover-dependent information; every hover affordance needs a tap and keyboard equivalent.

