import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'locale_provider.dart';

/// Central string table — EN / HI / MR / KN.
/// Usage: final ks = KsStrings.of(context);
class KsStrings {
  final String _l;
  const KsStrings._(this._l);

  static KsStrings of(BuildContext context) {
    final provider = Provider.of<LocaleProvider>(context);
    return KsStrings._(provider.locale.languageCode);
  }

  String _t(Map<String, String> m) => m[_l] ?? m['en']!;

  // ── Screen 2 ─────────────────────────────────────────────────────────────────

  String get productCapture => _t({
    'en': 'Product Capture',
    'hi': 'उत्पाद कैप्चर',
    'mr': 'उत्पाद कॅप्चर',
    'kn': 'ಉತ್ಪನ್ನ ಕ್ಯಾಪ್ಚರ್',
  });

  String get stage2Badge => _t({
    'en': 'STAGE 2 — PRODUCT CAPTURE',
    'hi': 'चरण 2 — उत्पाद कैप्चर',
    'mr': 'टप्पा 2 — उत्पाद कॅप्चर',
    'kn': 'ಹಂತ 2 — ಉತ್ಪನ್ನ ಕ್ಯಾಪ್ಚರ್',
  });

  String get greetingPrefix => _t({
    'en': 'Hello Devi Ram, show us your',
    'hi': 'नमस्ते देवी राम, दिखाइए आपकी',
    'mr': 'नमस्कार देवी राम, दाखवा तुमची',
    'kn': 'ನಮಸ್ಕಾರ ದೇವಿ ರಾಮ್, ತೋರಿಸಿ ನಿಮ್ಮ',
  });

  String get craftName => _t({
    'en': 'Bamboo & Zari Craft.',
    'hi': 'बांस और जरी शिल्प।',
    'mr': 'बांबू आणि जरी हस्तकला.',
    'kn': 'ಬಿದಿರು ಮತ್ತು ಜರಿ ಶಿಲ್ಪ.',
  });

  String get captureHint => _t({
    'en': 'Capture in natural studio lighting or upload ancestral archive photographs.',
    'hi': 'प्राकृतिक प्रकाश में कैप्चर करें या पुराने फ़ोटो अपलोड करें।',
    'mr': 'नैसर्गिक प्रकाशात कॅप्चर करा किंवा जुने फोटो अपलोड करा.',
    'kn': 'ನೈಸರ್ಗಿಕ ಬೆಳಕಿನಲ್ಲಿ ಕ್ಯಾಪ್ಚರ್ ಮಾಡಿ ಅಥವಾ ಹಳೆಯ ಫೋಟೋ ಅಪ್ಲೋಡ್ ಮಾಡಿ.',
  });

  String get tapToCapture => _t({
    'en': 'Tap to open camera',
    'hi': 'कैमरा खोलने के लिए टैप करें',
    'mr': 'कॅमेरा उघडण्यासाठी टॅप करा',
    'kn': 'ಕ್ಯಾಮೆರಾ ತೆರೆಯಲು ಟ್ಯಾಪ್ ಮಾಡಿ',
  });

  String get retake => _t({
    'en': 'Retake',
    'hi': 'फिर से लें',
    'mr': 'पुन्हा घ्या',
    'kn': 'ಮತ್ತೆ ತೆಗೆಯಿರಿ',
  });

  String get uploadPhoto => _t({
    'en': 'Upload Photo',
    'hi': 'फ़ोटो अपलोड करें',
    'mr': 'फोटो अपलोड करा',
    'kn': 'ಫೋಟೋ ಅಪ್ಲೋಡ್ ಮಾಡಿ',
  });

  String get sample => _t({
    'en': 'Sample',
    'hi': 'नमूना',
    'mr': 'नमुना',
    'kn': 'ಮಾದರಿ',
  });

  String get voiceAsrLabel => _t({
    'en': 'TWO-WAY VOICE — SARVAM ASR',
    'hi': 'द्विमार्गीय वॉइस — सर्वम ASR',
    'mr': 'द्विदिशात्मक आवाज — सर्वम ASR',
    'kn': 'ದ್ವಿ-ಮಾರ್ಗ ಧ್ವನಿ — ಸರ್ವಮ್ ASR',
  });

