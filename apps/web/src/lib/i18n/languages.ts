export interface LanguageInfo {
  code: string;
  nativeName: string;
  englishName: string;
  script?: string;
}

export const SARVAM_LANGUAGES: LanguageInfo[] = [
  { code: "en-IN", nativeName: "English", englishName: "English (India)" },
  { code: "hi-IN", nativeName: "हिन्दी", englishName: "Hindi" },
  { code: "mr-IN", nativeName: "मराठी", englishName: "Marathi" },
  { code: "bn-IN", nativeName: "বাংলা", englishName: "Bengali" },
  { code: "ta-IN", nativeName: "தமிழ்", englishName: "Tamil" },
  { code: "te-IN", nativeName: "తెలుగు", englishName: "Telugu" },
  { code: "ml-IN", nativeName: "മലയാളം", englishName: "Malayalam" },
  { code: "kn-IN", nativeName: "ಕನ್ನಡ", englishName: "Kannada" },
  { code: "gu-IN", nativeName: "ગુજરાતી", englishName: "Gujarati" },
  { code: "pa-IN", nativeName: "ਪੰਜਾਬੀ", englishName: "Punjabi" },
  { code: "od-IN", nativeName: "ଓଡ଼ିଆ", englishName: "Odia" },
  { code: "as-IN", nativeName: "অসমীয়া", englishName: "Assamese" },
  { code: "ur-IN", nativeName: "اردو", englishName: "Urdu", script: "rtl" },
  { code: "sa-IN", nativeName: "संस्कृतम्", englishName: "Sanskrit" },
  { code: "ne-IN", nativeName: "नेपाली", englishName: "Nepali" },
  { code: "kok-IN", nativeName: "कोंकणी", englishName: "Konkani" },
  { code: "mai-IN", nativeName: "मैथिली", englishName: "Maithili" },
  { code: "sd-IN", nativeName: "سنڌي", englishName: "Sindhi", script: "rtl" },
  { code: "doi-IN", nativeName: "डोगरी", englishName: "Dogri" },
  { code: "sat-IN", nativeName: "ᱥᱟᱱᱛᱟᱲᱤ", englishName: "Santali" },
  { code: "mni-IN", nativeName: "মৈতৈলোন্", englishName: "Manipuri" },
  { code: "ks-IN", nativeName: "کٲشُر", englishName: "Kashmiri", script: "rtl" },
  { code: "brx-IN", nativeName: "बर'", englishName: "Bodo" },
];

export function getLanguageInfo(code: string): LanguageInfo {
  const norm = (code || "en-IN").toLowerCase();
  const match = SARVAM_LANGUAGES.find(
    (l) => l.code.toLowerCase() === norm || l.code.toLowerCase().startsWith(norm.split("-")[0])
  );
  return match || { code, nativeName: code, englishName: code };
}
