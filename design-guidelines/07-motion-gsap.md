# Motion and GSAP

Motion should make the interface feel considered and tactile while keeping the product and task immediately available.

## Motion principles

- Motion is expressive but purposeful.
- Content must be visible and usable without waiting for an animation.
- Use one coherent motion language across the surface.
- Prefer smooth, controlled easing over bounce, elastic, or novelty effects.
- Do not use scroll-jacking.
- Do not make public catalog browsing dependent on motion.

## Approved motion patterns

- Product image hover: subtle scale or crop change, approximately 1.01–1.03×.
- Product detail transition: image and metadata move as one composed record.
- Verification reveal: a restrained thread-line draw connecting product to evidence.
- Filter update: graceful reflow or fade/translate, preserving item position where possible.
- Section entrance: short staggered reveals used once per section.
- Artisan voice control: restrained waveform or pulse that communicates listening/recording state.
- Image loading: quiet opacity or blur-to-sharp transition without layout shift.

## Timing and easing

- Micro-interactions: approximately 120–220ms.
- Control and card transitions: approximately 180–320ms.
- Page or section transitions: approximately 300–550ms.
- Use GSAP easing such as `power2.out`, `power3.out`, or `expo.out` when appropriate.
- Avoid bounce, elastic, long looping animations, and constant floating motion.

## Accessibility and performance

- Respect `prefers-reduced-motion` with an immediate or near-immediate alternative.
- Never hide critical content until an animation completes.
- Avoid large continuous canvas effects and expensive full-page parallax.
- Animate transforms and opacity where possible; avoid layout-thrashing properties.
- Cancel or reverse interrupted transitions cleanly.
- Do not animate while a user is typing, reading verification details, or confirming a voice transcript.

