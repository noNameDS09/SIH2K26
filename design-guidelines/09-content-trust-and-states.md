# Content, Trust, and UI States

## User-facing language

Do not expose vendor names, model names, or technical implementation language in the interface. Use clear terms such as `Source details`, `Updated`, `Verification`, `Voice transcript`, and `Provided by artisan` where appropriate.

## Provenance

Any assisted or computed value must have a way for the user to inspect its provenance. The detail view must support:

- Source
- Version
- Confidence, when applicable
- Timestamp

Use human-readable source categories such as `Artisan-provided`, `Voice input`, `Catalog record`, or `Market evidence`. Never show a value without a path to its source details.

## Claims

- Use only facts available from the listing record or approved product content.
- Synthetic content must be labelled `Mock — for SIH demo`.
- Never invent artisan names, locations, prices, verification, demand, or market outcomes.
- Do not use exaggerated promises or unsupported cultural claims.

## Required states

Every catalog and detail surface must account for:

- Loading
- Empty catalog
- No filter results
- Missing optional metadata
- Image unavailable
- Verification pending
- Verification unavailable
- Network failure
- Retry or recovery
- Long translated text
- Keyboard focus and reduced motion

States should preserve the page structure and explain the next action. Never show a blank panel with no explanation.

## Voice transcript states for artisan workflows

Where voice is used by artisans, show listening, recording, processing, transcript review, correction, confirmation, permission denial, and retry states. The transcript must remain editable or rejectable before it becomes listing data.

