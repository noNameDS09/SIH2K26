Purpose

This README defines the current shared visual design system for the Kala Setu application.

Use this system as the visual source of truth for all screens and future UI work. New screens should reuse these colors, typography, spacing, shapes, and semantic roles instead of creating screen-specific visual styles.

This document intentionally contains only the current design system. It does not document previous palettes, previous themes, or screen-specific implementation code.

1. Design Language

Kala Setu uses a warm, handcrafted, editorial visual language inspired by:

Indian craft and heritage

Natural materials and textiles

Warm paper and earthy surfaces

Premium editorial design

Modern mobile interfaces

Calm and trustworthy information presentation

The overall feeling should be:

Warm · Natural · Elegant · Trustworthy · Craft-focused · Modern

The interface should feel tactile and human rather than like a generic enterprise dashboard.

2. Current Master Color Palette

These are the current shared color tokens.

Token

HEX / Value

Semantic Role

cream

#FFEED6

Main warm application background

creamDeep

#F3DFC2

Secondary warm surface

paper

#FFF9EF

Main card/content surface

sage

#A5AF79

Positive/natural accent

sageDark

#5F6D47

Strong positive/verification color

brown

#6F603E

Primary earthy brand accent

brownDark

#51462F

Strong earthy action/emphasis

peach

#E8A07C

Small warm highlight

oliveInk

#243628

Primary dark text/ink

line

rgba(81, 70, 47, 0.20)

Borders and dividers

shadow

rgba(57, 47, 31, 0.14)

Warm elevation/shadow

Do not introduce unrelated HEX values when building a new screen.

3. Color Usage

3.1 Cream — #FFEED6

Use for

Main screen backgrounds

Page-level backgrounds

Large breathing areas

Warm visual space around content

Cream should normally be the dominant background instead of pure white.

3.2 Cream Deep — #F3DFC2

Use for

Secondary sections

Supporting surfaces

Selected areas

Subtle background variation

Containers that need separation from the main background

Use it to create hierarchy without introducing another background color.

3.3 Paper — #FFF9EF

Use for

Main cards

Product/content containers

Forms

Important information surfaces

Modal-like content

Elevated content areas

Paper should feel like a warm sheet of paper placed over the cream background.

4. Natural / Verification Colors

4.1 Sage — #A5AF79

Use for

Positive states

Verification backgrounds

Approved states

Success-related decorative elements

Natural/craft accents

Positive indicators

Sage is an accent and should not dominate the entire interface.

4.2 Sage Dark — #5F6D47

Use for

Verified text

Approved labels

Check icons

Success icons

Positive-state emphasis

Stronger positive borders

For small text and icons, prefer Sage Dark because it provides stronger readability.

Relationship

Sage → light positive background/accent

Sage Dark → readable positive text/icon

5. Earth / Brand Colors

5.1 Brown — #6F603E

Use for

Section labels

Secondary headings

Accent icons

Supporting actions

Metadata emphasis

Decorative UI details

Brand highlights

Brown connects the interface visually with wood, natural dyes, looms, soil, and traditional craft materials.

5.2 Brown Dark — #51462F

Use for

Primary actions

Strong buttons

Important interactive elements

High-emphasis headings

Strong borders when necessary

Key brand moments

Brown Dark is the preferred strong action color while keeping the interface warm and natural.

6. Peach — #E8A07C

Peach is a secondary accent.

Use for

Small highlights

Decorative details

Selected visual accents

Supporting illustrations

Small warm emphasis

Rule

Use Peach sparingly.

Do not use it as:

The main page background

The dominant text color

The default color for every button

The color for every icon

The background of repeated large cards

7. Olive Ink — #243628

Olive Ink is the primary dark ink color.

Use for

Main headings

Important body text

Product/content names

High-priority information

Primary readable text

Strong iconography

Olive Ink provides a softer natural alternative to harsh pure black.

Avoid using pure #000000 as the dominant UI color.

8. Borders and Dividers

Line — rgba(81, 70, 47, 0.20)

Use for:

Card borders

Input borders

Dividers

Section boundaries

Subtle outlines

Borders should remain soft and understated.

Avoid heavy black outlines and multiple borders around the same component.

9. Shadows

Shadow — rgba(57, 47, 31, 0.14)

Use for:

Important cards

Elevated surfaces

Floating components

Modal/elevated UI

Shadows should remain subtle.

The visual goal is layered paper, not a heavily elevated dashboard.

10. Semantic Color Mapping

Use colors according to meaning, not only appearance.

UI Meaning

Preferred Color

Main background

Cream

Secondary background

Cream Deep

Main content surface

Paper

Primary text

Olive Ink

Strong text/action

Brown Dark

Brand accent

Brown

Positive state

Sage

Positive text/icon

Sage Dark

Warm highlight

Peach

Border/divider

Line

Elevation

Shadow

This semantic mapping should remain consistent across every screen.

11. Color Usage by UI Element

Navigation

Use:

Cream or Paper for navigation surfaces

Olive Ink for inactive icons/text

Brown or Brown Dark for active emphasis

Sage only when navigation communicates a positive/verification state

Navigation should remain understated.

Headers

Use:

Olive Ink for primary heading text

Brown or Brown Dark for selected accents

Cream or Paper around the header

Do not create a separate header palette for individual screens.

Cards

Preferred structure:

Background → Cream

Primary card → Paper

Secondary card → Cream Deep

Text → Olive Ink

Accent → Brown or Sage depending on meaning

Border → Line

Elevation → Shadow

Cards should feel like part of one unified system.

Primary Buttons

Use:

Background → Brown Dark