  String get languageName => _t({
    'en': 'English',
    'hi': 'हिंदी',
    'mr': 'मराठी',
    'kn': 'ಕನ್ನಡ',
  });

  String get activeQuery => _t({
    'en': 'ACTIVE AUDIO QUERY',
    'hi': 'सक्रिय ऑडियो प्रश्न',
    'mr': 'सक्रिय ऑडिओ प्रश्न',
    'kn': 'ಸಕ್ರಿಯ ಆಡಿಯೋ ಪ್ರಶ್ನೆ',
  });

  String get voiceQuery => _t({
    'en': '"What materials were used and how long did it take to make this craft?"',
    'hi': '"इस शिल्प को बनाने में क्या सामग्री लगी और कितना समय लगा?"',
    'mr': '"हे हस्तकला बनवण्यासाठी कोणती सामग्री वापरली आणि किती वेळ लागला?"',
    'kn': '"ಈ ಕರಕುಶಲ ತಯಾರಿಸಲು ಯಾವ ವಸ್ತುಗಳನ್ನು ಬಳಸಲಾಯಿತು ಮತ್ತು ಎಷ್ಟು ಸಮಯ ತೆಗೆದುಕೊಂಡಿತು?"',
  });

  String get tapMicHint => _t({
    'en': 'Tap mic to start voice query',
    'hi': 'वॉइस क्वेरी शुरू करने के लिए माइक टैप करें',
    'mr': 'व्हॉइस प्रश्न सुरू करण्यासाठी मायक टॅप करा',
    'kn': 'ಧ್ವನಿ ಪ್ರಶ್ನೆ ಪ್ರಾರಂಭಿಸಲು ಮೈಕ್ ಟ್ಯಾಪ್ ಮಾಡಿ',
  });

  String get missingInfoHint => _t({
    'en': 'Missing info prompt auto-triggers voice query loop',
    'hi': 'छूटी जानकारी स्वचालित रूप से वॉइस क्वेरी लूप चालू करती है',
    'mr': 'गहाळ माहिती स्वयंचलितपणे व्हॉइस प्रश्न लूप सुरू करते',
    'kn': 'ಕಾಣೆಯಾದ ಮಾಹಿತಿ ಸ್ವಯಂಚಾಲಿತವಾಗಿ ಧ್ವನಿ ಪ್ರಶ್ನೆ ಲೂಪ್ ಪ್ರಚೋದಿಸುತ್ತದೆ',
  });

  String get runIntelligence => _t({
    'en': 'Run Intelligence Engine',
    'hi': 'इंटेलिजेंस इंजन चलाएं',
    'mr': 'इंटेलिजन्स इंजिन चालवा',
    'kn': 'ಇಂಟೆಲಿಜೆನ್ಸ್ ಎಂಜಿನ್ ರನ್ ಮಾಡಿ',
  });

  String get stepFooter => _t({
    'en': 'Step 2 of 5  •  Auto sync to offline draft',
    'hi': 'चरण 2 / 5  •  ऑफलाइन ड्राफ्ट में स्वतः सिंक',
    'mr': 'टप्पा 2 / 5  •  ऑफलाइन ड्राफ्टमध्ये स्वयंचलित सिंक',
    'kn': 'ಹಂತ 2 / 5  •  ಆಫ್‌ಲೈನ್ ಡ್ರಾಫ್ಟ್‌ಗೆ ಸ್ವಯಂ ಸಿಂಕ್',
  });

  String get photoTaken => _t({
    'en': 'Photo captured!',
    'hi': 'फ़ोटो कैप्चर हुई!',
    'mr': 'फोटो कॅप्चर केला!',
    'kn': 'ಫೋಟೋ ಕ್ಯಾಪ್ಚರ್ ಆಯಿತು!',
  });

  String get photoSelected => _t({
    'en': 'Photo selected from gallery',
    'hi': 'गैलरी से फ़ोटो चुनी गई',
    'mr': 'गॅलरीमधून फोटो निवडला',
    'kn': 'ಗ್ಯಾಲರಿಯಿಂದ ಫೋಟೋ ಆಯ್ಕೆ ಮಾಡಲಾಗಿದೆ',
  });

