# 09 — Image pipeline

Goal: e-commerce photo that **does not lie about colour**. Output must look finished, not a ragged mask.

## Policy

- Original is never deleted.
- Studio is compositor output, not a generated image.
- Six bundled backgrounds only (white, linen, beige, slate, jute, wood). Ship in `apps/mobile/assets/bg/` and `apps/web/public/bg/`.
- No diffusion, inpaint, upscalers that invent texture, or internet background search.

## Quality path (required for “done”)

Server FastAPI:

1. Decode JPEG, long edge 1600px.
2. **Salient cut-out with a high-quality model** (ISNet-general or BiRefNet weights on the server). Not YOLO-as-final if the mask is jagged.
3. Feather alpha 2–4px. Light contact shadow (blurred alpha, 15–20% opacity).
4. Composite onto chosen preset (default: warm linen for textiles, slate for metal — from `fields.craft` if known, else linen).
5. Convert subject pixels to Lab. Adjust **L only** (exposure + grey-world WB from subject). Do not touch a,b.
6. Compute mean ΔE on subject using a,b only.
7. If `deltaE > 2.0`: **reject studio**, return original + reason.
8. Upload both to Storage. Write URLs + `deltaE` + provenance `source: kalasetu-studio.v1`.

YOLOv8n-seg on device is **preview only**. The image the artisan publishes is the **server** result unless server is down.

## Client

- Capture with frame guide. Reject obviously dark/blurry with a spoken hint if you can measure it cheaply (luma / Laplacian), else skip.
- Show original | studio. User picks. Default studio if gate passed.
- `POST /v1/images/enhance` multipart `file` + `bg_preset` + `listing_id`.

## Working if

- Side-by-side shows a clean edge on a real textile photo (not a thin halo, not missing pallu).
- dE printed. A red saree is still red.
- Original still openable.
- Failed gate does not publish a mutilated image.

## Not done if

- Green fringe, chewed edges, grey product, or “AI beauty” saturation.
