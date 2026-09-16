"""Voice navigation intent parser and localized confirmation synthesizer for KalaSetu."""

from __future__ import annotations

import re
import unicodedata
from typing import Any

from kalasetu_api.engines.languages import normalize_language_code

# Intent routing mappings
NAVIGATION_INTENTS: dict[str, tuple[str, ...]] = {
    "/shop": (
        "shop",
        "store",
        "catalog",
        "inventory",
        "products",
        "दुकान",
        "कैटलॉग",
        "सामान",
        "स्टॉक",
        "कॅटलॉग",
        "विक्री",
        "கடை",
        "பட்டியல்",
        "షాప్",
        "దుకాణం",
        "দোকান",
        "পণ্য",
    ),
    "/capture": (
        "capture",
        "camera",
        "photo",
        "new product",
        "add product",
        "take photo",
        "add",
        "नया सामान",
        "नया उत्पाद",
        "फोटो",
        "कैमरा",
        "सामान जोड़ो",
        "नवीन",
        "नवीन वस्तू",
        "புதிய",
        "புகைப்படம்",
        "కెమెరా",
        "కొత్త",
        "ছবি",
        "নতুন",
    ),
    "/money": (
        "money",
        "sales",
        "earnings",
        "revenue",
        "rupees",
        "record",
        "पैसे",
        "कमाई",
        "बिक्री",
        "रुपये",
        "खाता",
        "हिशोब",
        "पैसे दाखवा",
        "பணம்",
        "வருமானம்",
        "డబ్బులు",
        "ఆదాయం",
        "টাকা",
        "উপার্জন",
    ),
    "/insights": (
        "insights",
        "advice",
        "advisor",
        "trends",
        "suggestions",
        "सलाह",
        "सुझाव",
        "सलाहकार",
        "ट्रेंड",
        "सल्ला",
        "सल्लागार",
        "ஆலோசனை",
        "సలహా",
        "পরামর্শ",
    ),
    "/studio": (
        "studio",
        "image studio",
        "background",
        "enhance",
        "स्टूडियो",
        "पृष्ठभूमि",
    ),
    "/pricing": (
        "pricing",
        "price",
        "cost",
        "value",
        "दाम",
        "कीमत",
    ),
    "/approval": (
        "approval",
        "approve",
        "sign",
        "publish",
        "मंजूरी",
        "हस्ताक्षर",
    ),
    "/distribute": (
        "distribute",
        "share",
        "qr",
        "export",
        "वितरण",
        "साझा",
    ),
    "/live": (
        "live",
        "catalog",
        "describe",
        "विवरण",
        "बोलकर",
    ),
    "/settings": (
        "settings",
        "language",
        "change language",
        "preference",
        "सेटिंग",
        "सेटिंग्स",
        "भाषा",
        "भाषा बदलो",
        "भाषा बदला",
        "அமைப்புகள்",
        "மொழி",
        "సెట్టింగ్‌లు",
        "భాష",
        "সেটিংস",
    ),
    "/": (
        "home",
        "dashboard",
        "main",
        "होम",
        "घर",
        "मुख्य",
        "डैशबोर्ड",
        "मुख्य पान",
        "முகப்பு",
        "హోమ్",
        "হোম",
    ),
}

ACTION_INTENTS: dict[str, tuple[str, ...]] = {
    "back": (
        "back",
        "go back",
        "previous",
        "पीछे",
        "वापस",
        "पीछे जाओ",
        "मागे",
        "मागे चला",
        "திரும்பு",
        "వెనుకకు",
        "ফিরে",
    ),
    "read_screen": (
        "read screen",
        "read aloud",
        "speak screen",
        "speak",
        "narrate",
        "सुनो",
        "सुनाओ",
        "पढ़ो",
        "पढ़कर सुनाओ",
        "क्या लिखा है",
        "वाचा",
        "वाचून दाखवा",
        "काय लिहिले आहे",
        "படி",
        "வாசி",
        "చదువు",
        "পড়ুন",
    ),
}

QUESTION_MARKERS: tuple[str, ...] = (
    "?",
    "क्या",
    "कैसे",
    "क्यो",
    "क्यों",
    "कितना",
    "किधर",
    "बताओ",
    "समझाओ",
    "फायदा",
    "दाम",
    "कीमत",
    "प्राइस",
    "टैग",
    "काय",
    "कसे",
    "का बरं",
    "किती",
    "सांगा",
    "समजवा",
    "भाव",
    "கிடைக்கும்",
    "என்ன",
    "எப்படி",
    "ஏன்",
    "எவ்வளவு",
    "சொல்லுங்கள்",
    "వివరించు",
    "ఎలా",
    "ఎందుకు",
    "చెప్పండి",
    "কী",
    "কেন",
    "কিভাবে",
    "বলুন",
    "দাম",
    "what",
    "why",
    "how",
    "explain",
    "tell me",
    "cost",
    "price",
    "pricing",
    "calculate",
    "gem",
    "ondc",
    "tag",
)