  String get sampleLoaded => _t({
    'en': 'Sample image loaded',
    'hi': 'नमूना छवि लोड की गई',
    'mr': 'नमुना प्रतिमा लोड केली',
    'kn': 'ಮಾದರಿ ಚಿತ್ರ ಲೋಡ್ ಆಯಿತು',
  });

  String get cameraUnavailable => _t({
    'en': 'Camera unavailable on this device',
    'hi': 'इस डिवाइस पर कैमरा उपलब्ध नहीं',
    'mr': 'या डिव्हाइसवर कॅमेरा उपलब्ध नाही',
    'kn': 'ಈ ಸಾಧನದಲ್ಲಿ ಕ್ಯಾಮೆರಾ ಲಭ್ಯವಿಲ್ಲ',
  });

  String get listening => _t({
    'en': 'Listening...',
    'hi': 'सुन रहे हैं...',
    'mr': 'ऐकत आहे...',
    'kn': 'ಆಲಿಸುತ್ತಿದ್ದೇವೆ...',
  });

  String get querySent => _t({
    'en': 'Voice query sent',
    'hi': 'वॉइस क्वेरी भेजी गई',
    'mr': 'व्हॉइस प्रश्न पाठवला',
    'kn': 'ಧ್ವನಿ ಪ್ರಶ್ನೆ ಕಳುಹಿಸಲಾಗಿದೆ',
  });

  // ── Screen 3 ─────────────────────────────────────────────────────────────────

  String get intelligenceReview => _t({
    'en': 'Intelligence Review',
    'hi': 'इंटेलिजेंस समीक्षा',
    'mr': 'इंटेलिजन्स समीक्षा',
    'kn': 'ಇಂಟೆಲಿಜೆನ್ಸ್ ವಿಮರ್ಶೆ',
  });

  String get stage3Badge => _t({
    'en': 'STAGE 3 — INTELLIGENCE ENGINE',
    'hi': 'चरण 3 — इंटेलिजेंस इंजन',
    'mr': 'टप्पा 3 — इंटेलिजन्स इंजिन',
    'kn': 'ಹಂತ 3 — ಇಂಟೆಲಿಜೆನ್ಸ್ ಎಂಜಿನ್',
  });

  String get step3Of5 => _t({
    'en': 'Step 3 of 5',
    'hi': 'चरण 3 / 5',
    'mr': 'टप्पा 3 / 5',
    'kn': 'ಹಂತ 3 / 5',
  });

  String get confidencePill => _t({
    'en': '● Confidence: 98%',
    'hi': '● विश्वास: 98%',
    'mr': '● विश्वासार्हता: 98%',
    'kn': '● ವಿಶ್ವಾಸ: 98%',
  });

  String get multiAgentPill => _t({
    'en': '✦ LangGraph Multi-Agent',
    'hi': '✦ मल्टी-एजेंट',
    'mr': '✦ मल्टी-एजंट',
    'kn': '✦ ಮಲ್ಟಿ-ಏಜೆಂಟ್',
  });

  String get craftIntelligence => _t({
    'en': 'Craft Intelligence &\nSynthesis',
    'hi': 'शिल्प बुद्धिमत्ता\nएवं संश्लेषण',
    'mr': 'हस्तकला बुद्धिमत्ता\nआणि संश्लेषण',
    'kn': 'ಕರಕುಶಲ ಬುದ್ಧಿಮತ್ತೆ\nಮತ್ತು ಸಂಶ್ಲೇಷಣೆ',
  });

  String get analysisSubtext => _t({
    'en': 'Autonomous analysis synthesized from artisan audio stream & craft imagery.',
    'hi': 'कारीगर ऑडियो स्ट्रीम और शिल्प चित्रों से स्वायत्त विश्लेषण।',
    'mr': 'कारागीर ऑडिओ प्रवाह आणि हस्तकला प्रतिमांमधून स्वायत्त विश्लेषण.',
    'kn': 'ಕರಕುಶಲಿ ಆಡಿಯೋ ಮತ್ತು ಶಿಲ್ಪ ಚಿತ್ರಗಳಿಂದ ಸ್ವಾಯತ್ತ ವಿಶ್ಲೇಷಣೆ.',
  });

