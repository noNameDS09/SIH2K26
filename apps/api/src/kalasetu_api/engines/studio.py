"""
KalaSetu image studio — FastAPI quality path.

Same compositor for POST /v1/images/enhance and the optional CLI.
Not a generative background. Locked in agent-coding-guide/09_IMAGE_PIPELINE.md.

CLI (debug only — production clients call the API):

    PYTHONPATH=src .venv/bin/python -m kalasetu_api.engines.studio photo.jpg --preset linen
"""

from __future__ import annotations

import argparse
import io
import json
from dataclasses import dataclass
from datetime import datetime, timezone
from functools import lru_cache
from pathlib import Path
from typing import Any

import numpy as np
from PIL import Image, ImageFilter

# Locked preset names. Do not add a seventh, do not download stock photos.
PRESET_NAMES = ("white", "linen", "beige", "slate", "jute", "wood")

# Mean ΔE on a,b only. Above this we refuse to lie about colour.
DELTA_E_LIMIT = 2.0

# Long edge after decode. Matches 09.
LONG_EDGE = 1600

# Contact shadow: blurred alpha, 15–20% opacity, slight downward offset.
SHADOW_OPACITY = 0.18
SHADOW_BLUR_PX = 16
SHADOW_OFFSET_Y = 10

FEATHER_PX = 3

_REPO_ROOT = Path(__file__).resolve().parents[5]
_API_BG_DIR = Path(__file__).resolve().parents[3] / "assets" / "bg"
_WEB_BG_DIR = _REPO_ROOT / "apps" / "web" / "public" / "bg"


# ---------------------------------------------------------------------------
# Bundled backdrops (created once as PNGs — not generated per photo)
# ---------------------------------------------------------------------------

def _noise(h: int, w: int, scale: float, rng: np.random.Generator) -> np.ndarray:
    return rng.normal(0.0, scale, size=(h, w, 1)).astype(np.float32)


def make_preset_array(name: str, size: int = 1600) -> np.ndarray:
    """RGB uint8 backdrop. Simple textile/surface colour, not a fake room."""
    seeds = {
        "white": 11,
        "linen": 22,
        "beige": 33,
        "slate": 44,
        "jute": 55,
        "wood": 66,
    }
    rng = np.random.default_rng(seeds[name])
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    xx /= size
    yy /= size
    n = _noise(size, size, 4.0, rng)

    if name == "white":
        base = np.array([248, 247, 244], dtype=np.float32)
        rgb = base + n
    elif name == "linen":
        # Warm cloth. Default for textiles.
        weave = 6.0 * np.sin(xx * 180.0) + 4.0 * np.sin(yy * 220.0)
        base = np.array([232, 218, 196], dtype=np.float32)
        rgb = base + n + weave[..., None]
    elif name == "beige":
        base = np.array([224, 206, 178], dtype=np.float32)
        rgb = base + n
    elif name == "slate":
        # Cool grey. Default-ish for metal.
        grain = 8.0 * np.sin(xx * 40.0 + yy * 12.0)
        base = np.array([92, 98, 108], dtype=np.float32)
        rgb = base + n + grain[..., None]
    elif name == "jute":
        fibre = 10.0 * np.sin(yy * 260.0) + 5.0 * np.sin(xx * 80.0)
        base = np.array([186, 154, 108], dtype=np.float32)
        rgb = base + n + fibre[..., None]
    elif name == "wood":
        rings = 16.0 * np.sin(xx * 55.0 + 0.4 * np.sin(yy * 8.0))
        base = np.array([138, 98, 68], dtype=np.float32)
        rgb = base + n + rings[..., None]
    else:
        raise ValueError(f"Unknown preset {name}")

    return np.clip(rgb, 0, 255).astype(np.uint8)


class StudioUnavailable(RuntimeError):
    """ISNet weights / rembg are not installed on this API process."""


@dataclass
class StudioResult:
    original_jpeg: bytes
    studio_jpeg: bytes
    accepted: bool
    delta_e: float
    bg_preset: str
    bg_reason: str
    reject_reason: str | None
    provenance: dict[str, Any]


def studio_deps_ok() -> bool:
    try:
        import onnxruntime  # noqa: F401
        import rembg  # noqa: F401
    except Exception:
        return False
    return True


def ensure_preset_files() -> Path:
    """Write the six JPEGs if missing. Safe to call on every run."""
    _API_BG_DIR.mkdir(parents=True, exist_ok=True)
    for name in PRESET_NAMES:
        api_path = _API_BG_DIR / f"{name}.jpg"
        if not api_path.exists():
            Image.fromarray(make_preset_array(name), mode="RGB").save(
                api_path, format="JPEG", quality=88
            )
        try:
            _WEB_BG_DIR.mkdir(parents=True, exist_ok=True)
            web_path = _WEB_BG_DIR / f"{name}.jpg"
            if not web_path.exists():
                Image.open(api_path).save(web_path, format="JPEG", quality=88)
        except OSError:
            pass
    return _API_BG_DIR


