import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

import 'l10n/locale_provider.dart';
import '../services/api_service.dart';
import '../services/wav_utils.dart';

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
  final _player = AudioPlayer();
  final List<Uint8List> _pcmChunks = [];

  @override
  void initState() {
    super.initState();
    // /language runs before OTP, but /v1/speech/tts requires a bearer
    // token — without this, tapping a tile to hear it is a silent 401.
    ApiService.ensurePreviewToken();
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  // Sarvam-supported codes only (10_VOICE_AND_AGENTS.md); the extra tiles in
  // this picker beyond Sarvam's list fall back to Hindi TTS rather than
  // silently failing.
  static const _sarvamCodes = {
    'en': 'en-IN', 'hi': 'hi-IN', 'mr': 'mr-IN', 'ta': 'ta-IN',
    'te': 'te-IN', 'kn': 'kn-IN', 'bn': 'bn-IN', 'gu': 'gu-IN',
    'pa': 'pa-IN', 'ml': 'ml-IN', 'as': 'as-IN', 'or': 'od-IN',
    'ur': 'ur-IN',
  };

  /// Each tile speaks its own name on tap (04_FEATURES_AND_SCREENS.md:
  /// "Tile speaks its own name").
  Future<void> _selectLanguage(_Language language) async {
    setState(() => _selectedLanguage = language);
    final code = _sarvamCodes[language.localeCode] ?? 'hi-IN';
    final bytes = await ApiService.synthesizeSpeech(language.nativeName, code);
    if (bytes != null && mounted) await _player.play(BytesSource(bytes));
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
          final wav = buildWav(_pcmChunks);
          final (transcript, detectedCode) = await ApiService.transcribeAudio(wav, 'unknown');
          if (!mounted) return;
          if (detectedCode != null && detectedCode != 'unknown') {
            // Map BCP-47 to locale code (e.g. mr-IN -> mr)
            final langCode = detectedCode.split('-').first.toLowerCase();
            final match = _languages.where((l) => l.localeCode == langCode).firstOrNull;
            if (match != null) {
              setState(() => _selectedLanguage = match);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Detected: ${match.name} (${match.nativeName})'),
                    duration: const Duration(seconds: 2)),
              );
            } else {
              _showDetectionFailure("Heard '$detectedCode' — not in the list yet.");
            }
          } else if (transcript.isNotEmpty) {
            _showDetectionFailure("Heard you, but couldn't tell the language — try again or pick below.");
          } else {
            _showDetectionFailure("Didn't catch that — check mic permission and try again.");
          }
        } else {
          _showDetectionFailure('No audio captured — try again.');
        }
      } catch (_) {
        if (mounted) _showDetectionFailure('Detection failed — pick your language below.');
      }
      if (mounted) setState(() => _isDetecting = false);
    } else {
      // Ensure the preview token exists before recording — otherwise a
      // fast tap-and-speak can race the auth call.
      await ApiService.ensurePreviewToken();
      if (!mounted) return;
      // Start recording
      _pcmChunks.clear();
      try {
        final hasPermission = await _recorder.hasPermission();
        if (!hasPermission) {
          _showDetectionFailure('Microphone permission denied — pick your language below.');
          return;
        }
        final stream = await _recorder.startStream(
          const RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: 16000, numChannels: 1),
        );
        stream.listen((chunk) => _pcmChunks.add(Uint8List.fromList(chunk)));
        setState(() => _isRecording = true);
        // Auto-stop after 5 seconds — long enough for a short sentence,
        // which Sarvam needs for confident language detection.
        Future.delayed(const Duration(seconds: 5), () {
          if (_isRecording && mounted) _onRecordingTap();
        });
      } catch (_) {
        setState(() => _isRecording = true);
        Future.delayed(const Duration(seconds: 5), () {
          if (_isRecording && mounted) setState(() => _isRecording = false);
        });
      }
    }
  }

  void _showDetectionFailure(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
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
                    onLanguageChanged: _selectLanguage,
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
            SizedBox(
              height: 220,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.6,
                ),
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final language = languages[index];
                  final selected = language == selectedLanguage;
                  return GestureDetector(
                    onTap: () => onLanguageChanged(language),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFFFFF0E8) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? const Color(0xFF9F3C07) : const Color(0xFFE7E1DD),
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected ? const Color(0xFF9F3C07) : Colors.transparent,
                            border: Border.all(
                              color: selected ? const Color(0xFF9F3C07) : const Color(0xFFBDB5B0),
                              width: 1.5,
                            ),
                          ),
                          child: selected
                              ? const Center(child: Icon(Icons.check, size: 9, color: Colors.white))
                              : null,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                language.nativeName,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF32302E),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                              Text(
                                language.name,
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF9F8C84),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  );
                },
              ),
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