  String get listingAgent => _t({
    'en': 'LISTING AGENT (HINDI + EN)',
    'hi': 'लिस्टिंग एजेंट (हिंदी + अंग्रेज़ी)',
    'mr': 'लिस्टिंग एजंट (हिंदी + इंग्रजी)',
    'kn': 'ಲಿಸ್ಟಿಂಗ್ ಏಜೆಂಟ್ (ಹಿಂದಿ + ಇಂಗ್ಲಿಷ್)',
  });

  String get specsExtracted => _t({
    'en': '9 specs extracted',
    'hi': '9 विवरण निकाले',
    'mr': '9 तपशील काढले',
    'kn': '9 ವಿಶೇಷಣಗಳು ಸಂಗ್ರಹಿಸಲಾಗಿದೆ',
  });

  String get seoTitleLabel => _t({
    'en': 'GENERATED SEO TITLE',
    'hi': 'जेनरेटेड SEO शीर्षक',
    'mr': 'जनरेट केलेले SEO शीर्षक',
    'kn': 'ರಚಿಸಲಾದ SEO ಶೀರ್ಷಿಕೆ',
  });

  String get audioSummary => _t({
    'en': 'Sarvam Voice Summary: Malwa Dialect',
    'hi': 'सर्वम वॉइस सारांश: मालवा बोली',
    'mr': 'सर्वम व्हॉइस सारांश: मालवा बोली',
    'kn': 'ಸರ್ವಮ್ ವಾಯ್ಸ್ ಸಾರಾಂಶ: ಮಾಲ್ವಾ ಉಪಭಾಷೆ',
  });

  String get audioPlaying => _t({
    'en': 'Playing Sarvam TTS audio…',
    'hi': 'सर्वम TTS ऑडियो चल रही है…',
    'mr': 'सर्वम TTS ऑडिओ वाजत आहे…',
    'kn': 'ಸರ್ವಮ್ TTS ಆಡಿಯೋ ಪ್ಲೇ ಆಗುತ್ತಿದೆ…',
  });

  String get trendAgent => _t({
    'en': 'TREND AGENT: MARKET DEMAND',
    'hi': 'ट्रेंड एजेंट: बाजार मांग',
    'mr': 'ट्रेंड एजंट: बाजार मागणी',
    'kn': 'ಟ್ರೆಂಡ್ ಏಜೆಂಟ್: ಮಾರುಕಟ್ಟೆ ಬೇಡಿಕೆ',
  });

  String get peakWindows => _t({
    'en': 'Peak Windows',
    'hi': 'पीक अवधि',
    'mr': 'पीक कालावधी',
    'kn': 'ಪೀಕ್ ಅವಧಿ',
  });

  String get peakValue => _t({
    'en': 'Oct – Feb Festive',
    'hi': 'अक्टू – फरव उत्सव',
    'mr': 'ऑक्टो – फेब्रु उत्सव',
    'kn': 'ಅಕ್ಟೋ – ಫೆಬ್ ಹಬ್ಬ',
  });

  String get topHotspots => _t({
    'en': 'Top Hotspots',
    'hi': 'शीर्ष बाजार',
    'mr': 'शीर्ष बाजार',
    'kn': 'ಪ್ರಮುಖ ಮಾರ್ಕೆಟ್',
  });

  String get hotspotsValue => _t({
    'en': 'Delhi & Mumbai',
    'hi': 'दिल्ली और मुंबई',
    'mr': 'दिल्ली आणि मुंबई',
    'kn': 'ದೆಹಲಿ ಮತ್ತು ಮುಂಬೈ',
  });

  String get trendBody => _t({
    'en': 'Festive bridal queries indicate surging preference for authentic unbleached raw silk weaves with unpolished gold zari motifs.',
    'hi': 'त्योहारी खोजों में प्रामाणिक कच्चे रेशम बुनाई की बढ़ती प्राथमिकता दिखती है।',
    'mr': 'उत्सवी वधू शोधांमध्ये प्रामाणिक कच्च्या रेशीम विणकामाची वाढती पसंती दिसते.',
    'kn': 'ಹಬ್ಬದ ಮದುವೆ ಹುಡುಕಾಟಗಳಲ್ಲಿ ಅಸಲಿ ಕಚ್ಚಾ ರೇಷ್ಮೆ ನೇಯ್ಗೆಗೆ ಹೆಚ್ಚಿನ ಆದ್ಯತೆ.',
  });

