"""
One-slot artisan cataloger.

Not a chatbot. Gemini Live (or the turn-based tester) asks one slot,
re-reads it, repairs only that slot on galat, then writes bilingual copy.

Price is math on seed CSVs — Gemini never picks a rupee amount.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any

from kalasetu_api.engines.pricing import compute_prices
from kalasetu_api.engines.languages import SARVAM_LANGUAGES, language_label

LANG_MR = "mr-IN"

SLOT_ORDER = (
    "craft",
    "material",
    "technique",
    "hours",
    "colour",
    "occasion",
    "gi",
    "material_cost_inr",
    "material_source",
    "effort",
    "extras",
)

SLOT_KEYS = (
    "craft", "material", "technique", "hours", "colour", "occasion", "gi",
    "material_cost_inr", "material_source", "effort", "extras",
)

# Per-language question/label/status text. Every dict here must carry all
# of SLOT_KEYS plus "confirm_prompt". Previously this whole cataloger only
# ever asked in Marathi regardless of the artisan's chosen language — the
# turn-based tester now looks the artisan's language up here and falls
# back to Hindi only if the code truly isn't covered.
QUESTIONS: dict[str, dict[str, str]] = {
    "en": {
        "craft": "What product is this? For example, a saree, a lamp, or jewellery.",
        "material": "What is it made of? Tell me the material.",
        "technique": "How was it made? Which art or technique did you use?",
        "hours": "How many hours or days did it take?",
        "colour": "What is the main colour?",
        "occasion": "When is this used? Festival, wedding, everyday?",
        "gi": "Does this have a GI tag? Yes, no, or not sure.",
        "material_cost_inr": "How much did the material cost, in rupees?",
        "material_source": "Was the material your own, from a shop, or from a trader?",
        "effort": "Was the work simple, normal, or skilled?",
        "extras": "Anything else to add? Say no if not.",
    },
    "hi": {
        "craft": "यह कौन सा उत्पाद है? जैसे साड़ी, दीया, या गहना।",
        "material": "यह किस चीज़ से बना है? सामग्री बताएं।",
        "technique": "यह कैसे बनाया? कौन सी कला या तकनीक इस्तेमाल की?",
        "hours": "कितने घंटे या दिन लगे?",
        "colour": "मुख्य रंग कौन सा है?",
        "occasion": "यह कब इस्तेमाल होता है? त्योहार, शादी, रोज़?",
        "gi": "क्या इसे जीआई टैग मिला है? हाँ, नहीं, या पता नहीं।",
        "material_cost_inr": "सामग्री में कितने रुपये लगे?",
        "material_source": "सामग्री अपनी थी, दुकान से, या व्यापारी से?",
        "effort": "काम आसान था, सामान्य था, या कुशल था?",
        "extras": "कुछ और बताना है? नहीं तो नहीं कहें।",
    },
    "mr": {
        "craft": "हे कोणते उत्पादन आहे? उदाहरणार्थ साडी, दिवा, दागिना.",
        "material": "हे कशाचे बनवले आहे? साहित्य सांगा.",
        "technique": "कशी बनवली? कोणती कला किंवा तंत्र वापरले?",
        "hours": "किती तास किंवा दिवस लागले?",
        "colour": "मुख्य रंग कोणते?",
        "occasion": "हे कधी वापरतात? सण, लग्न, रोज?",
        "gi": "याला जीआय टॅग आहे का? हो, नाही, किंवा माहित नाही.",
        "material_cost_inr": "साहित्याला किती रुपये लागले?",
        "material_source": "साहित्य स्वतःचे होते, दुकानातून, की व्यापाऱ्याकडून?",
        "effort": "काम सोपे होते, सामान्य, की कुशल?",
        "extras": "आणखी काही सांगायचे आहे का? नाही तर नाही म्हणा.",
    },
    "ta": {
        "craft": "இது என்ன பொருள்? உதாரணமாக புடவை, விளக்கு, அல்லது நகை.",
        "material": "இது எதனால் செய்யப்பட்டது? பொருளைச் சொல்லுங்கள்.",
        "technique": "இது எப்படி செய்யப்பட்டது? எந்த கலை அல்லது நுட்பம் பயன்படுத்தினீர்கள்?",
        "hours": "எத்தனை மணி நேரம் அல்லது நாட்கள் ஆனது?",
        "colour": "முக்கிய நிறம் என்ன?",
        "occasion": "இதை எப்போது பயன்படுத்துவீர்கள்? திருவிழா, திருமணம், தினசரி?",
        "gi": "இதற்கு ஜிஐ டேக் உள்ளதா? ஆம், இல்லை, அல்லது தெரியவில்லை.",
        "material_cost_inr": "பொருளுக்கு எவ்வளவு ரூபாய் ஆனது?",
        "material_source": "பொருள் உங்களுடையதா, கடையிலிருந்தா, அல்லது வியாபாரியிடமிருந்தா?",
        "effort": "வேலை எளிதானதா, சாதாரணமானதா, அல்லது திறமையானதா?",
        "extras": "வேறு ஏதாவது சொல்ல வேண்டுமா? இல்லை என்றால் இல்லை என்று சொல்லுங்கள்.",
    },
    "te": {
        "craft": "ఇది ఏ ఉత్పత్తి? ఉదాహరణకు చీర, దీపం, లేదా నగలు.",
        "material": "ఇది దేనితో తయారైంది? పదార్థం చెప్పండి.",
        "technique": "ఇది ఎలా తయారు చేశారు? ఏ కళ లేదా టెక్నిక్ ఉపయోగించారు?",
        "hours": "ఎన్ని గంటలు లేదా రోజులు పట్టింది?",
        "colour": "ప్రధాన రంగు ఏమిటి?",
        "occasion": "దీన్ని ఎప్పుడు వాడతారు? పండుగ, పెళ్లి, రోజువారీ?",
        "gi": "దీనికి జిఐ ట్యాగ్ ఉందా? అవును, లేదు, లేదా తెలియదు.",
        "material_cost_inr": "పదార్థానికి ఎంత రూపాయలు అయింది?",
        "material_source": "పదార్థం మీదేనా, దుకాణం నుండా, లేదా వ్యాపారి నుండా?",
        "effort": "పని సులభమా, సాధారణమా, లేదా నైపుణ్యమా?",
        "extras": "ఇంకా ఏమైనా చెప్పాలా? లేకపోతే లేదు అనండి.",
    },
    "kn": {
        "craft": "ಇದು ಯಾವ ಉತ್ಪನ್ನ? ಉದಾಹರಣೆಗೆ ಸೀರೆ, ದೀಪ, ಅಥವಾ ಆಭರಣ.",
        "material": "ಇದು ಯಾವುದರಿಂದ ಮಾಡಲ್ಪಟ್ಟಿದೆ? ವಸ್ತುವನ್ನು ಹೇಳಿ.",
        "technique": "ಇದನ್ನು ಹೇಗೆ ಮಾಡಿದ್ದೀರಿ? ಯಾವ ಕಲೆ ಅಥವಾ ತಂತ್ರ ಬಳಸಿದ್ದೀರಿ?",
        "hours": "ಎಷ್ಟು ಗಂಟೆ ಅಥವಾ ದಿನ ತಗುಲಿತು?",
        "colour": "ಮುಖ್ಯ ಬಣ್ಣ ಯಾವುದು?",
        "occasion": "ಇದನ್ನು ಯಾವಾಗ ಬಳಸುತ್ತೀರಿ? ಹಬ್ಬ, ಮದುವೆ, ದಿನನಿತ್ಯ?",
        "gi": "ಇದಕ್ಕೆ ಜಿಐ ಟ್ಯಾಗ್ ಇದೆಯೇ? ಹೌದು, ಇಲ್ಲ, ಅಥವಾ ಗೊತ್ತಿಲ್ಲ.",
        "material_cost_inr": "ವಸ್ತುವಿಗೆ ಎಷ್ಟು ರೂಪಾಯಿ ಆಯಿತು?",
        "material_source": "ವಸ್ತು ನಿಮ್ಮದೇ, ಅಂಗಡಿಯಿಂದ, ಅಥವಾ ವ್ಯಾಪಾರಿಯಿಂದ?",
        "effort": "ಕೆಲಸ ಸುಲಭವಾಗಿತ್ತೇ, ಸಾಮಾನ್ಯವೇ, ಅಥವಾ ಕುಶಲವೇ?",
        "extras": "ಇನ್ನೇನಾದರೂ ಹೇಳಬೇಕೇ? ಇಲ್ಲದಿದ್ದರೆ ಇಲ್ಲ ಎನ್ನಿ.",
    },
    "bn": {
        "craft": "এটা কী পণ্য? যেমন শাড়ি, প্রদীপ, বা গয়না।",
        "material": "এটা কী দিয়ে তৈরি? উপাদান বলুন।",
        "technique": "এটা কীভাবে তৈরি করলেন? কোন শিল্প বা কৌশল ব্যবহার করলেন?",
        "hours": "কত ঘণ্টা বা দিন লেগেছে?",
        "colour": "প্রধান রং কী?",
        "occasion": "এটা কখন ব্যবহার হয়? উৎসব, বিয়ে, রোজকার?",
        "gi": "এর জিআই ট্যাগ আছে কি? হ্যাঁ, না, বা জানি না।",
        "material_cost_inr": "উপাদানে কত টাকা লেগেছে?",
        "material_source": "উপাদান নিজের ছিল, দোকান থেকে, নাকি ব্যবসায়ীর থেকে?",
        "effort": "কাজটা সহজ ছিল, সাধারণ, নাকি দক্ষতার?",
        "extras": "আর কিছু বলার আছে? না থাকলে না বলুন।",
    },
    "gu": {
        "craft": "આ કઈ પ્રોડક્ટ છે? જેમ કે સાડી, દીવો, અથવા ઘરેણાં.",
        "material": "આ શેમાંથી બનાવ્યું છે? સામગ્રી જણાવો.",
        "technique": "આ કેવી રીતે બનાવ્યું? કઈ કલા અથવા ટેકનિક વાપરી?",
        "hours": "કેટલા કલાક કે દિવસ લાગ્યા?",
        "colour": "મુખ્ય રંગ કયો છે?",
        "occasion": "આ ક્યારે વપરાય છે? તહેવાર, લગ્ન, રોજિંદું?",
        "gi": "આને જીઆઈ ટેગ છે? હા, ના, કે ખબર નથી.",
        "material_cost_inr": "સામગ્રીમાં કેટલા રૂપિયા થયા?",
        "material_source": "સામગ્રી તમારી પોતાની હતી, દુકાનમાંથી, કે વેપારી પાસેથી?",
        "effort": "કામ સહેલું હતું, સામાન્ય, કે કુશળ?",
        "extras": "બીજું કંઈ કહેવું છે? ના હોય તો ના કહો.",
    },
    "pa": {
        "craft": "ਇਹ ਕਿਹੜਾ ਉਤਪਾਦ ਹੈ? ਜਿਵੇਂ ਸਾੜੀ, ਦੀਵਾ, ਜਾਂ ਗਹਿਣਾ।",
        "material": "ਇਹ ਕਿਸ ਚੀਜ਼ ਤੋਂ ਬਣਿਆ ਹੈ? ਸਮੱਗਰੀ ਦੱਸੋ।",
        "technique": "ਇਹ ਕਿਵੇਂ ਬਣਾਇਆ? ਕਿਹੜੀ ਕਲਾ ਜਾਂ ਤਕਨੀਕ ਵਰਤੀ?",
        "hours": "ਕਿੰਨੇ ਘੰਟੇ ਜਾਂ ਦਿਨ ਲੱਗੇ?",
        "colour": "ਮੁੱਖ ਰੰਗ ਕਿਹੜਾ ਹੈ?",
        "occasion": "ਇਹ ਕਦੋਂ ਵਰਤਿਆ ਜਾਂਦਾ ਹੈ? ਤਿਉਹਾਰ, ਵਿਆਹ, ਰੋਜ਼ਾਨਾ?",
        "gi": "ਕੀ ਇਸਨੂੰ ਜੀਆਈ ਟੈਗ ਮਿਲਿਆ ਹੈ? ਹਾਂ, ਨਹੀਂ, ਜਾਂ ਪਤਾ ਨਹੀਂ।",
        "material_cost_inr": "ਸਮੱਗਰੀ ਵਿੱਚ ਕਿੰਨੇ ਰੁਪਏ ਲੱਗੇ?",
        "material_source": "ਸਮੱਗਰੀ ਆਪਣੀ ਸੀ, ਦੁਕਾਨ ਤੋਂ, ਜਾਂ ਵਪਾਰੀ ਤੋਂ?",
        "effort": "ਕੰਮ ਸੌਖਾ ਸੀ, ਆਮ, ਜਾਂ ਮਾਹਰ ਵਾਲਾ?",
        "extras": "ਹੋਰ ਕੁਝ ਦੱਸਣਾ ਹੈ? ਨਹੀਂ ਤਾਂ ਨਹੀਂ ਕਹੋ।",
    },
    "ml": {
        "craft": "ഇത് ഏത് ഉൽപ്പന്നമാണ്? ഉദാഹരണത്തിന് സാരി, വിളക്ക്, അല്ലെങ്കിൽ ആഭരണം.",
        "material": "ഇത് എന്തിൽ നിന്നാണ് ഉണ്ടാക്കിയത്? വസ്തു പറയൂ.",
        "technique": "ഇത് എങ്ങനെ ഉണ്ടാക്കി? ഏത് കല അല്ലെങ്കിൽ സാങ്കേതികവിദ്യ ഉപയോഗിച്ചു?",
        "hours": "എത്ര മണിക്കൂർ അല്ലെങ്കിൽ ദിവസം എടുത്തു?",
        "colour": "പ്രധാന നിറം എന്താണ്?",
        "occasion": "ഇത് എപ്പോൾ ഉപയോഗിക്കുന്നു? ഉത്സവം, കല്യാണം, ദിവസേന?",
        "gi": "ഇതിന് ജിഐ ടാഗ് ഉണ്ടോ? ഉണ്ട്, ഇല്ല, അല്ലെങ്കിൽ അറിയില്ല.",
        "material_cost_inr": "വസ്തുവിന് എത്ര രൂപ ചെലവായി?",
        "material_source": "വസ്തു സ്വന്തമായിരുന്നോ, കടയിൽ നിന്നോ, അതോ വ്യാപാരിയിൽ നിന്നോ?",
        "effort": "ജോലി എളുപ്പമായിരുന്നോ, സാധാരണമോ, അതോ വൈദഗ്ധ്യമുള്ളതോ?",
        "extras": "വേറെ എന്തെങ്കിലും പറയാനുണ്ടോ? ഇല്ലെങ്കിൽ ഇല്ല എന്ന് പറയൂ.",
    },
    "as": {
        "craft": "এইটো কি সামগ্ৰী? যেনে শাড়ী, চাকি, বা অলংকাৰ।",
        "material": "এইটো কিহেৰে বনোৱা? সামগ্ৰীটো কওক।",
        "technique": "এইটো কেনেকৈ বনালে? কি কলা বা কৌশল ব্যৱহাৰ কৰিলে?",
        "hours": "কিমান ঘণ্টা বা দিন লাগিল?",
        "colour": "মূল ৰং কি?",
        "occasion": "এইটো কেতিয়া ব্যৱহাৰ কৰা হয়? উৎসৱ, বিয়া, দৈনন্দিন?",
        "gi": "ইয়াৰ জিআই টেগ আছেনে? হয়, নাই, বা নাজানো।",
        "material_cost_inr": "সামগ্ৰীত কিমান টকা লাগিল?",
        "material_source": "সামগ্ৰী নিজৰ আছিল, দোকানৰ পৰা, নে ব্যৱসায়ীৰ পৰা?",
        "effort": "কামটো সহজ আছিল, সাধাৰণ, নে দক্ষতাসম্পন্ন?",
        "extras": "আৰু কিবা কব লাগেনে? নহলে নাই কওক।",
    },
    "or": {
        "craft": "ଏହା କେଉଁ ଉତ୍ପାଦ? ଯେପରି ଶାଢ଼ୀ, ଦୀପ, କିମ୍ବା ଅଳଙ୍କାର।",
        "material": "ଏହା କେଉଁଠାରୁ ତିଆରି? ସାମଗ୍ରୀ କୁହନ୍ତୁ।",
        "technique": "ଏହା କିପରି ତିଆରି କଲେ? କେଉଁ କଳା କିମ୍ବା କୌଶଳ ବ୍ୟବହାର କଲେ?",
        "hours": "କେତେ ଘଣ୍ଟା କିମ୍ବା ଦିନ ଲାଗିଲା?",
        "colour": "ମୁଖ୍ୟ ରଙ୍ଗ କ'ଣ?",
        "occasion": "ଏହା କେବେ ବ୍ୟବହାର ହୁଏ? ପର୍ବ, ବିବାହ, ଦୈନିକ?",
        "gi": "ଏହାର ଜିଆଇ ଟ୍ୟାଗ୍ ଅଛି କି? ହଁ, ନାହିଁ, କିମ୍ବା ଜାଣି ନାହିଁ।",
        "material_cost_inr": "ସାମଗ୍ରୀରେ କେତେ ଟଙ୍କା ଲାଗିଲା?",
        "material_source": "ସାମଗ୍ରୀ ନିଜର ଥିଲା, ଦୋକାନରୁ, କିମ୍ବା ବ୍ୟବସାୟୀଙ୍କଠାରୁ?",
        "effort": "କାମ ସହଜ ଥିଲା, ସାଧାରଣ, କିମ୍ବା ଦକ୍ଷତାସମ୍ପନ୍ନ?",
        "extras": "ଆଉ କିଛି କହିବାକୁ ଅଛି କି? ନଥିଲେ ନାହିଁ କୁହନ୍ତୁ।",
    },
    "ur": {
        "craft": "یہ کون سی پروڈکٹ ہے؟ جیسے ساڑی، دیا، یا زیور۔",
        "material": "یہ کس چیز سے بنا ہے؟ مواد بتائیں۔",
        "technique": "یہ کیسے بنایا؟ کون سا فن یا تکنیک استعمال کی؟",
        "hours": "کتنے گھنٹے یا دن لگے؟",
        "colour": "اصل رنگ کیا ہے؟",
        "occasion": "یہ کب استعمال ہوتا ہے؟ تہوار، شادی، روزمرہ؟",
        "gi": "کیا اسے جی آئی ٹیگ ملا ہے؟ ہاں، نہیں، یا پتا نہیں۔",
        "material_cost_inr": "مواد میں کتنے روپے لگے؟",
        "material_source": "مواد اپنا تھا، دکان سے، یا تاجر سے؟",
        "effort": "کام آسان تھا، عام، یا ماہرانہ؟",
        "extras": "کچھ اور بتانا ہے؟ نہیں تو نہیں کہیں۔",
    },
}

LABELS: dict[str, dict[str, str]] = {
    "en": {"craft": "Product", "material": "Material", "technique": "Technique", "hours": "Hours", "colour": "Colour", "occasion": "Occasion", "gi": "GI Tag", "material_cost_inr": "Material Cost", "material_source": "Material Source", "effort": "Effort", "extras": "Extra"},
    "hi": {"craft": "उत्पाद", "material": "सामग्री", "technique": "तकनीक", "hours": "घंटे", "colour": "रंग", "occasion": "अवसर", "gi": "जीआई", "material_cost_inr": "सामग्री खर्च", "material_source": "सामग्री स्रोत", "effort": "मेहनत", "extras": "अतिरिक्त"},
    "mr": {
        "craft": "उत्पादन", "material": "साहित्य", "technique": "तंत्र", "hours": "तास",
        "colour": "रंग", "occasion": "प्रसंग", "gi": "जीआय", "material_cost_inr": "साहित्य खर्च",
        "material_source": "साहित्य स्रोत", "effort": "कष्ट", "extras": "अधिक",
    },
    "ta": {"craft": "பொருள்", "material": "பொருள் வகை", "technique": "நுட்பம்", "hours": "மணி நேரம்", "colour": "நிறம்", "occasion": "சந்தர்ப்பம்", "gi": "ஜிஐ", "material_cost_inr": "பொருள் செலவு", "material_source": "பொருள் மூலம்", "effort": "முயற்சி", "extras": "கூடுதல்"},
    "te": {"craft": "ఉత్పత్తి", "material": "పదార్థం", "technique": "టెక్నిక్", "hours": "గంటలు", "colour": "రంగు", "occasion": "సందర్భం", "gi": "జిఐ", "material_cost_inr": "పదార్థ ఖర్చు", "material_source": "పదార్థ మూలం", "effort": "శ్రమ", "extras": "అదనపు"},
    "kn": {"craft": "ಉತ್ಪನ್ನ", "material": "ವಸ್ತು", "technique": "ತಂತ್ರ", "hours": "ಗಂಟೆಗಳು", "colour": "ಬಣ್ಣ", "occasion": "ಸಂದರ್ಭ", "gi": "ಜಿಐ", "material_cost_inr": "ವಸ್ತು ವೆಚ್ಚ", "material_source": "ವಸ್ತು ಮೂಲ", "effort": "ಶ್ರಮ", "extras": "ಹೆಚ್ಚುವರಿ"},
    "bn": {"craft": "পণ্য", "material": "উপাদান", "technique": "কৌশল", "hours": "ঘণ্টা", "colour": "রং", "occasion": "উপলক্ষ", "gi": "জিআই", "material_cost_inr": "উপাদান খরচ", "material_source": "উপাদান উৎস", "effort": "শ্রম", "extras": "অতিরিক্ত"},
    "gu": {"craft": "પ્રોડક્ટ", "material": "સામગ્રી", "technique": "ટેકનિક", "hours": "કલાક", "colour": "રંગ", "occasion": "પ્રસંગ", "gi": "જીઆઈ", "material_cost_inr": "સામગ્રી ખર્ચ", "material_source": "સામગ્રી સ્ત્રોત", "effort": "મહેનત", "extras": "વધારાનું"},
    "pa": {"craft": "ਉਤਪਾਦ", "material": "ਸਮੱਗਰੀ", "technique": "ਤਕਨੀਕ", "hours": "ਘੰਟੇ", "colour": "ਰੰਗ", "occasion": "ਮੌਕਾ", "gi": "ਜੀਆਈ", "material_cost_inr": "ਸਮੱਗਰੀ ਖਰਚ", "material_source": "ਸਮੱਗਰੀ ਸਰੋਤ", "effort": "ਮਿਹਨਤ", "extras": "ਵਾਧੂ"},
    "ml": {"craft": "ഉൽപ്പന്നം", "material": "വസ്തു", "technique": "സാങ്കേതികവിദ്യ", "hours": "മണിക്കൂർ", "colour": "നിറം", "occasion": "അവസരം", "gi": "ജിഐ", "material_cost_inr": "വസ്തു ചെലവ്", "material_source": "വസ്തു ഉറവിടം", "effort": "അധ്വാനം", "extras": "അധികം"},
    "as": {"craft": "সামগ্ৰী", "material": "উপাদান", "technique": "কৌশল", "hours": "ঘণ্টা", "colour": "ৰং", "occasion": "উপলক্ষ", "gi": "জিআই", "material_cost_inr": "উপাদান খৰচ", "material_source": "উপাদান উৎস", "effort": "পৰিশ্ৰম", "extras": "অতিৰিক্ত"},
    "or": {"craft": "ଉତ୍ପାଦ", "material": "ସାମଗ୍ରୀ", "technique": "କୌଶଳ", "hours": "ଘଣ୍ଟା", "colour": "ରଙ୍ଗ", "occasion": "ଅବସର", "gi": "ଜିଆଇ", "material_cost_inr": "ସାମଗ୍ରୀ ଖର୍ଚ୍ଚ", "material_source": "ସାମଗ୍ରୀ ଉତ୍ସ", "effort": "ପରିଶ୍ରମ", "extras": "ଅତିରିକ୍ତ"},
    "ur": {"craft": "پروڈکٹ", "material": "مواد", "technique": "تکنیک", "hours": "گھنٹے", "colour": "رنگ", "occasion": "موقع", "gi": "جی آئی", "material_cost_inr": "مواد کا خرچ", "material_source": "مواد کا ذریعہ", "effort": "محنت", "extras": "اضافی"},
}

CONFIRM_PROMPT: dict[str, str] = {
    "en": "Is this correct?", "hi": "क्या यह सही है?", "mr": "बरोबर आहे का?",
    "ta": "இது சரியா?", "te": "ఇది సరైనదేనా?", "kn": "ಇದು ಸರಿಯೇ?",
    "bn": "এটা কি ঠিক?", "gu": "શું આ સાચું છે?", "pa": "ਕੀ ਇਹ ਸਹੀ ਹੈ?",
    "ml": "ഇത് ശരിയാണോ?", "as": "এইটো শুদ্ধনে?", "or": "ଏହା ଠିକ୍ କି?",
    "ur": "کیا یہ درست ہے؟",
}

STATUS: dict[str, dict[str, str]] = {
    "en": {"all_done": "All information received. Preparing the listing.", "ready": "The listing is ready."},
    "hi": {"all_done": "सारी जानकारी मिल गई। लिस्टिंग तैयार कर रहे हैं।", "ready": "लिस्टिंग तैयार है।"},
    "mr": {"all_done": "सगळी माहिती मिळाली. लिस्टिंग तयार करतो.", "ready": "लिस्टिंग तयार आहे."},
    "ta": {"all_done": "எல்லா தகவலும் கிடைத்தது. பட்டியலைத் தயார் செய்கிறோம்.", "ready": "பட்டியல் தயார்."},
    "te": {"all_done": "మొత్తం సమాచారం అందింది. లిస్టింగ్ సిద్ధం చేస్తున్నాం.", "ready": "లిస్టింగ్ సిద్ధంగా ఉంది."},
    "kn": {"all_done": "ಎಲ್ಲಾ ಮಾಹಿತಿ ಸಿಕ್ಕಿದೆ. ಪಟ್ಟಿಯನ್ನು ಸಿದ್ಧಪಡಿಸುತ್ತಿದ್ದೇವೆ.", "ready": "ಪಟ್ಟಿ ಸಿದ್ಧವಾಗಿದೆ."},
    "bn": {"all_done": "সব তথ্য পাওয়া গেছে। তালিকা তৈরি করছি।", "ready": "তালিকা প্রস্তুত।"},
    "gu": {"all_done": "બધી માહિતી મળી ગઈ. લિસ્ટિંગ તૈયાર કરીએ છીએ.", "ready": "લિસ્ટિંગ તૈયાર છે."},
    "pa": {"all_done": "ਸਾਰੀ ਜਾਣਕਾਰੀ ਮਿਲ ਗਈ। ਲਿਸਟਿੰਗ ਤਿਆਰ ਕਰ ਰਹੇ ਹਾਂ।", "ready": "ਲਿਸਟਿੰਗ ਤਿਆਰ ਹੈ।"},
    "ml": {"all_done": "എല്ലാ വിവരങ്ങളും ലഭിച്ചു. ലിസ്റ്റിംഗ് തയ്യാറാക്കുന്നു.", "ready": "ലിസ്റ്റിംഗ് തയ്യാറാണ്."},
    "as": {"all_done": "সকলো তথ্য পোৱা গ'ল। তালিকা প্ৰস্তুত কৰি আছোঁ।", "ready": "তালিকা সাজু।"},
    "or": {"all_done": "ସମସ୍ତ ସୂଚନା ମିଳିଲା। ତାଲିକା ପ୍ରସ୍ତୁତ କରୁଛୁ।", "ready": "ତାଲିକା ପ୍ରସ୍ତୁତ।"},
    "ur": {"all_done": "تمام معلومات مل گئیں۔ فہرست تیار کر رہے ہیں۔", "ready": "فہرست تیار ہے۔"},
}


def _lang_key(language_code: str | None) -> str:
    """BCP-47 (e.g. 'hi-IN', 'od-IN') -> our dict key, defaulting to Hindi."""
    code = (language_code or LANG_MR).strip()
    prefix = code.split("-", 1)[0].lower()
    if prefix == "od":
        prefix = "or"
    return prefix if prefix in QUESTIONS else "hi"

_DEV_DIGITS = str.maketrans("०१२३४५६७८९", "0123456789")
_WORD_NUMBERS = {
    "एक": 1,
    "दोन": 2,
    "तीन": 3,
    "चार": 4,
    "पाच": 5,
    "सहा": 6,
    "सात": 7,
    "आठ": 8,
    "नऊ": 9,
    "दहा": 10,
    "अकरा": 11,
    "बारा": 12,
    "पंधरा": 15,
    "वीस": 20,
    "तीस": 30,
    "चाळीस": 40,
    "पन्नास": 50,
    "शंभर": 100,
    "one": 1,
    "two": 2,
    "three": 3,
    "four": 4,
    "five": 5,
    "six": 6,
    "seven": 7,
    "eight": 8,
    "nine": 9,
    "ten": 10,
}

_CONFIRM = (
    "theek",
    "theek hai",
    "haan",
    "ha",
    "yes",
    "ok",
    "okay",
    "correct",
    "ठीक",
    "ठीक आहे",
    "हो",
    "होय",
    "हाँ",
    "हां",
    "बरोबर",
    "बरोबर आहे",
    "सही",
)
_REJECT = (
    "galat",
    "nahin",
    "nahi",
    "no",
    "wrong",
    "गलत",
    "चुकीचे",
    "चुकीचं",
    "नाही",
    "नको",
    "वेरं",
)
_REPEAT = ("phir se", "peeche", "repeat", "again", "परत", "पुन्हा", "पुन्हा सांगा")
_DONT_KNOW = (
    "unknown",
    "don't know",
    "dont know",
    "not sure",
    "माहित नाही",
    "नकळे",
    "पता नहीं",
    "कळत नाही",
    "समजत नाही",
)
_NO_EXTRAS = ("नाही", "नको", "काही नाही", "nothing", "no", "nahi")


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _fold(text: str) -> str:
    return re.sub(r"\s+", " ", (text or "").strip().lower())


def _provenance(source: str, confidence: float, version: str = "1") -> dict[str, Any]:
    return {
        "source": source,
        "version": version,
        "confidence": confidence,
        "ts": _now_iso(),
    }


def classify_intent(transcript: str) -> str:
    folded = _fold(transcript)
    if not folded:
        return "empty"
    if any(token == folded or folded.startswith(f"{token} ") for token in _REPEAT):
        return "repeat"
    if any(token == folded for token in _DONT_KNOW) or folded in {"माहित नाही", "कळत नाही"}:
        return "unknown"
    if folded in {token.lower() for token in _REJECT} or folded in {"galat hai", "चुकीचे आहे"}:
        return "reject"
    if folded in {token.lower() for token in _CONFIRM} or folded in {"theek hai", "haan ji"}:
        return "confirm"
    # short confirm/reject contained as the whole utterance
    compact = folded.replace(".", "").replace(",", "")
    if compact in {token.lower() for token in _CONFIRM}:
        return "confirm"
    if compact in {token.lower() for token in _REJECT}:
        return "reject"
    if compact in {token.lower() for token in _DONT_KNOW}:
        return "unknown"
    return "answer"


def _first_number(text: str) -> float | None:
    translated = text.translate(_DEV_DIGITS)
    folded = _fold(translated)
    match = re.search(r"(\d+(?:\.\d+)?)", folded)
    if match:
        return float(match.group(1))
    for word, value in _WORD_NUMBERS.items():
        if re.search(rf"(^|\s){re.escape(word)}(\s|$)", folded):
            return float(value)
    return None


def parse_slot(slot: str, transcript: str) -> tuple[Any, float]:
    """Cheap local parse. Gemini only refines once at the end."""
    folded = _fold(transcript.translate(_DEV_DIGITS))
    if slot == "hours":
        number = _first_number(transcript)
        if number is None:
            return transcript.strip(), 0.4
        if any(token in folded for token in ("दिवस", "day", "days")):
            return number * 8, 0.85
        return number, 0.9
    if slot == "material_cost_inr":
        number = _first_number(transcript)
        if number is None:
            return None, 0.3
        return int(round(number)), 0.9
    if slot == "gi":
        if any(token in folded for token in ("unsure", "माहित नाही", "कळत नाही", "पता नहीं")):
            return "unsure", 0.8
        if any(token in folded for token in ("नाही", "नको", "no", "नहीं")):
            return "no", 0.85
        if any(token in folded for token in ("हो", "होय", "yes", "haan", "आहे")):
            return "yes", 0.85
        return "unsure", 0.4
    if slot == "material_source":
        if any(token in folded for token in ("व्यापारी", "trader", "मंडी")):
            return "trader", 0.85
        if any(token in folded for token in ("दुकान", "shop")):
            return "shop", 0.85
        if any(token in folded for token in ("स्वतः", "स्वत:", "own", "घर")):
            return "own", 0.85
        return transcript.strip(), 0.4
    if slot == "effort":
        if any(token in folded for token in ("कुशल", "skilled", "कठीण")):
            return "skilled", 0.85
        if any(token in folded for token in ("सोपे", "simple", "easy")):
            return "simple", 0.85
        if any(token in folded for token in ("सामान्य", "normal")):
            return "normal", 0.85
        return "normal", 0.4
    if slot == "colour":
        parts = re.split(r",| आणि | और | and ", transcript.strip())
        colours = [part.strip() for part in parts if part.strip()]
        return colours, 0.7 if colours else 0.3
    if slot == "extras":
        if folded in {token.lower() for token in _NO_EXTRAS} or folded in {"काही नाही", "नको"}:
            return {}, 0.9
        return {"note": transcript.strip()}, 0.7
    return transcript.strip(), 0.7


_UNKNOWN_WORD: dict[str, str] = {
    "en": "not known", "hi": "पता नहीं", "mr": "माहित नाही", "ta": "தெரியவில்லை",
    "te": "తెలియదు", "kn": "ಗೊತ್ತಿಲ್ಲ", "bn": "জানি না", "gu": "ખબર નથી",
    "pa": "ਪਤਾ ਨਹੀਂ", "ml": "അറിയില്ല", "as": "নাজানো", "or": "ଜାଣି ନାହିଁ",
    "ur": "پتا نہیں",
}
_NONE_WORD: dict[str, str] = {
    "en": "none", "hi": "नहीं", "mr": "नाही", "ta": "இல்லை", "te": "లేదు",
    "kn": "ಇಲ್ಲ", "bn": "না", "gu": "નથી", "pa": "ਨਹੀਂ", "ml": "ഇല്ല",
    "as": "নাই", "or": "ନାହିଁ", "ur": "نہیں",
}


def display_value(value: Any, lang: str = "hi") -> str:
    if value is None or value == "":
        return _UNKNOWN_WORD.get(lang, _UNKNOWN_WORD["hi"])
    if value == {}:
        return _NONE_WORD.get(lang, _NONE_WORD["hi"])
    if isinstance(value, list):
        return ", ".join(str(item) for item in value)
    return str(value)


def reread_line(slot: str, value: Any, language_code: str = LANG_MR) -> str:
    lang = _lang_key(language_code)
    labels = LABELS.get(lang, LABELS["hi"])
    prompt = CONFIRM_PROMPT.get(lang, CONFIRM_PROMPT["hi"])
    return f"{labels[slot]}: {display_value(value, lang)}. {prompt}"


@dataclass
class SlotState:
    raw: str | None = None
    value: Any = None
    confirmed: bool = False
    provenance: dict[str, Any] | None = None

    def to_dict(self) -> dict[str, Any]:
        return {
            "raw": self.raw,
            "value": self.value,
            "confirmed": self.confirmed,
            "provenance": self.provenance,
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any] | None) -> "SlotState":
        data = data or {}
        return cls(
            raw=data.get("raw"),
            value=data.get("value"),
            confirmed=bool(data.get("confirmed")),
            provenance=data.get("provenance"),
        )


@dataclass
class CatalogerSession:
    language_code: str = LANG_MR
    cluster: str = "varanasi"
    phase: str = "interviewing"
    current_slot: str = "craft"
    slots: dict[str, SlotState] = field(default_factory=dict)
    question: str = QUESTIONS["mr"]["craft"]
    reread: str | None = None
    speak: str = QUESTIONS["mr"]["craft"]
    listing: dict[str, Any] | None = None
    error: str | None = None
    artisan_name: str = ""
    photo_attached: bool = False

    def __post_init__(self) -> None:
        for name in SLOT_ORDER:
            self.slots.setdefault(name, SlotState())

    def to_dict(self) -> dict[str, Any]:
        return {
            "language_code": self.language_code,
            "cluster": self.cluster,
            "phase": self.phase,
            "current_slot": self.current_slot,
            "slots": {name: state.to_dict() for name, state in self.slots.items()},
            "question": self.question,
            "reread": self.reread,
            "speak": self.speak,
            "listing": self.listing,
            "error": self.error,
            "artisan_name": self.artisan_name,
            "photo_attached": self.photo_attached,
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any] | None) -> "CatalogerSession":
        data = data or {}
        session = cls(
            language_code=data.get("language_code") or LANG_MR,
            cluster=data.get("cluster") or "varanasi",
            phase=data.get("phase") or "interviewing",
            current_slot=data.get("current_slot") or "craft",
            question=data.get("question") or QUESTIONS[_lang_key(data.get("language_code"))]["craft"],
            reread=data.get("reread"),
            speak=data.get("speak") or QUESTIONS[_lang_key(data.get("language_code"))]["craft"],
            listing=data.get("listing"),
            error=data.get("error"),
            artisan_name=data.get("artisan_name") or "",
            photo_attached=bool(data.get("photo_attached")),
        )
        raw_slots = data.get("slots") or {}
        for name in SLOT_ORDER:
            session.slots[name] = SlotState.from_dict(raw_slots.get(name))
        return session


def start_session(
    *,
    cluster: str = "varanasi",
    language_code: str = LANG_MR,
    artisan_name: str = "",
    photo_attached: bool = False,
) -> CatalogerSession:
    question = QUESTIONS[_lang_key(language_code)]["craft"]
    return CatalogerSession(
        language_code=language_code,
        cluster=cluster,
        phase="interviewing",
        current_slot="craft",
        question=question,
        speak=question,
        artisan_name=artisan_name,
        photo_attached=photo_attached,
    )


def _next_unconfirmed(session: CatalogerSession) -> str | None:
    for name in SLOT_ORDER:
        if not session.slots[name].confirmed:
            return name
    return None


def _capture(session: CatalogerSession, slot: str, transcript: str, *, unknown: bool = False) -> None:
    state = session.slots[slot]
    state.raw = transcript.strip() or None
    if unknown:
        state.value = None if slot != "colour" else []
        if slot == "extras":
            state.value = {}
        if slot == "gi":
            state.value = "unsure"
        state.provenance = _provenance("sarvam-saaras-v3", 0.35)
    else:
        value, confidence = parse_slot(slot, transcript)
        state.value = value
        state.provenance = _provenance("kalasetu-cataloger.v1", confidence)
    state.confirmed = False
    session.current_slot = slot
    session.phase = "confirming"
    session.reread = reread_line(slot, state.value, session.language_code)
    session.speak = session.reread
    session.question = QUESTIONS[_lang_key(session.language_code)][slot]


def _ask(session: CatalogerSession, slot: str) -> None:
    session.current_slot = slot
    session.phase = "interviewing"
    session.question = QUESTIONS[_lang_key(session.language_code)][slot]
    session.reread = None
    session.speak = session.question


def _advance(session: CatalogerSession) -> None:
    nxt = _next_unconfirmed(session)
    if nxt is None:
        session.phase = "copy"
        lang = _lang_key(session.language_code)
        session.speak = STATUS.get(lang, STATUS["hi"])["all_done"]
        session.question = session.speak
        return
    _ask(session, nxt)


def _finalize(session: CatalogerSession) -> CatalogerSession:
    transcripts = {
        name: {"raw": state.raw, "parsed": state.value, "confirmed": state.confirmed}
        for name, state in session.slots.items()
    }
    generated: dict[str, Any] | None = None
    try:
        from kalasetu_api.adapters.llm.gemini import generate_listing_json

        generated = generate_listing_json(transcripts)
        source = "gemini-flash-catalog.v1"
        confidence = 0.8
    except Exception as exc:  # noqa: BLE001 — tester must still show parsed slots
        session.error = f"Gemini listing copy failed: {exc}"
        generated = None
        source = "kalasetu-cataloger.v1"
        confidence = 0.55

    fields: dict[str, Any] = {}
    for name in SLOT_ORDER:
        parsed = session.slots[name].value
        local_conf = float((session.slots[name].provenance or {}).get("confidence") or 0)
        if parsed not in (None, "", []) and local_conf >= 0.85:
            fields[name] = parsed
        elif generated and generated.get(name) not in (None, "", []):
            fields[name] = generated[name]
        else:
            fields[name] = parsed
        session.slots[name].confirmed = True

    copy_keys = ("title_hi", "title_en", "title_mr", "desc_hi", "desc_en", "desc_mr")
    copy = {key: (generated or {}).get(key) or "" for key in copy_keys}
    extras = fields.get("extras") if isinstance(fields.get("extras"), dict) else {}
    if copy["title_mr"]:
        extras = {**extras, "title_mr": copy["title_mr"], "desc_mr": copy["desc_mr"]}
    fields["extras"] = extras

    prices = compute_prices(fields, cluster=session.cluster)
    listing = {
        "fields": {
            key: {
                "value": fields.get(key),
                "provenance": session.slots.get(key, SlotState()).provenance
                or _provenance(source, confidence),
            }
            for key in SLOT_ORDER
        },
        "title_hi": {"value": copy["title_hi"], "provenance": _provenance(source, confidence)},
        "title_en": {"value": copy["title_en"], "provenance": _provenance(source, confidence)},
        "desc_hi": {"value": copy["desc_hi"], "provenance": _provenance(source, confidence)},
        "desc_en": {"value": copy["desc_en"], "provenance": _provenance(source, confidence)},
        "prices": prices,
        "cluster": session.cluster,
        "language_code": session.language_code,
    }
    session.listing = listing
    session.phase = "complete"
    read_title = copy["title_mr"] or copy["title_hi"] or display_value(fields.get("craft"))
    read_desc = copy["desc_mr"] or copy["desc_hi"]
    session.speak = f"{read_title}. {read_desc}".strip()
    lang = _lang_key(session.language_code)
    session.question = STATUS.get(lang, STATUS["hi"])["ready"]
    session.reread = session.speak
    return session


def apply_transcript(session: CatalogerSession, transcript: str) -> CatalogerSession:
    session.error = None
    intent = classify_intent(transcript)
    slot = session.current_slot

    if session.phase == "complete":
        session.speak = session.reread or session.question
        return session

    if session.phase == "copy":
        return _finalize(session)

    if intent == "empty":
        session.speak = session.question
        return session

    if session.phase == "confirming":
        if intent == "confirm":
            session.slots[slot].confirmed = True
            _advance(session)
            if session.phase == "copy":
                return _finalize(session)
            return session
        if intent == "reject" or intent == "repeat":
            session.slots[slot] = SlotState()
            _ask(session, slot)
            return session
        if intent == "unknown":
            _capture(session, slot, transcript, unknown=True)
            session.slots[slot].confirmed = True
            _advance(session)
            if session.phase == "copy":
                return _finalize(session)
            return session
        # Re-said the field: repair only this slot.
        _capture(session, slot, transcript)
        return session

    # interviewing — confirm/reject words are answers here (हो = GI yes).
    if intent == "repeat":
        session.speak = session.question
        return session
    if intent == "unknown":
        _capture(session, slot, transcript, unknown=True)
        return session
    _capture(session, slot, transcript)
    return session


def confirm_current(session: CatalogerSession) -> CatalogerSession:
    return apply_transcript(session, "बरोबर")


def reject_current(session: CatalogerSession) -> CatalogerSession:
    return apply_transcript(session, "चुकीचे")


def listing_table_rows(session: CatalogerSession) -> list[dict[str, Any]]:
    """Flat rows for the Streamlit / app table — values, not spoken sentences."""
    rows: list[dict[str, Any]] = []
    listing = session.listing or {}
    field_map = listing.get("fields") or {
        name: {"value": state.value, "provenance": state.provenance}
        for name, state in session.slots.items()
        if state.raw is not None or state.value is not None
    }
    for name, payload in field_map.items():
        value = payload.get("value") if isinstance(payload, dict) else payload
        prov = payload.get("provenance") if isinstance(payload, dict) else None
        if name == "colour" and isinstance(value, list):
            shown = ", ".join(value)
        elif name == "extras" and isinstance(value, dict):
            extras = {
                key: item
                for key, item in value.items()
                if key not in {"title_mr", "desc_mr"}
            }
            shown = extras or None
        else:
            shown = value
        rows.append(
            {
                "field": name,
                "value": shown,
                "raw_transcript": session.slots.get(name, SlotState()).raw,
                "source": (prov or {}).get("source"),
                "confidence": (prov or {}).get("confidence"),
            }
        )
    for key in ("title_hi", "title_en", "desc_hi", "desc_en"):
        payload = listing.get(key) or {}
        rows.append(
            {
                "field": key,
                "value": payload.get("value") if isinstance(payload, dict) else payload,
                "raw_transcript": None,
                "source": (payload.get("provenance") or {}).get("source")
                if isinstance(payload, dict)
                else None,
                "confidence": (payload.get("provenance") or {}).get("confidence")
                if isinstance(payload, dict)
                else None,
            }
        )
    extras = (listing.get("fields") or {}).get("extras") or {}
    extra_val = extras.get("value") if isinstance(extras, dict) else extras
    if isinstance(extra_val, dict):
        if extra_val.get("title_mr"):
            rows.append(
                {
                    "field": "title_mr",
                    "value": extra_val.get("title_mr"),
                    "raw_transcript": None,
                    "source": "gemini-flash-catalog.v1",
                    "confidence": 0.8,
                }
            )
        if extra_val.get("desc_mr"):
            rows.append(
                {
                    "field": "desc_mr",
                    "value": extra_val.get("desc_mr"),
                    "raw_transcript": None,
                    "source": "gemini-flash-catalog.v1",
                    "confidence": 0.8,
                }
            )
    prices = listing.get("prices") or {}
    for band in ("floor", "recommended", "aspirational", "listed"):
        payload = prices.get(band) or {}
        rows.append(
            {
                "field": f"price_{band}_inr",
                "value": payload.get("value"),
                "raw_transcript": None,
                "source": (payload.get("provenance") or {}).get("source"),
                "confidence": (payload.get("provenance") or {}).get("confidence"),
            }
        )
    rows.append(
        {
            "field": "cluster",
            "value": session.cluster,
            "raw_transcript": None,
            "source": "tester",
            "confidence": 1.0,
        }
    )
    rows.append(
        {
            "field": "language_code",
            "value": session.language_code,
            "raw_transcript": None,
            "source": "tester",
            "confidence": 1.0,
        }
    )
    rows.append(
        {
            "field": "artisan_name",
            "value": session.artisan_name or None,
            "raw_transcript": None,
            "source": "onboarding",
            "confidence": 1.0,
        }
    )
    rows.append(
        {
            "field": "photo_attached",
            "value": session.photo_attached,
            "raw_transcript": None,
            "source": "capture",
            "confidence": 1.0,
        }
    )
    return rows


def _coerce_live_value(slot: str, value_text: str, unknown: bool) -> tuple[Any, float]:
    if unknown or not (value_text or "").strip():
        if slot == "colour":
            return [], 0.35
        if slot == "extras":
            return {}, 0.35
        if slot == "gi":
            return "unsure", 0.35
        return None, 0.35
    return parse_slot(slot, value_text)


def apply_live_tool(session: CatalogerSession, name: str, args: dict[str, Any] | None) -> dict[str, Any]:
    """Handle Gemini Live function calls. Price is never taken from the model."""
    args = args or {}
    if name == "propose_slot":
        slot = str(args.get("slot") or session.current_slot)
        if slot not in SLOT_ORDER:
            return {"ok": False, "error": f"unknown slot {slot}"}
        if session.slots[slot].confirmed and not args.get("repair"):
            return {
                "ok": False,
                "error": "slot already confirmed; call repair_slot first",
                "confirmed": True,
            }
        unknown = bool(args.get("unknown"))
        value, confidence = _coerce_live_value(slot, str(args.get("value_text") or ""), unknown)
        state = session.slots[slot]
        state.raw = str(args.get("value_text") or "").strip() or None
        state.value = value
        state.confirmed = False
        state.provenance = _provenance("gemini-live-catalog.v1", confidence)
        session.current_slot = slot
        session.phase = "confirming"
        session.reread = reread_line(slot, state.value, session.language_code)
        session.speak = session.reread
        session.question = QUESTIONS.get(_lang_key(session.language_code), {}).get(slot, session.reread)
        return {
            "ok": True,
            "slot": slot,
            "value": state.value,
            "reread": session.reread,
            "instruction": "Speak the reread line, then wait for theek hai / galat.",
        }
    if name == "confirm_slot":
        slot = str(args.get("slot") or session.current_slot)
        if slot not in SLOT_ORDER:
            return {"ok": False, "error": f"unknown slot {slot}"}
        session.slots[slot].confirmed = True
        session.current_slot = slot
        _advance(session)
        if session.phase == "copy":
            return {
                "ok": True,
                "all_slots_confirmed": True,
                "instruction": "Call write_copy now with bilingual titles and descriptions. Do not invent a price.",
            }
        return {
            "ok": True,
            "next_slot": session.current_slot,
            "ask": session.question,
            "instruction": "Ask only the next_slot question in the artisan's language.",
        }
    if name == "repair_slot":
        slot = str(args.get("slot") or session.current_slot)
        if slot not in SLOT_ORDER:
            return {"ok": False, "error": f"unknown slot {slot}"}
        session.slots[slot] = SlotState()
        _ask(session, slot)
        return {
            "ok": True,
            "slot": slot,
            "ask": session.question,
            "instruction": "Ask this slot again. Do not keep the old value.",
        }
    if name == "write_copy":
        return _apply_write_copy(session, args)
    if name == "approve_listing":
        if session.listing is None:
            return {"ok": False, "error": "write_copy first"}
        session.phase = "complete"
        return {"ok": True, "done": True, "instruction": "Stop interviewing. Listing is approved."}
    return {"ok": False, "error": f"unknown tool {name}"}


def _apply_write_copy(session: CatalogerSession, copy: dict[str, Any]) -> dict[str, Any]:
    source = "gemini-live-catalog.v1"
    confidence = 0.85
    fields: dict[str, Any] = {}
    for name in SLOT_ORDER:
        fields[name] = session.slots[name].value
        session.slots[name].confirmed = True
        if session.slots[name].provenance is None:
            session.slots[name].provenance = _provenance(source, 0.5)
    extras = fields.get("extras") if isinstance(fields.get("extras"), dict) else {}
    title_local = (copy.get("title_local") or "").strip()
    desc_local = (copy.get("desc_local") or "").strip()
    if title_local:
        extras = {**extras, "title_local": title_local, "desc_local": desc_local}
    fields["extras"] = extras
    prices = compute_prices(fields, cluster=session.cluster)
    listing = {
        "fields": {
            key: {
                "value": fields.get(key),
                "provenance": session.slots[key].provenance or _provenance(source, confidence),
            }
            for key in SLOT_ORDER
        },
        "title_hi": {
            "value": copy.get("title_hi") or "",
            "provenance": _provenance(source, confidence),
        },
        "title_en": {
            "value": copy.get("title_en") or "",
            "provenance": _provenance(source, confidence),
        },
        "desc_hi": {
            "value": copy.get("desc_hi") or "",
            "provenance": _provenance(source, confidence),
        },
        "desc_en": {
            "value": copy.get("desc_en") or "",
            "provenance": _provenance(source, confidence),
        },
        "prices": prices,
        "cluster": session.cluster,
        "language_code": session.language_code,
    }
    session.listing = listing
    session.phase = "approval"
    read_title = title_local or copy.get("title_hi") or display_value(fields.get("craft"))
    read_desc = desc_local or copy.get("desc_hi") or ""
    session.speak = f"{read_title}. {read_desc}".strip()
    session.reread = session.speak
    session.question = "Hear the card. theek hai to approve, galat to repair copy."
    return {
        "ok": True,
        "prices": {
            band: payload.get("value")
            for band, payload in prices.items()
        },
        "card_text": session.speak,
        "instruction": (
            "Read title and description aloud. Also say the three price bands from this tool "
            "response (floor, recommended, aspirational). Do not change those numbers. "
            "Wait for theek hai, then call approve_listing."
        ),
    }
