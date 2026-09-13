import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  static const _languages = <_Language>[
    _Language('English', 'English'),
    _Language('Hindi', 'हिन्दी'),
    _Language('Marathi', 'मराठी'),
    _Language('Tamil', 'தமிழ்'),
    _Language('Telugu', 'తెలుగు'),
    _Language('Kannada', 'ಕನ್ನಡ'),
    _Language('Bengali', 'বাংলা'),
    _Language('Gujarati', 'ગુજરાતી'),
    _Language('Punjabi', 'ਪੰਜਾਬੀ'),
    _Language('Malayalam', 'മലയാളം'),
    _Language('Assamese', 'অসমীয়া'),
    _Language('Odia', 'ଓଡ଼ିଆ'),
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
                      onSelected: (language) => setState(() => _selectedLanguage = language),
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
          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF8A7268), fontSize: 12),
        ),
      ),
    );
  }
}

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
    return Material(
      color: selected ? const Color(0xFF370E00) : const Color(0xFFF8F2EE),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFF370E00) : const Color(0xFFE7E1DD),
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
                  color: selected ? const Color(0xFFF4DED4) : const Color(0xFF8A7268),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinueBar extends StatelessWidget {
  const _ContinueBar({required this.language});

  final _Language language;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Color(0xE6FEF8F4),
        boxShadow: [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, -3))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: () => context.go('/onboarding'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF9F3C07),
            foregroundColor: Colors.white,
            elevation: 2,
            shape: const StadiumBorder(),
          ),
          child: Text(
            'Continue in ${language.name}  →',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _Language {
  const _Language(this.name, this.nativeName);

  final String name;
  final String nativeName;
}