  String get fairPriceAgent => _t({
    'en': 'FAIR-PRICE AGENT + ML',
    'hi': 'उचित मूल्य एजेंट + ML',
    'mr': 'उचित किंमत एजंट + ML',
    'kn': 'ನ್ಯಾಯ ಬೆಲೆ ಏಜೆಂಟ್ + ML',
  });

  String get fairWageCertified => _t({
    'en': 'Fair-Wage Certified',
    'hi': 'उचित वेतन प्रमाणित',
    'mr': 'उचित वेतन प्रमाणित',
    'kn': 'ನ್ಯಾಯ-ವೇತನ ಪ್ರಮಾಣಿತ',
  });

  String get rawMaterial => _t({
    'en': 'Raw Material (Pure Silk + Zari)',
    'hi': 'कच्चा माल (शुद्ध रेशम + जरी)',
    'mr': 'कच्चा माल (शुद्ध रेशीम + जरी)',
    'kn': 'ಕಚ್ಚಾ ವಸ್ತು (ಶುದ್ಧ ರೇಷ್ಮೆ + ಜರಿ)',
  });

  String get labourCost => _t({
    'en': 'Artisan Labour (14 days @ ₹140/day)',
    'hi': 'कारीगर श्रम (14 दिन @ ₹140/दिन)',
    'mr': 'कारागीर श्रम (14 दिवस @ ₹140/दिवस)',
    'kn': 'ಕರಕುಶಲಿ ಕಾರ್ಮಿಕ (14 ದಿನ @ ₹140/ದಿನ)',
  });

  String get finishing => _t({
    'en': 'Finishing, Packaging & Buffer',
    'hi': 'फिनिशिंग, पैकेजिंग और बफर',
    'mr': 'फिनिशिंग, पॅकेजिंग आणि बफर',
    'kn': 'ಫಿನಿಶಿಂಗ್, ಪ್ಯಾಕೇಜಿಂಗ್ ಮತ್ತು ಬಫರ್',
  });

  String get recommendedTarget => _t({
    'en': 'RECOMMENDED TARGET',
    'hi': 'अनुशंसित लक्ष्य',
    'mr': 'शिफारस केलेले लक्ष्य',
    'kn': 'ಶಿಫಾರಸು ಮಾಡಲಾದ ಗುರಿ',
  });

  String get netMargin => _t({
    'en': 'NET ARTISAN MARGIN',
    'hi': 'शुद्ध कारीगर मार्जिन',
    'mr': 'निव्वळ कारागीर मार्जिन',
    'kn': 'ನಿವ್ವಳ ಕರಕುಶಲಿ ಮಾರ್ಜಿನ್',
  });

  String get guaranteed => _t({
    'en': 'Guaranteed',
    'hi': 'गारंटीकृत',
    'mr': 'हमीखात्री',
    'kn': 'ಖಾತರಿ',
  });

  String get lowestPrice => _t({
    'en': 'LOWEST',
    'hi': 'न्यूनतम',
    'mr': 'किमान',
    'kn': 'ಕನಿಷ್ಠ',
  });

  String get recommendedPrice => _t({
    'en': 'RECOMMENDED',
    'hi': 'अनुशंसित',
    'mr': 'शिफारस',
    'kn': 'ಶಿಫಾರಸು',
  });

  String get highestPrice => _t({
    'en': 'HIGHEST',
    'hi': 'उच्चतम',
    'mr': 'जास्तीत जास्त',
    'kn': 'ಅತ್ಯಧಿಕ',
  });

  String get opportunityAgent => _t({
    'en': 'BUSINESS OPPORTUNITY AGENT',
    'hi': 'व्यापार अवसर एजेंट',
    'mr': 'व्यवसाय संधी एजंट',
    'kn': 'ವ್ಯಾಪಾರ ಅವಕಾಶ ಏಜೆಂಟ್',
  });