CONFIRMATIONS: dict[str, dict[str, str]] = {
    "/shop": {
        "hi-IN": "आपकी दुकान और उत्पाद सूची खोल रहे हैं।",
        "mr-IN": "तुमची दुकान आणि उत्पादन सूची उघडत आहोत.",
        "en-IN": "Opening your shop inventory.",
        "ta-IN": "உங்கள் கடை பட்டியலை திறக்கிறோம்.",
        "te-IN": "మీ దుకాణ జాబితాను తెరుస్తున్నాము.",
        "bn-IN": "আপনার দোকান খুলছি।",
    },
    "/capture": {
        "hi-IN": "नया उत्पाद कैमरा खोल रहे हैं।",
        "mr-IN": "नवीन उत्पादन कॅमेरा उघडत आहोत.",
        "en-IN": "Opening product capture camera.",
        "ta-IN": "புதிய தயாரிப்பு கேமராவை திறக்கிறோம்.",
        "te-IN": "కొత్త ఉత్పత్తి కెమెరాను తెరుస్తున్నాము.",
        "bn-IN": "নতুন পণ্যের ক্যামেরা খুলছি।",
    },
    "/money": {
        "hi-IN": "आपकी बिक्री और कमाई का खाता खोल रहे हैं।",
        "mr-IN": "तुमच्या विक्रीचे खाते उघडत आहोत.",
        "en-IN": "Opening your sales and earnings record.",
        "ta-IN": "உங்கள் விற்பனை மற்றும் வருமான பதிவை திறக்கிறோம்.",
        "te-IN": "మీ అమ్మకాలు మరియు ఆదాయ వివరాలు తెరుస్తున్నాము.",
        "bn-IN": "আপনার বিক্রি ও উপার্জনের খাতা খুলছি।",
    },
    "/insights": {
        "hi-IN": "व्यापार सलाहकार के सुझाव खोल रहे हैं।",
        "mr-IN": "व्यापार सल्लागाराचे संदेश उघडत आहोत.",
        "en-IN": "Opening advisor insights and trends.",
        "ta-IN": "வியாபார ஆலோசகரின் வழிகாட்டுதலை திறக்கிறோம்.",
        "te-IN": "వ్యాపార సలహాదారు సూచనలు తెరుస్తున్నాము.",
        "bn-IN": "পরামর্শদাতার নির্দেশিকা খুলছি।",
    },
    "/studio": {
        "hi-IN": "स्टूडियो में छवि सुधार कर रहे हैं।",
        "mr-IN": "स्टुडिओमध्ये प्रतिमा सुधारत आहोत.",
        "en-IN": "Enhancing image in studio.",
        "ta-IN": "ஸ்டுடியோவில் படத்தை மேம்படுத்துகிறோம்.",
        "te-IN": "స్టూడియోలో చిత్రాన్ని మెరుగుపరుస్తున్నాము.",
        "bn-IN": "স্টুডিওতে ছবি উন্নত করছি।",
    },
    "/pricing": {
        "hi-IN": "दाम तय कर रहे हैं।",
        "mr-IN": "भाव ठरवत आहोत.",
        "en-IN": "Setting price bands.",
        "ta-IN": "விலை நிர்ணயிக்கிறோம்.",
        "te-IN": "ధరను నిర్ణయిస్తున్నాము.",
        "bn-IN": "দাম নির্ধারণ করছি।",
    },
    "/approval": {
        "hi-IN": "लिस्टिंग मंजूर कर रहे हैं।",
        "mr-IN": "लिस्टिंग मंजूर करत आहोत.",
        "en-IN": "Approving and signing listing.",
        "ta-IN": "பட்டியலை அங்கீகரிக்கிறோம்.",
        "te-IN": "జాబితాను ఆమోదిస్తున్నాము.",
        "bn-IN": "তালিকাটি অনুমোদন করছি।",
    },
    "/distribute": {
        "hi-IN": "वितरण और QR तैयार कर रहे हैं।",
        "mr-IN": "वितरण आणि QR तयार करत आहोत.",
        "en-IN": "Preparing distribution and QR.",
        "ta-IN": "விநியோகம் மற்றும் QR தயாரிக்கிறோம்.",
        "te-IN": "వితరణ మరియు QR సిద్ధం చేస్తున్నాము.",
        "bn-IN": "বিতরণ এবং QR প্রস্তুত করছি।",
    },
    "/live": {
        "hi-IN": "विवरण बोलकर दर्ज कर रहे हैं।",
        "mr-IN": "विवरण बोलून नोंदवत आहोत.",
        "en-IN": "Cataloging by voice.",
        "ta-IN": "விவரங்களை பேசி பதிவு செய்கிறோம்.",
        "te-IN": "వివరాలను మాట్లాడి నమోదు చేస్తున్నాము.",
        "bn-IN": "বর্ণনা বলে নিবন্ধন করছি।",
    },
    "/settings": {
        "hi-IN": "सेटिंग्स और भाषा विकल्प खोल रहे हैं।",
        "mr-IN": "सेटिंग्ज आणि भाषा पर्याय उघडत आहोत.",
        "en-IN": "Opening settings and preferences.",
        "ta-IN": "அமைப்புகள் மற்றும் மொழி விருப்பங்களை திறக்கிறோம்.",
        "te-IN": "సెట్టింగ్‌లు మరియు భాషా ఎంపికలను తెరుస్తున్నాము.",
        "bn-IN": "সেটিংস এবং ভাষা বিকল্প খুলছি।",
    },
    "/": {
        "hi-IN": "मुख्य डैशबोर्ड पर जा रहे हैं।",
        "mr-IN": "मुख्य डॅशबोर्डवर जात आहोत.",
        "en-IN": "Going to home dashboard.",
        "ta-IN": "முகப்பு பக்கத்திற்கு செல்கிறோம்.",
        "te-IN": "హోమ్ పేజీకి వెళ్తున్నాము.",
        "bn-IN": "প্রধান পেজে যাচ্ছি।",
    },
    "back": {
        "hi-IN": "पिछले पेज पर जा रहे हैं।",
        "mr-IN": "मागील पानावर जात आहोत.",
        "en-IN": "Going back.",
        "ta-IN": "முந்தைய பக்கத்திற்கு செல்கிறோம்.",
        "te-IN": "వెనుక పేజీకి వెళ్తున్నాము.",
        "bn-IN": "আগের পেজে যাচ্ছি।",
    },
    "read_screen": {
        "hi-IN": "स्क्रीन पढ़कर सुना रहे हैं।",
        "mr-IN": "स्क्रीन वाचून दाखवत आहोत.",
        "en-IN": "Reading the screen aloud.",
        "ta-IN": "திரையை வாசித்து காட்டுகிறோம்.",
        "te-IN": "స్క్రీన్ చదివి వినిపిస్తున్నాము.",
        "bn-IN": "স্ক্রিন পড়ে শোনাচ্ছি।",
    },
}


