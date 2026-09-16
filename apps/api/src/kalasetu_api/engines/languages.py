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


LANGUAGE_WELCOME_GREETINGS: dict[str, str] = {
    "hi-IN": "नमस्ते! हमने आपकी भाषा पहचान ली है — हिन्दी। चलिए शुरू करते हैं।",
    "mr-IN": "नमस्ते! आम्ही तुमची भाषा ओळखली आहे — मराठी. चला सुरू करूया!",
    "bn-IN": "নমস্কার! আমরা আপনার ভাষা বুঝতে পেরেছি — বাংলা। চলুন শুরু করি!",
    "ta-IN": "வணக்கம்! உங்கள் மொழி அறியப்பட்டது — தமிழ். தொடங்குவோம்!",
    "te-IN": "నమస్కారం! మేము మీ భాషను గుర్తించాము — తెలుగు. ప్రారంభిద్దాం!",
    "gu-IN": "નમસ્તે! અમે તમારી ભાષા ઓળખી લીધી છે — ગુજરાતી. ચાલો શરૂ કરીએ!",
    "kn-IN": "ನಮಸ್ಕಾರ! ನಾವು ನಿಮ್ಮ ಭಾಷೆಯನ್ನು ಗುರುತಿಸಿದ್ದೇವೆ — ಕನ್ನಡ. ಪ್ರಾರಂಭಿಸೋಣ!",
    "ml-IN": "നമസ്കാരം! നിങ്ങളുടെ ഭാഷ തിരിച്ചറിഞ്ഞു — മലയാളം. നമുക്ക് തുടങ്ങാം!",
    "pa-IN": "ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ! ਅਸੀਂ ਤੁਹਾਡੀ ਭਾਸ਼ਾ ਪਛਾਣ ਲਈ ਹੈ — ਪੰਜਾਬੀ। ਆਓ ਸ਼ੁਰੂ ਕਰੀਏ!",
    "od-IN": "ନମସ୍କାର! ଆମେ ଆପଣଙ୍କ ଭାଷା ଚିହ୍ନି ପାରିଲୁ — ଓଡ଼ିଆ। ଆରମ୍ଭ କରିବା!",
    "as-IN": "নমস্কাৰ! আমি আপোনাৰ ভাষা চিনাক্ত কৰিলোঁ — অসমীয়া। আৰম্ভ কৰোঁ আহক!",
    "ur-IN": "آداب! ہم نے آپ کی زبان پہچان لی ہے — اردو۔ آئیے شروع کرتے ہیں۔",
    "sa-IN": "नमस्ते! वयं भवतां भाषां प्रत्यभिज्ञातवन्तः — संस्कृतम्। आरभामहे!",
    "ne-IN": "नमस्ते! हामीले तपाईंको भाषा पहिचान गर्‍यौं — नेपाली। सुरु गरौं!",
    "kok-IN": "नमस्कार! आम्ही तुमची भाषा वळखल्या — कोंकणी. सुरू करूया!",
    "mai-IN": "प्रणाम! हम अहाँक भाषा पहचानि लेलहुँ — मैथिली। चलू शुरू करी!",
    "en-IN": "Namaste! We identified your language — English. Let's get started!",
}


def normalize_language_code(code: str) -> str:
    clean = (code or "").strip().lower()
    for item, _ in SARVAM_LANGUAGES:
        if item.lower() == clean:
            return item
    prefix = clean.split("-")[0]
    for item, _ in SARVAM_LANGUAGES:
        if item.lower().startswith(prefix):
            return item
    return "hi-IN"


def get_welcome_greeting(code: str) -> str:
    norm = normalize_language_code(code)
    if norm in LANGUAGE_WELCOME_GREETINGS:
        return LANGUAGE_WELCOME_GREETINGS[norm]
    label = language_label(norm)
    return f"नमस्ते! हमने आपकी भाषा पहचान ली है — {label}। चलिए शुरू करते हैं।"