Text/icon → Paper or another appropriate high-contrast light color

Secondary Buttons

Use:

Background → Paper or transparent

Border → Line or Brown

Text → Brown Dark

Positive Actions

For actions representing verification, approval, completion, or success:

Background → Sage Dark or Sage

Text/icon → Paper or appropriate high-contrast color

Do not use green for ordinary actions that have no positive-state meaning.

Status / Verification

Use:

Background → Sage at low opacity

Icon/text → Sage Dark

This creates a consistent verification language.

Forms and Inputs

Use:

Input background → Paper

Input border → Line

Input text → Olive Ink

Placeholder → muted version of the text system

Focus accent → Brown

Positive validation → Sage Dark

Avoid unrelated bright blue or purple accents unless required by platform accessibility behavior.

Informational Labels

Use Brown for general branded or section labels.

Use Sage Dark when the label communicates a positive or verified state.

12. Typography System

Kala Setu uses two complementary type families.

Display / Editorial Font

Playfair Display

Use for:

Large page titles

Editorial headings

Hero-style titles

Important expressive text

Characteristics:

Serif

Elegant

Editorial

Heritage-inspired

Premium

Use it selectively. It establishes the craft/editorial identity without taking over the functional UI.

UI / Functional Font

Plus Jakarta Sans

Use for:

Section headings

Body text

Labels

Captions

Metadata

Buttons

Navigation

Form controls

Characteristics:

Clean

Modern

Highly readable

Suitable for compact mobile interfaces

Pairs well with Playfair Display

13. Typography Hierarchy

Style

Font

Size

Weight

Usage

Display

Playfair Display

25px

700

Main expressive headings

Section

Plus Jakarta Sans

14px

700

Section headings

Body

Plus Jakarta Sans

11.5px

Regular

General content

Label

Plus Jakarta Sans

9px

700

Small uppercase labels

Caption

Plus Jakarta Sans

10px

Regular

Supporting information

Button

Plus Jakarta Sans

12px

700

Button text

Typography rules

Display headings should use Playfair Display selectively.

Functional controls should use Plus Jakarta Sans.

Labels should generally be:

Uppercase

Bold

Small

Slightly letter-spaced

Examples:

VERIFIED

MATERIAL

CRAFT TIME

PRICE

14. Typography Color Pairing

Recommended combinations:

Element

Color

Main heading

Olive Ink

Section heading

Olive Ink / Brown Dark

Body text

Olive Ink or a softer neutral derived from the system

Brand label

Brown

Positive label

Sage Dark

Primary button text

Paper / appropriate light text

Secondary button text

Brown Dark

The darkest colors should be reserved for information and actions that require stronger emphasis.

15. Spacing System

Use a consistent spacing rhythm:

Spacing

Usage

4px

Micro spacing

8px

Tight spacing

12px

Component spacing

16px

Standard internal padding

20px

Section spacing

24px

Major spacing

32px

Large visual breathing room

Consistency is more important than using every value on every screen.

16. Shape and Corner Radius

Use a soft, rounded mobile visual language.

Recommended:

Radius

Usage

10px

Small controls

12px

Compact components

14px

Medium surfaces

18–20px

Major cards

Larger surfaces can use larger corner radii.

Avoid excessive rounding that makes the interface feel playful rather than premium.

17. Mobile-First Principles

The design system is intended for portrait mobile interfaces.

Every new screen should:

Prioritize vertical hierarchy

Keep important information visible and scannable

Use comfortable touch targets

Maintain consistent horizontal margins

Avoid unnecessary visual nesting

Avoid overly dense desktop-style layouts

Reuse the shared palette

Reuse the shared typography

Preserve the same visual language even when the screen structure changes

The layout can change from screen to screen; the design language should not.

18. Texture and Material Feel

Kala Setu may use subtle material-inspired visual treatments such as:

Paper

Linen

Wood

Textile

Natural/earth surfaces

Textures should support the current color system rather than compete with it.

Keep textures:

Subtle

Low contrast

Non-distracting

Consistent with the warm palette

Never place heavy textures behind dense text or important controls.

19. What Developers Should Avoid

Do not introduce screen-specific:

Random HEX colors

New primary button colors

New background colors

Unrelated green shades

Unrelated brown shades

Unrelated gradients

Bright neon colors

Pure black as the dominant UI color

Excessive shadows

Heavy borders

Unrelated typography families

Different spacing systems without a clear reason

If a genuinely new color is required, it should be added to the shared design system first and given a clear semantic purpose.

20. Shared Flutter Theme Architecture

The preferred architecture is:

ks_colors.dart
↓
Central color tokens

ks_text_styles.dart
↓
Central typography styles

app_theme.dart
↓
Global Material/component behavior

Individual screens
↓
Consume the shared theme

Individual screens should consume the shared theme rather than becoming their own visual source of truth.

21. Quick Reference

Colors

Cream        #FFEED6
Cream Deep   #F3DFC2
Paper        #FFF9EF

Sage         #A5AF79
Sage Dark    #5F6D47

Brown        #6F603E
Brown Dark   #51462F

Peach        #E8A07C
Olive Ink    #243628

Line         rgba(81, 70, 47, 0.20)
Shadow       rgba(57, 47, 31, 0.14)

Fonts

Display / Editorial → Playfair Display
UI / Functional     → Plus Jakarta Sans

Core hierarchy

Background → Cream
Cards      → Paper
Text       → Olive Ink
Actions    → Brown Dark
Brand      → Brown
Positive   → Sage / Sage Dark
Highlight  → Peach
Borders    → Line
Elevation  → Shadow