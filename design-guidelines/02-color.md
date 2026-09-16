# Web Color System

The following four colors are the confirmed web palette. They are the only expressive colors permitted in the primary design system.

| Token | Hex | Role |
| --- | --- | --- |
| Cream | `#FFEED6` | Main light surface, page warmth, quiet background |
| Sage | `#A5AF79` | Supporting surface, selection, calm status, craft accent |
| Brown | `#827148` | Material accent, borders, secondary emphasis, earthy action |
| Peach | `#E8A07C` | Focused accent, active emphasis, warmth, positive energy |

## Usage rules

- Cream is the default light canvas; do not replace it with cold white across the whole experience.
- Sage, Brown, and Peach are accents. They must not be used as large competing panels on the same screen.
- Product photos retain their natural colors and are never colorized to match the palette.
- Verification must not depend on color alone; pair color with text, iconography, or a mark.
- Text must be tested for contrast before implementation. If the palette does not meet readable contrast for text, use a single deep olive/green derived from the palette as an accessibility ink color only.
- That derived ink is not a fifth accent, brand color, gradient stop, or decorative color.
- Do not use orange, orange-adjacent substitutions, or an unapproved color scale.

## Contrast and states

- Normal text targets at least 4.5:1 contrast.
- Large text targets at least 3:1 contrast.
- Focus indicators must be visible against both Cream and product-image surfaces.
- Disabled states must remain distinguishable without reducing text to illegibility.
- Error, warning, and success states require a text label and icon; do not introduce red or green by default without design review.