def get_spoken_confirmation(key: str, language_code: str = "hi-IN") -> str:
    norm = normalize_language_code(language_code)
    mapping = CONFIRMATIONS.get(key, {})
    if norm in mapping:
        return mapping[norm]
    # Fallback to Hindi or English
    return mapping.get("hi-IN") or mapping.get("en-IN") or f"Navigating to {key}."


def parse_voice_command(text: str, language_code: str = "hi-IN") -> dict[str, Any]:
    """Classifies spoken text into NAVIGATION, ACTION, or QUESTION intent."""
    clean = "".join(
        ch for ch in (text or "") if not unicodedata.category(ch).startswith("P") or ch == "?"
    ).strip().lower()
    if not clean:
        return {
            "intent": "empty",
            "action": "none",
            "target": None,
            "spoken": "",
        }

    # Check for question markers
    is_question = any(marker in clean for marker in QUESTION_MARKERS)

    # Check if a specific navigation command is present
    for target, keywords in NAVIGATION_INTENTS.items():
        for kw in keywords:
            # Word boundary or substring matching
            if kw in clean:
                # If it's a short navigation command, prioritize navigation
                if len(clean.split()) <= 4 and not clean.endswith("?"):
                    return {
                        "intent": "navigation",
                        "action": "navigate",
                        "target": target,
                        "spoken": get_spoken_confirmation(target, language_code),
                    }

    # Check actions
    for action, keywords in ACTION_INTENTS.items():
        for kw in keywords:
            if kw in clean:
                if len(clean.split()) <= 4 and not clean.endswith("?"):
                    return {
                        "intent": "action",
                        "action": action,
                        "target": None,
                        "spoken": get_spoken_confirmation(action, language_code),
                    }

    # If question markers or longer conversational query
    if is_question or len(clean.split()) > 3:
        return {
            "intent": "question",
            "action": "assistant",
            "target": None,
            "spoken": "",
        }

    # Default fallback: Treat as search or assistant query
    return {
        "intent": "question",
        "action": "assistant",
        "target": None,
        "spoken": "",
    }