def load_preset(name: str, size: tuple[int, int]) -> Image.Image:
    ensure_preset_files()
    img = Image.open(_API_BG_DIR / f"{name}.jpg").convert("RGB")
    if img.size != size:
        img = img.resize(size, Image.Resampling.LANCZOS)
    return img


# ---------------------------------------------------------------------------
# Colour: Lab, L-only light, ΔE on a,b only
# ---------------------------------------------------------------------------

def _srgb_to_linear(c: np.ndarray) -> np.ndarray:
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def _linear_to_srgb(c: np.ndarray) -> np.ndarray:
    return np.where(c <= 0.0031308, 12.92 * c, 1.055 * np.power(np.clip(c, 0, None), 1 / 2.4) - 0.055)


def rgb_uint8_to_lab(rgb: np.ndarray) -> np.ndarray:
    """rgb (H,W,3) uint8 → Lab float. D65. Used for the colour gate."""
    srgb = np.clip(rgb.astype(np.float64) / 255.0, 0.0, 1.0)
    lin = _srgb_to_linear(srgb)
    m = np.array(
        [
            [0.4124564, 0.3575761, 0.1804375],
            [0.2126729, 0.7151522, 0.0721750],
            [0.0193339, 0.1191920, 0.9503041],
        ]
    )
    xyz = lin @ m.T
    xyz /= np.array([0.95047, 1.0, 1.08883])
    eps = 216 / 24389
    kappa = 24389 / 27
    f = np.where(xyz > eps, np.cbrt(xyz), (kappa * xyz + 16.0) / 116.0)
    L = 116.0 * f[..., 1] - 16.0
    a = 500.0 * (f[..., 0] - f[..., 1])
    b = 200.0 * (f[..., 1] - f[..., 2])
    return np.stack([L, a, b], axis=-1)


def lab_to_rgb_uint8(lab: np.ndarray) -> np.ndarray:
    L, a, b = lab[..., 0], lab[..., 1], lab[..., 2]
    fy = (L + 16.0) / 116.0
    fx = a / 500.0 + fy
    fz = fy - b / 200.0
    eps = 216 / 24389
    kappa = 24389 / 27
    xr = np.where(fx**3 > eps, fx**3, (116.0 * fx - 16.0) / kappa)
    yr = np.where(L > kappa * eps, fy**3, L / kappa)
    zr = np.where(fz**3 > eps, fz**3, (116.0 * fz - 16.0) / kappa)
    xyz = np.stack([xr * 0.95047, yr, zr * 1.08883], axis=-1)
    m_inv = np.array(
        [
            [3.2404542, -1.5371385, -0.4985314],
            [-0.9692660, 1.8760108, 0.0415560],
            [0.0556434, -0.2040259, 1.0572252],
        ]
    )
    lin = xyz @ m_inv.T
    srgb = np.clip(_linear_to_srgb(lin), 0.0, 1.0)
    return (srgb * 255.0 + 0.5).astype(np.uint8)


def adjust_light_only(rgb: np.ndarray, alpha: np.ndarray) -> np.ndarray:
    """
    Exposure / grey-world on L only. a and b (hue/chroma) stay put.
    Grey-world here means: pull mean L of the subject toward a mid value so
    a dark indoor shot is readable, without making a red saree pink/grey.
    """
    lab = rgb_uint8_to_lab(rgb)
    mask = alpha > 0.5
    if not np.any(mask):
        return rgb
    mean_l = float(lab[..., 0][mask].mean())
    # Modest lift toward ~58; never a dramatic “beauty” curve.
    target = 58.0
    gain = target / max(mean_l, 1.0)
    gain = float(np.clip(gain, 0.85, 1.25))
    lab_out = lab.copy()
    lab_out[..., 0] = np.clip(lab[..., 0] * gain, 0.0, 100.0)
    # Keep a,b identical (the next line is the lock).
    lab_out[..., 1] = lab[..., 1]
    lab_out[..., 2] = lab[..., 2]
    out = lab_to_rgb_uint8(lab_out)
    # Only replace subject pixels; leave transparent holes alone.
    alpha3 = alpha[..., None]
    return np.clip(out * alpha3 + rgb * (1.0 - alpha3), 0, 255).astype(np.uint8)


def mean_delta_e_ab(before_rgb: np.ndarray, after_rgb: np.ndarray, alpha: np.ndarray) -> float:
    """Mean Euclidean distance in Lab a,b on subject pixels. 09 uses a,b only."""
    # High alpha only — ignore the feathered halo where backdrop mixes in.
    mask = alpha > 0.9
    if mask.sum() < 50:
        return 0.0
    b = rgb_uint8_to_lab(before_rgb)[mask]
    a = rgb_uint8_to_lab(after_rgb)[mask]
    d = np.sqrt((b[:, 1] - a[:, 1]) ** 2 + (b[:, 2] - a[:, 2]) ** 2)
    return float(d.mean())