  String get bundleTitle => _t({
    'en': 'Bundle Upsell Recommendation',
    'hi': 'बंडल अपसेल सिफारिश',
    'mr': 'बंडल अपसेल शिफारस',
    'kn': 'ಬಂಡಲ್ ಅಪ್‌ಸೆಲ್ ಶಿಫಾರಸು',
  });

  String get bundleBody => _t({
    'en': 'Artisan has ~0.4m cut silk left. Craft a matching scrap-silk potli pouch to lift bundle order value by +₹250.',
    'hi': 'कारीगर के पास ~0.4m कटा रेशम बचा है। मिलान वाली पोटली बनाएं, ऑर्डर मूल्य +₹250 बढ़ेगा।',
    'mr': 'कारागीराकडे ~0.4m कापलेला रेशीम शिल्लक. जुळणारी पोटली बनवा, ऑर्डर मूल्य +₹250 वाढेल.',
    'kn': 'ಕರಕುಶಲಿಗೆ ~0.4m ಕಡಿತ ರೇಷ್ಮೆ ಉಳಿದಿದೆ. ಪೊಟ್ಲಿ ಚೀಲ ಮಾಡಿ, ಬಂಡಲ್ ಮೌಲ್ಯ +₹250 ಏರುತ್ತದೆ.',
  });

  String get payloadTitle => _t({
    'en': 'STRUCTURED PAYLOAD PREVIEW',
    'hi': 'संरचित पेलोड पूर्वावलोकन',
    'mr': 'संरचित पेलोड पूर्वावलोकन',
    'kn': 'ರಚನಾತ್ಮಕ ಪೇಲೋಡ್ ಮುನ್ನೋಟ',
  });

  String get readyToVerify => _t({
    'en': 'Ready to Verify',
    'hi': 'सत्यापन के लिए तैयार',
    'mr': 'सत्यापनासाठी तयार',
    'kn': 'ಪರಿಶೀಲಿಸಲು ಸಿದ್ಧ',
  });

  String get originCluster => _t({
    'en': 'Origin Cluster',
    'hi': 'उत्पत्ति क्लस्टर',
    'mr': 'उगम क्लस्टर',
    'kn': 'ಮೂಲ ಕ್ಲಸ್ಟರ್',
  });

  String get weaveTechnique => _t({
    'en': 'Weave Technique',
    'hi': 'बुनाई तकनीक',
    'mr': 'विणकाम तंत्र',
    'kn': 'ನೇಯ್ಗೆ ತಂತ್ರ',
  });

  String get dispatchSla => _t({
    'en': 'Dispatch SLA',
    'hi': 'डिस्पैच SLA',
    'mr': 'प्रेषण SLA',
    'kn': 'ರವಾನೆ SLA',
  });

  String get channelsMapped => _t({
    'en': 'Channels Mapped',
    'hi': 'चैनल मैप किए',
    'mr': 'चॅनेल मॅप केले',
    'kn': 'ಚಾನೆಲ್‌ಗಳು ಮ್ಯಾಪ್ ಆಗಿವೆ',
  });

  String get reviewCta => _t({
    'en': 'Review Verified Product Card',
    'hi': 'सत्यापित उत्पाद कार्ड समीक्षा करें',
    'mr': 'सत्यापित उत्पाद कार्ड पुनरावलोकन करा',
    'kn': 'ಪರಿಶೀಲಿತ ಉತ್ಪನ್ನ ಕಾರ್ಡ್ ಪರಿಶೀಲಿಸಿ',
  });

  String get hashtagCopied => _t({
    'en': 'Hashtag copied',
    'hi': 'हैशटैग कॉपी किया',
    'mr': 'हॅशटॅग कॉपी केला',
    'kn': 'ಹ್ಯಾಶ್‌ಟ್ಯಾಗ್ ಕಾಪಿ ಆಯಿತು',
  });

  String get priceBandSelected => _t({
    'en': 'price selected',
    'hi': 'मूल्य चुना गया',
    'mr': 'किंमत निवडली',
    'kn': 'ಬೆಲೆ ಆಯ್ಕೆ ಮಾಡಲಾಗಿದೆ',
  });
}
