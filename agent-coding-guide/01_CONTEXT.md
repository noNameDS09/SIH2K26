# 01 — Context (aim, PS, personas, goals)

## Aim

KalaSetu lets an artisan with low literacy turn a phone photo + regional-language speech into a bilingual, priced, shareable product listing, then **push that listing onto a web show catalog** (and later onto gov/open networks).

We are a **friction-remover**, not a shop on the phone. Web `/market` exists **only so judges can see the listing land**.

## Problem statement (SIH26090)

MoSJE: marginalized artisans/weavers get fair-time sales but not year-round digital access. They cannot shoot, write English/Hindi catalogs, or price for e-commerce.

Required capabilities (must exist in the build):

1. **AI Image Enhancer & Studio** — clean background, honest colour, e-commerce crop.
2. **Multilingual auto-cataloger** — voice in regional language → professional EN + HI listing.
3. **Dynamic pricing assistant** — image + description + artisan cost answers → competitive suggested price.

Theme: Smart Automation.

## Who it is for

| Persona | Need | How we treat them |
|---|---|---|
| **Artisan** (primary). Often primary-school literacy or none. Speaks a regional language. Cheap Android. | List a product without typing a catalog. Hear confirmation. Own the price. | Voice after OTP. Huge primary button. Confirm by ear. Override price. App has no shop. |
| **Family helper** (OTP only). | Type the phone number once. | Keypad on OTP. Then they can leave. |
| **Buyer / judge with a second phone** | Scan QR or open `/market` and see the same listing. | Public card + show catalog. No checkout. |
| **Cluster officer** (demo extra) | See that identity is Pehchan-shaped. | Seeded registry fields. Not a live gov write. |

## Goals (build)

| Goal | Done when |
|---|---|
| List in first session in own language | Photo + Live Q&A + price + publish < few minutes |
| Listing is trade-shaped | Hindi+English, attributes, three prices, provenance |
| Honest photo | Studio image exists **and** colour-delta gate passed, or original shown |
| Demo linkage | Publish on app → visible on web `/market` |
| Trust | AI values tagged; mocks labelled; QR opens public card |

## Non-goals (this build)

- Real Aadhaar KUA
- Real GeM/ONDC/IH write APIs
- Cart, UPI collection, escrow
- ChatGPT-style advisor
- Postgres
- Training a foundation model

## Numbers you may cite (already sourced in research)

Use only if a UI or README needs a fact: ~1.13 crore craft workers; ~₹7,000/month typical; 71% of handloom weavers women; <10% on e-commerce. Do not invent impact percentages.

## Novelty you must not drop

Every AI prediction is provenance-tagged. Voice-first after OTP. Signed listing / QR. That triad stays. Do not replace it with “we built a marketplace.”