# ---------------------------------------------------------------------------
# Backdrop choice from the SUBJECT's colours (still one of the six presets)
# ---------------------------------------------------------------------------

def pick_preset_for_subject(rgb: np.ndarray, alpha: np.ndarray) -> tuple[str, str]:
    """
    Suit the backdrop to the product, not the old room.

    Warm red/gold textile  → linen (warm cloth, does not fight zari)
    Yellow / straw / cane  → beige or jute
    Dark product           → linen or white (so it does not sink)
    Pale / white product   → wood or slate (so it does not vanish)
    Low-chroma metal-like  → slate
    """
    mask = alpha > 0.6
    if mask.sum() < 50:
        return "linen", "fallback: not enough subject pixels"
    lab = rgb_uint8_to_lab(rgb)[mask]
    L = float(lab[:, 0].mean())
    a = float(lab[:, 1].mean())
    b = float(lab[:, 2].mean())
    chroma = (a * a + b * b) ** 0.5

    if chroma < 12 and 28 < L < 78:
        return "slate", f"muted/metal-like (chroma={chroma:.1f}, L={L:.0f})"
    if L < 30:
        return "linen", f"dark subject (L={L:.0f}) on warm light cloth"
    if L > 80:
        return "wood", f"pale subject (L={L:.0f}) on darker warm ground"
    if a > 12 and b > 8:
        return "linen", f"warm textile (a={a:.0f}, b={b:.0f})"
    if b > 22 and a < 8:
        return "jute", f"yellow/earth (b={b:.0f})"
    if a < -6:
        return "beige", f"cool/green craft (a={a:.0f}) on warm beige"
    return "linen", f"default textile (L={L:.0f}, chroma={chroma:.1f})"


# ---------------------------------------------------------------------------
# Cut-out + composite
# ---------------------------------------------------------------------------

def resize_long_edge(img: Image.Image, long_edge: int = LONG_EDGE) -> Image.Image:
    img = img.convert("RGB")
    w, h = img.size
    longest = max(w, h)
    if longest <= long_edge:
        return img
    scale = long_edge / longest
    return img.resize((max(1, int(w * scale)), max(1, int(h * scale))), Image.Resampling.LANCZOS)


@lru_cache(maxsize=1)
def _rembg_session():
    try:
        from rembg import new_session
    except Exception as exc:
        raise StudioUnavailable(
            "Studio needs rembg + onnxruntime on the API process"
        ) from exc
    return new_session("isnet-general-use")


def cutout_isnet(img: Image.Image) -> Image.Image:
    """ISNet-general via rembg. Quality mask — do not swap in YOLO here."""
    try:
        from rembg import remove

        cut = remove(img, session=_rembg_session())
    except StudioUnavailable:
        raise
    except Exception as exc:
        raise StudioUnavailable(f"Studio cut-out failed: {exc}") from exc
    if not isinstance(cut, Image.Image):
        cut = Image.open(cut)  # type: ignore[arg-type]
    return cut.convert("RGBA")


def resolve_preset(
    preset: str | None,
    craft: str,
    rgb: np.ndarray,
    alpha: np.ndarray,
) -> tuple[str, str]:
    if preset in PRESET_NAMES:
        return preset, "requested by client"
    craft_l = (craft or "").strip().lower()
    if any(
        word in craft_l
        for word in ("metal", "brass", "bronze", "copper", "bell", "diya")
    ):
        return "slate", f"craft={craft_l} → metal backdrop"
    if craft_l:
        return "linen", f"craft={craft_l} → textile backdrop"
    return pick_preset_for_subject(rgb, alpha)


def jpeg_bytes(img: Image.Image) -> bytes:
    buf = io.BytesIO()
    img.convert("RGB").save(buf, format="JPEG", quality=92)
    return buf.getvalue()


def provenance(accepted: bool) -> dict[str, Any]:
    return {
        "source": "kalasetu-studio.v1",
        "version": "1",
        "confidence": 0.9 if accepted else 0.2,
        "ts": datetime.now(timezone.utc).isoformat(),
    }


