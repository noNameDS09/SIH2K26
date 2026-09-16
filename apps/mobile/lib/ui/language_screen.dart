import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import 'l10n/locale_provider.dart';
import '../services/api_service.dart';

/// Voice-first language selection shown immediately after the launch splash.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  static const _languages = <_Language>[
    _Language('English', 'English', 'en', 'Continue in English'),
    _Language('Hindi', 'हिन्दी', 'hi', 'हिंदी में जारी रखें'),
    _Language('Marathi', 'मराठी', 'mr', 'मराठीत सुरू ठेवा'),
    _Language('Tamil', 'தமிழ்', 'ta', 'தமிழில் தொடரவும்'),
    _Language('Telugu', 'తెలుగు', 'te', 'తెలుగులో కొనసాగించు'),
    _Language('Kannada', 'ಕನ್ನಡ', 'kn', 'ಕನ್ನಡದಲ್ಲಿ ಮುಂದುವರಿಸಿ'),
    _Language('Bengali', 'বাংলা', 'bn', 'বাংলায় চালিয়ে যান'),
    _Language('Gujarati', 'ગુજરાતી', 'gu', 'ગુજરાતીમાં આગળ વધો'),
    _Language('Punjabi', 'ਪੰਜਾਬੀ', 'pa', 'ਪੰਜਾਬੀ ਵਿੱਚ ਜਾਰੀ ਰੱਖੋ'),
    _Language('Malayalam', 'മലയാളം', 'ml', 'മലയാളത്തിൽ തുടരുക'),
    _Language('Assamese', 'অসমীয়া', 'as', 'অসমীয়াত আগবাঢ়ক'),
    _Language('Odia', 'ଓଡ଼ିଆ', 'or', 'ଓଡ଼ିଆରେ ଜାରି ରଖ'),
    _Language('Urdu', 'اُردُو', 'ur', 'اردو میں جاری رکھیں'),
    _Language('Maithili', 'मैथिली', 'mai', 'मैथिलीमे आगू बढ़ू'),
    _Language('Santali', 'संताली', 'sat', 'संतालीरे आगे बढ़'),
    _Language('Kashmiri', 'कॉशुर', 'ks', 'कॉशुरमें जारी रखें'),
    _Language('Nepali', 'नेपाली', 'ne', 'नेपालीमा जारी राख्नुस्'),
    _Language('Sindhi', 'سنڌي', 'sd', 'سنڌيءَ ۾ جاري رکو'),
    _Language('Dogri', 'डोगरी', 'doi', 'डोगरीच जारी रखो'),
    _Language('Manipuri', 'মৈতৈলোন', 'mni', 'মৈতৈলোনদা লৈবাক'),
    _Language('Bodo', 'बड़ो', 'brx', 'बड़ो खोनफ्रनाय'),
    _Language('Sanskrit', 'संस्कृतम्', 'sa', 'संस्कृते अग्रे गच्छ'),
    _Language('Konkani', 'कोंकणी', 'kok', 'कोंकणीत पुढे वच'),
  ];

  _Language _selectedLanguage = _languages.first;
  bool _isRecording = false;
  bool _isDetecting = false;
  final _recorder = AudioRecorder();
  final List<Uint8List> _pcmChunks = [];

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  void _continue() {
    context.read<LocaleProvider>().setLocale(Locale(_selectedLanguage.localeCode));
    context.go('/otp');
  }

  Future<void> _onRecordingTap() async {
    if (_isRecording) {
      // Stop recording and detect language
      setState(() { _isRecording = false; _isDetecting = true; });
      try {
        await _recorder.stop();
        if (_pcmChunks.isNotEmpty) {
          final wav = _buildWav(_pcmChunks);
          final detectedCode = await ApiService.detectLanguage(wav);
          if (detectedCode != null && mounted) {
            // Map BCP-47 to locale code (e.g. mr-IN -> mr)
            final langCode = detectedCode.split('-').first.toLowerCase();
            final match = _languages.where((l) => l.localeCode == langCode).firstOrNull;
            if (match != null) {
              setState(() => _selectedLanguage = match);
              // Play greeting if TTS available
            }
          }
        }
      } catch (_) {}
      if (mounted) setState(() => _isDetecting = false);
    } else {
      // Start recording
      _pcmChunks.clear();
      try {
        final hasPermission = await _recorder.hasPermission();
        if (!hasPermission) return;
        final stream = await _recorder.startStream(
          const RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: 16000, numChannels: 1),
        );
        stream.listen((chunk) => _pcmChunks.add(Uint8List.fromList(chunk)));
        setState(() => _isRecording = true);
        // Auto-stop after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (_isRecording && mounted) _onRecordingTap();
        });
      } catch (_) {
        setState(() => _isRecording = true);
        Future.delayed(const Duration(seconds: 3), () {
          if (_isRecording && mounted) setState(() => _isRecording = false);
        });
      }
    }
  }

  static Uint8List _buildWav(List<Uint8List> chunks, {int sampleRate = 16000}) {
    final pcm = Uint8List.fromList(chunks.expand((c) => c).toList());
    final header = ByteData(44);
    void setStr(int offset, String s) {
      for (var i = 0; i < s.length; i++) header.setUint8(offset + i, s.codeUnitAt(i));
    }
    setStr(0, 'RIFF');
    header.setUint32(4, 36 + pcm.length, Endian.little);
    setStr(8, 'WAVE');
    setStr(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, 1, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * 2, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    setStr(36, 'data');
    header.setUint32(40, pcm.length, Endian.little);
    final result = Uint8List(44 + pcm.length);
    result.setRange(0, 44, header.buffer.asUint8List());
    result.setRange(44, result.length, pcm);
    return result;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFFEF8F4),
        body: SafeArea(
          child: Stack(
            children: [
              const Align(
                alignment: Alignment(0, -0.91),
                child: SizedBox(
                  width: 154,
                  height: 92,
                  child: _KalaSetuLogo(),
                ),
              ),
              Align(
                alignment: const Alignment(0, .42),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: _LanguageChoiceCard(
                    selectedLanguage: _selectedLanguage,
                    languages: _languages,
                    isRecording: _isRecording,
                    isDetecting: _isDetecting,
                    onRecordingTap: _onRecordingTap,
                    onLanguageChanged: (language) => setState(
                      () => _selectedLanguage = language,
                    ),
                    onContinue: _continue,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

}

class _KalaSetuLogo extends StatelessWidget {
  const _KalaSetuLogo();

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/images/kalasetu_logo.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Text(
          'KalaSetu',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFF370E00),
            fontSize: 38,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _LanguageChoiceCard extends StatelessWidget {
  const _LanguageChoiceCard({
    required this.selectedLanguage,
    required this.languages,
    required this.isRecording,
    required this.onRecordingTap,
    required this.onLanguageChanged,
    required this.onContinue,
    this.isDetecting = false,
  });

  final _Language selectedLanguage;
  final List<_Language> languages;
  final bool isRecording;
  final bool isDetecting;
  final VoidCallback onRecordingTap;
  final ValueChanged<_Language> onLanguageChanged;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 350),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Welcome to KalaSetu',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFF1D1B19),
                fontSize: 28,
                height: 1.15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'अपनी भाषा में बोलें, हम आपके साथ हैं',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF705F58),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 28),
            _VoiceRecordButton(
              isRecording: isRecording,
              onTap: onRecordingTap,
            ),
            const SizedBox(height: 12),
            Text(
              isDetecting
                  ? 'Detecting language…'
                  : isRecording
                      ? 'Listening… tap again when you finish'
                      : 'Tap to tell us your language',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: isRecording || isDetecting
                    ? const Color(0xFF9F3C07)
                    : const Color(0xFF705F58),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'OR CHOOSE A LANGUAGE',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF705F58),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .6,
                ),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<_Language>(
              value: selectedLanguage,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF9F3C07),
              ),
              decoration: _dropdownDecoration(),
              items: languages
                  .map(
                    (language) => DropdownMenuItem(
                      value: language,
                      child: Text(
                        '${language.nativeName}  ·  ${language.name}',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF32302E),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (language) {
                if (language != null) onLanguageChanged(language);
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF9F3C07),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  '${selectedLanguage.continueText}  →',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  InputDecoration _dropdownDecoration() => InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        border: _border(const Color(0xFFE7E1DD)),
        enabledBorder: _border(const Color(0xFFE7E1DD)),
        focusedBorder: _border(const Color(0xFF9F3C07), width: 1.5),
      );

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
}

class _VoiceRecordButton extends StatelessWidget {
  const _VoiceRecordButton({required this.isRecording, required this.onTap});

  final bool isRecording;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: isRecording ? 'Stop recording language' : 'Record your language',
        child: InkResponse(
          onTap: onTap,
          radius: 58,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF9F3C07),
              border: Border.all(color: const Color(0xFFF4DED4), width: 9),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x339F3C07),
                  blurRadius: 18,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(
              isRecording ? Icons.stop_rounded : Icons.mic_none_rounded,
              color: Colors.white,
              size: 31,
            ),
          ),
        ),
      );
}

class _Language {
  const _Language(this.name, this.nativeName, this.localeCode, this.continueText);

  final String name;
  final String nativeName;
  final String localeCode;
  final String continueText;
}
