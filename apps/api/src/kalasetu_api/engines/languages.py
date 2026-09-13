"""Sarvam BCP-47 codes shown in the language picker (app, web, Streamlit)."""

from __future__ import annotations

SARVAM_LANGUAGES: tuple[tuple[str, str], ...] = (
    ("mr-IN", "मराठी / Marathi"),
    ("hi-IN", "हिन्दी / Hindi"),
    ("en-IN", "English (India)"),
    ("bn-IN", "বাংলা / Bengali"),
    ("ta-IN", "தமிழ் / Tamil"),
    ("te-IN", "తెలుగు / Telugu"),
    ("ml-IN", "മലയാളം / Malayalam"),
    ("kn-IN", "ಕನ್ನಡ / Kannada"),
    ("gu-IN", "ગુજરાતી / Gujarati"),
    ("pa-IN", "ਪੰਜਾਬੀ / Punjabi"),
    ("od-IN", "ଓଡ଼ିଆ / Odia"),
    ("as-IN", "অসমীয়া / Assamese"),
    ("ur-IN", "اردو / Urdu"),
    ("sa-IN", "संस्कृत / Sanskrit"),
    ("ne-IN", "नेपाली / Nepali"),
    ("kok-IN", "कोंकणी / Konkani"),
    ("mai-IN", "मैथिली / Maithili"),
    ("sd-IN", "سنڌي / Sindhi"),
    ("doi-IN", "डोगरी / Dogri"),
    ("sat-IN", "ᱥᱟᱱᱛᱟᱲᱤ / Santali"),
    ("mni-IN", "মৈতৈলোন্ / Manipuri"),
    ("ks-IN", "کٲشُر / Kashmiri"),
    ("brx-IN", "बर' / Bodo"),
)


def language_label(code: str) -> str:
    for item, label in SARVAM_LANGUAGES:
        if item == code:
            return label
    return code