def run_studio(
    original: Image.Image,
    *,
    preset: str | None = None,
    craft: str = "",
) -> StudioResult:
    original = resize_long_edge(original.convert("RGB"))
    orig_rgb = np.array(original, dtype=np.uint8)

    rgba = cutout_isnet(original)
    rgba = feather_alpha(rgba)
    alpha = np.array(rgba.split()[-1], dtype=np.float32) / 255.0
    cut_rgb = np.array(rgba.convert("RGB"), dtype=np.uint8)

    lit_rgb = adjust_light_only(cut_rgb, alpha)
    lit_rgba = Image.fromarray(lit_rgb, mode="RGB").convert("RGBA")
    lit_rgba.putalpha(rgba.split()[-1])

    chosen, reason = resolve_preset(preset, craft, lit_rgb, alpha)
    studio = composite_on_preset(lit_rgba, chosen)
    studio_np = np.array(studio, dtype=np.uint8)

    delta_e = mean_delta_e_ab(orig_rgb, studio_np, alpha)
    accepted = delta_e <= DELTA_E_LIMIT
    if not accepted:
        studio = original.copy()

    reject = (
        None
        if accepted
        else f"deltaE {delta_e:.2f} > {DELTA_E_LIMIT}: colour shifted; original returned"
    )
    return StudioResult(
        original_jpeg=jpeg_bytes(original),
        studio_jpeg=jpeg_bytes(studio),
        accepted=accepted,
        delta_e=round(delta_e, 3),
        bg_preset=chosen,
        bg_reason=reason,
        reject_reason=reject,
        provenance=provenance(accepted),
    )


def enhance_bytes(
    data: bytes,
    *,
    preset: str | None = None,
    craft: str = "",
) -> StudioResult:
    if not data:
        raise ValueError("Empty image")
    try:
        image = Image.open(io.BytesIO(data))
        image.load()
    except Exception as exc:
        raise ValueError("Not a readable JPEG/PNG") from exc
    return run_studio(image, preset=preset, craft=craft)


def feather_alpha(rgba: Image.Image, radius: int = FEATHER_PX) -> Image.Image:
    r, g, b, a = rgba.split()
    a = a.filter(ImageFilter.GaussianBlur(radius=radius))
    return Image.merge("RGBA", (r, g, b, a))


def composite_on_preset(rgba: Image.Image, preset: str) -> Image.Image:
    """Subject over preset + light contact shadow. Opaque RGB result."""
    w, h = rgba.size
    bg = load_preset(preset, (w, h)).convert("RGBA")
    _r, _g, _b, a = rgba.split()
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    # Offset alpha down, blur, 18% black.
    shifted = Image.new("L", (w, h), 0)
    shifted.paste(a, (0, SHADOW_OFFSET_Y))
    shifted = shifted.filter(ImageFilter.GaussianBlur(radius=SHADOW_BLUR_PX))
    shadow_a = shifted.point(lambda p: int(p * SHADOW_OPACITY))
    shadow = Image.merge("RGBA", (Image.new("L", (w, h), 0),) * 3 + (shadow_a,))
    canvas = Image.alpha_composite(bg, shadow)
    canvas = Image.alpha_composite(canvas, rgba)
    return canvas.convert("RGB")


def enhance_image(
    source: Path,
    *,
    preset: str | None = None,
    out_dir: Path | None = None,
    craft: str = "",
) -> dict:
    """CLI helper: same studio path, writes original/studio/json next to the photo."""
    source = source.expanduser().resolve()
    if not source.is_file():
        raise FileNotFoundError(source)
    result = enhance_bytes(source.read_bytes(), preset=preset, craft=craft)
    dest = out_dir.expanduser().resolve() if out_dir else source.parent
    dest.mkdir(parents=True, exist_ok=True)
    stem = source.stem
    original_path = dest / f"{stem}.original.jpg"
    studio_path = dest / f"{stem}.studio.jpg"
    json_path = dest / f"{stem}.studio.json"
    original_path.write_bytes(result.original_jpeg)
    studio_path.write_bytes(result.studio_jpeg)
    payload = {
        "input": str(source),
        "original": str(original_path),
        "studio": str(studio_path),
        "accepted": result.accepted,
        "deltaE": result.delta_e,
        "deltaE_limit": DELTA_E_LIMIT,
        "bg_preset": result.bg_preset,
        "bg_reason": result.bg_reason,
        "reject_reason": result.reject_reason,
        "provenance": result.provenance,
    }
    json_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    payload["json"] = str(json_path)
    return payload


def main() -> None:
    parser = argparse.ArgumentParser(
        description="KalaSetu studio test: photo in → original + studio + json out"
    )
    parser.add_argument("image", type=Path, help="JPEG/PNG of a real product")
    parser.add_argument(
        "--preset",
        choices=PRESET_NAMES,
        default=None,
        help="skip auto colour pick and force a bundled backdrop",
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=None,
        help="output directory (default: same folder as the photo)",
    )
    args = parser.parse_args()
    ensure_preset_files()
    result = enhance_image(args.image, preset=args.preset, out_dir=args.out)
    print(json.dumps(result, indent=2))
    if not result["accepted"]:
        raise SystemExit(2)


if __name__ == "__main__":
    main()
