# Accessibility and Internationalization

The website must be understandable through sight, touch, keyboard, and—where applicable—artisan voice workflows. It should serve users with limited literacy without making the experience feel childish or visually flat.

## Languages

Initial supported languages:

- Hindi
- Marathi
- English
- Tamil
- Bengali
- Kannada

The language choice must persist across routes and survive reloads. Do not mix languages unexpectedly inside the same user-facing surface.

## Comprehension

- Use short, direct sentences.
- Prefer familiar words over institutional or technical language.
- Pair icons with labels.
- Explain verification in plain language.
- Keep one main decision per screen or section.
- Use visual progress and confirmation instead of relying on paragraphs.
- Provide helpful empty, loading, and error states.

## Interaction accessibility

- Keyboard navigation must cover every interactive element.
- Focus indicators must be visible and not removed.
- Touch targets must be at least 44×44px.
- Images require useful alternative text; decorative motifs use empty alt text.
- Do not use color as the sole carrier of meaning.
- Respect browser zoom and text resizing.
- Preserve readable line height across Indic scripts.
- Forms and filters require explicit labels and understandable error recovery.

## Public versus artisan capability

- Public catalog: visual browsing, text search/filtering, and product details. No voice assistant or public voice search.
- Artisan workflow: voice-first capture and guided confirmation may be used where defined by the product guide.
- Do not place artisan workflow complexity into the public catalog.

