# Catalog and Component Rules

## Catalog architecture

The public experience uses one catalog with simple filters. It is not split into separate story-led collections at the top level.

Recommended filter dimensions, rendered only when data exists:

- Category
- Material
- Region
- Verification status
- Price or enquiry state

Filters must use plain labels, show active selections clearly, and provide an obvious reset action. Do not hide essential product information inside filters.

## Product card hierarchy

Every product card should communicate, in this order:

1. Product image
2. Product name
3. Artisan or maker
4. Craft or material
5. Region
6. Verification status
7. Price or enquiry state, when available
8. `View full details`

Cards must remain useful when optional values are missing. Do not show empty labels, placeholder dashes, or broken metadata rows.

## Product details page

The detail page should provide:

- Large product image and alternate media when available.
- Product name and clear maker attribution.
- Material, technique, region, dimensions, care, and availability when present.
- Verification mark with a plain-language explanation.
- Authenticity or provenance details in a dedicated readable section.
- Product description or artisan-provided story when available.
- A clear `View full details` destination from the catalog must never become a confusing purchase funnel.

The public web scope does not add cart, checkout, payment, or marketplace transaction flows.

## Verification presentation

Verification should look like a calm record of evidence, not a promotional sticker. Use a consistent mark, status text, and expandable detail area. Never imply verification when the record is pending, incomplete, or unavailable.

## Shared controls

- Use text labels with icons where an icon improves recognition.
- Minimum interactive target: 44×44px; prefer 48×48px for primary actions.
- Focus, hover, pressed, loading, disabled, empty, and error states must be designed together.
- Avoid controls whose meaning changes only through color.
- Avoid a new visual treatment for every route; reuse the same component grammar.

