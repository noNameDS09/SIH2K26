import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'l10n/locale_provider.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  static const _languages = <_Language>[
    _Language('English',   'English',      'en',  'Continue in English  →'),
    _Language('Hindi',     'हिन्दी',        'hi',  'हिंदी में जारी रखें  →'),
    _Language('Marathi',   'मराठी',        'mr',  'मराठीत सुरू ठेवा  →'),
    _Language('Tamil',     'தமிழ்',        'ta',  'தமிழில் தொடரவும்  →'),
    _Language('Telugu',    'తెలుగు',       'te',  'తెలుగులో కొనసాగించు  →'),
    _Language('Kannada',   'ಕನ್ನಡ',        'kn',  'ಕನ್ನಡದಲ್ಲಿ ಮುಂದುವರಿಸಿ  →'),
    _Language('Bengali',   'বাংলা',        'bn',  'বাংলায় চালিয়ে যান  →'),
    _Language('Gujarati',  'ગુજરાતી',      'gu',  'ગુજરાતીમાં આગળ વધો  →'),
    _Language('Punjabi',   'ਪੰਜਾਬੀ',      'pa',  'ਪੰਜਾਬੀ ਵਿੱਚ ਜਾਰੀ ਰੱਖੋ  →'),
    _Language('Malayalam', 'മലയാളം',      'ml',  'മലയാളത്തിൽ തുടരുക  →'),
    _Language('Assamese',  'অসমীয়া',     'as',  'অসমীয়াত আগবাঢ়ক  →'),
    _Language('Odia',      'ଓଡ଼ିଆ',       'or',  'ଓଡ଼ିଆରେ ଜାରି ରଖ  →'),
    _Language('Urdu',      'اُردُو',        'ur',  'اردو میں جاری رکھیں →'),
    _Language('Maithili',  'मैथिली',       'mai', 'मैथिलीमे आगू बढ़ू →'),
    _Language('Santali',   'संताली',       'sat', 'संतालीरे आगे बढ़ →'),
    _Language('Kashmiri',  'कॉशुर',        'ks',  'कॉशुरमें जारी रखें →'),
    _Language('Nepali',    'नेपाली',       'ne',  'नेपालीमा जारी राख्नुस् →'),
    _Language('Sindhi',    'سنڌي',         'sd',  'سنڌيءَ ۾ جاري رکو →'),
    _Language('Dogri',     'डोगरी',        'doi', 'डोगरीच जारी रखो →'),
    _Language('Manipuri',  'মৈতৈলোন্',    'mni', 'মৈতৈলোন্দা লৈবাক্ →'),
    _Language('Bodo',      'बड़ो',          'brx', 'बड़ो खोनफ्रनाय →'),
    _Language('Sanskrit',  'संस्कृतम्',    'sa',  'संस्कृते अग्रे गच्छ →'),
    _Language('Konkani',   'कोंकणी',       'kok', 'कोंकणींत पुडे वच →'),
  ];

  _Language _selectedLanguage = _languages.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEED6),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _KalaSetuLogo(),
                    const SizedBox(height: 34),
                    Text(
                      'Choose a language',
                      style: GoogleFonts.playfairDisplay(
                        color: const Color(0xFF1D1B19),
                        fontSize: 28,
                        height: 1.12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'अपनी भाषा चुनें',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF705F58),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _LanguageGrid(
                      languages: _languages,
                      selectedLanguage: _selectedLanguage,
                      onSelected: (language) =>
                          setState(() => _selectedLanguage = language),
                    ),
                  ],
                ),
              ),
            ),
            _ContinueBar(language: _selectedLanguage),
          ],
        ),
      ),
    );
  }
}

// ─── Logo ─────────────────────────────────────────────────────────────────────

class _KalaSetuLogo extends StatelessWidget {
  const _KalaSetuLogo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/kalasetu_logo.png',
      width: double.infinity,
      height: 176,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const _LogoFallback(),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 176,
      decoration: BoxDecoration(
        color: const Color(0xFFF3EDE9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9C9C0)),
      ),
      child: Center(
        child: Text(
          'Add assets/images/kalasetu_logo.png',
          style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF8A7268), fontSize: 12),
        ),
      ),
    );
  }
}

// ─── Language grid ────────────────────────────────────────────────────────────

class _LanguageGrid extends StatelessWidget {
  const _LanguageGrid({
    required this.languages,
    required this.selectedLanguage,
    required this.onSelected,
  });

  final List<_Language> languages;
  final _Language selectedLanguage;
  final ValueChanged<_Language> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: languages.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.28,
      ),
      itemBuilder: (context, index) {
        final language = languages[index];
        return _LanguageButton(
          language: language,
          selected: language == selectedLanguage,
          onPressed: () => onSelected(language),
        );
      },
    );
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({
    required this.language,
    required this.selected,
    required this.onPressed,
  });

  final _Language language;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.09 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: Material(
        color: selected ? const Color(0xFF370E00) : const Color(0xFFF8F2EE),
        borderRadius: BorderRadius.circular(12),
        elevation: selected ? 4 : 0,
        shadowColor: const Color(0x559F3C07),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? const Color(0xFF370E00)
                    : const Color(0xFFE7E1DD),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  language.nativeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: selected ? Colors.white : const Color(0xFF32302E),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  language.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: selected
                        ? const Color(0xFFF4DED4)
                        : const Color(0xFF8A7268),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Continue bar ─────────────────────────────────────────────────────────────

class _ContinueBar extends StatelessWidget {
  const _ContinueBar({required this.language});

  final _Language language;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Color(0xE6FEF8F4),
        boxShadow: [
          BoxShadow(
              color: Color(0x12000000), blurRadius: 12, offset: Offset(0, -3))
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: () {
            context.read<LocaleProvider>().setLocale(Locale(language.localeCode));
            context.go('/onboarding');
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF9F3C07),
            foregroundColor: Colors.white,
            elevation: 2,
            shape: const StadiumBorder(),
          ),
          child: Text(
            language.continueText,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

// ─── Data class ───────────────────────────────────────────────────────────────

class _Language {
  const _Language(
      this.name, this.nativeName, this.localeCode, this.continueText);

  final String name;
  final String nativeName;
  final String localeCode;
  final String continueText;
}
