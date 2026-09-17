import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../services/api_service.dart';
import 'theme/ks_colors.dart';
import 'l10n/locale_provider.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  static const _languages = <_Language>[
    _Language(
      'English',
      'English',
      'en',
      'Continue in English',
    ),
    _Language(
      'Hindi',
      'हिन्दी',
      'hi',
      'हिंदी में जारी रखें',
    ),
    _Language(
      'Marathi',
      'मराठी',
      'mr',
      'मराठीत सुरू ठेवा',
    ),
    _Language(
      'Tamil',
      'தமிழ்',
      'ta',
      'தமிழில் தொடரவும்',
    ),
    _Language(
      'Telugu',
      'తెలుగు',
      'te',
      'తెలుగులో కొనసాగించు',
    ),
    _Language(
      'Kannada',
      'ಕನ್ನಡ',
      'kn',
      'ಕನ್ನಡದಲ್ಲಿ ಮುಂದುವರಿಸಿ',
    ),
    _Language(
      'Bengali',
      'বাংলা',
      'bn',
      'বাংলায় চালিয়ে যান',
    ),
    _Language(
      'Gujarati',
      'ગુજરાતી',
      'gu',
      'ગુજરાતીમાં આગળ વધો',
    ),
    _Language(
      'Punjabi',
      'ਪੰਜਾਬੀ',
      'pa',
      'ਪੰਜਾਬੀ ਵਿੱਚ ਜਾਰੀ ਰੱਖੋ',
    ),
    _Language(
      'Malayalam',
      'മലയാളം',
      'ml',
      'മലയാളത്തിൽ തുടരുക',
    ),
    _Language(
      'Assamese',
      'অসমীয়া',
      'as',
      'অসমীয়াত আগবাঢ়ক',
    ),
    _Language(
      'Odia',
      'ଓଡ଼ିଆ',
      'or',
      'ଓଡ଼ିଆରେ ଜାରି ରଖ',
    ),
    _Language(
      'Urdu',
      'اُردُو',
      'ur',
      'اردو میں جاری رکھیں',
    ),
    _Language(
      'Maithili',
      'मैथिली',
      'mai',
      'मैथिलीमे आगू बढ़ू',
    ),
    _Language(
      'Santali',
      'संताली',
      'sat',
      'संतालीरे आगे बढ़',
    ),
    _Language(
      'Kashmiri',
      'कॉशुर',
      'ks',
      'कॉशुरमें जारी रखें',
    ),
    _Language(
      'Nepali',
      'नेपाली',
      'ne',
      'नेपालीमा जारी राख्नुस्',
    ),
    _Language(
      'Sindhi',
      'سنڌي',
      'sd',
      'سنڌيءَ ۾ جاري رکو',
    ),
    _Language(
      'Dogri',
      'डोगरी',
      'doi',
      'डोगरीच जारी रखो',
    ),
    _Language(
      'Manipuri',
      'মৈতৈলোন্',
      'mni',
      'মৈতৈলোন্দা লৈবাক্',
    ),
    _Language(
      'Bodo',
      'बड़ो',
      'brx',
      'बड़ो खोनफ्रनाय',
    ),
    _Language(
      'Sanskrit',
      'संस्कृतम्',
      'sa',
      'संस्कृते अग्रे गच्छ',
    ),
    _Language(
      'Konkani',
      'कोंकणी',
      'kok',
      'कोंकणींत पुडे वच',
    ),
  ];

  _Language _selectedLanguage = _languages.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KsColors.background,

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      22,
                      20,
                      24,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          _buildTopBar(),

                          const SizedBox(height: 30),

                          _buildHero(),

                          const SizedBox(height: 24),

                          _buildVoiceDetector(),

                          const SizedBox(height: 25),

                          _buildLanguageHeader(),

                          const SizedBox(height: 12),

                          _LanguageList(
                            languages: _languages,
                            selectedLanguage: _selectedLanguage,
                            onSelected: (language) {
                              setState(() {
                                _selectedLanguage = language;
                              });
                            },
                          ),

                          const SizedBox(height: 12),

                          _buildLanguageCount(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            _ContinueBar(
              language: _selectedLanguage,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TOP BAR
  // ===========================================================================

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: KsColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: KsColors.border,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/images/kalasetu_logo.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return const Icon(
                  Icons.auto_awesome_rounded,
                  color: KsColors.terracotta,
                  size: 21,
                );
              },
            ),
          ),
        ),

        const SizedBox(width: 11),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KalaSetu',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: KsColors.ink,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'A bridge for Indian artisans',
                style: TextStyle(
                  fontSize: 10,
                  color: KsColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: KsColors.greenSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.language_rounded,
                size: 14,
                color: KsColors.greenDark,
              ),
              SizedBox(width: 5),
              Text(
                'Language',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: KsColors.greenDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // HERO
  // ===========================================================================

  Widget _buildHero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How would you like\nto use KalaSetu?',
          style: TextStyle(
            fontSize: 29,
            height: 1.08,
            fontWeight: FontWeight.w800,
            color: KsColors.ink,
            letterSpacing: -0.7,
          ),
        ),

        const SizedBox(height: 9),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 5),
              width: 4,
              height: 30,
              decoration: BoxDecoration(
                color: KsColors.terracotta,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(width: 10),

            const Expanded(
              child: Text(
                'Choose the language you are most comfortable with. '
                'You can change it later.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: KsColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // VOICE DETECTOR
  // ===========================================================================

  Widget _buildVoiceDetector() {
    return _VoiceLanguageButton(
      onDetected: (code, name) {
        final normalizedCode = code.split('-').first;

        final language = _languages.cast<_Language?>().firstWhere(
              (language) =>
                  language?.localeCode == normalizedCode,
              orElse: () => null,
            );

        if (language != null) {
          setState(() {
            _selectedLanguage = language;
          });
        }
      },
    );
  }

  // ===========================================================================
  // LANGUAGE HEADER
  // ===========================================================================

  Widget _buildLanguageHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select your language',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: KsColors.ink,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Tap any language to select it',
                style: TextStyle(
                  fontSize: 11,
                  color: KsColors.textMuted,
                ),
              ),
            ],
          ),
        ),

        Text(
          '${_languages.length} languages',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: KsColors.terracotta,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // FOOTNOTE
  // ===========================================================================

  Widget _buildLanguageCount() {
    return Row(
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 14,
          color: KsColors.textMuted,
        ),

        const SizedBox(width: 6),

        Expanded(
          child: Text(
            'Your language preference will be used throughout KalaSetu.',
            style: const TextStyle(
              fontSize: 10,
              height: 1.4,
              color: KsColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// LANGUAGE LIST
// =============================================================================

class _LanguageList extends StatelessWidget {
  const _LanguageList({
    required this.languages,
    required this.selectedLanguage,
    required this.onSelected,
  });

  final List<_Language> languages;
  final _Language selectedLanguage;
  final ValueChanged<_Language> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int index = 0; index < languages.length; index++) ...[
          _LanguageButton(
            language: languages[index],
            selected: languages[index] == selectedLanguage,
            onPressed: () => onSelected(languages[index]),
          ),

          if (index != languages.length - 1)
            const SizedBox(height: 8),
        ],
      ],
    );
  }
}

// =============================================================================
// LANGUAGE BUTTON
// =============================================================================

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
    return Semantics(
      button: true,
      selected: selected,
      label: '${language.name}, ${language.nativeName}',
      hint: selected
          ? 'Selected. Double tap to continue.'
          : 'Double tap to select.',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),

        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),

          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,

            constraints: const BoxConstraints(
              minHeight: 68,
            ),

            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 11,
            ),

            decoration: BoxDecoration(
              color: selected
                  ? KsColors.terracottaSoft
                  : KsColors.surface,

              borderRadius: BorderRadius.circular(16),

              border: Border.all(
                color: selected
                    ? KsColors.terracotta
                    : KsColors.border,
                width: selected ? 1.4 : 1,
              ),
            ),

            child: Row(
              children: [
                // Language monogram
                _LanguageBadge(
                  language: language,
                  selected: selected,
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language.nativeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: selected
                              ? KsColors.terracottaDark
                              : KsColors.ink,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        language.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: KsColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),

                  width: 25,
                  height: 25,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? KsColors.terracotta
                        : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? KsColors.terracotta
                          : KsColors.textMuted,
                      width: selected ? 0 : 1.4,
                    ),
                  ),

                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),

                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            key: ValueKey('selected'),
                            size: 16,
                            color: KsColors.white,
                          )
                        : const SizedBox(
                            key: ValueKey('unselected'),
                          ),
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

// =============================================================================
// LANGUAGE BADGE
// =============================================================================

class _LanguageBadge extends StatelessWidget {
  const _LanguageBadge({
    required this.language,
    required this.selected,
  });

  final _Language language;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final label = language.localeCode.toUpperCase();

    return Container(
      width: 42,
      height: 42,

      alignment: Alignment.center,

      decoration: BoxDecoration(
        color: selected
            ? KsColors.surface
            : KsColors.surfaceWarm,
        borderRadius: BorderRadius.circular(13),
      ),

      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: .4,
          color: selected
              ? KsColors.terracotta
              : KsColors.textSecondary,
        ),
      ),
    );
  }
}

// =============================================================================
// CONTINUE BAR
// =============================================================================

class _ContinueBar extends StatelessWidget {
  const _ContinueBar({
    required this.language,
  });

  final _Language language;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        16,
      ),

      decoration: BoxDecoration(
        color: KsColors.background,
        border: Border(
          top: BorderSide(
            color: KsColors.border.withValues(alpha: 0.8),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),

      child: SafeArea(
        top: false,

        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text(
                    'Selected',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: KsColors.textMuted,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    '${language.nativeName} · ${language.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: KsColors.ink,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            SizedBox(
              height: 50,

              child: FilledButton(
                onPressed: () {
                  context
                      .read<LocaleProvider>()
                      .setLocale(
                        Locale(language.localeCode),
                      );

                  context.go('/otp');
                },

                style: FilledButton.styleFrom(
                  backgroundColor: KsColors.terracotta,
                  foregroundColor: KsColors.white,

                  padding: const EdgeInsets.symmetric(
                    horizontal: 19,
                  ),

                  elevation: 0,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),

                child: Row(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    Text(
                      'Continue',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(width: 7),

                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 17,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// DATA
// =============================================================================

class _Language {
  const _Language(
    this.name,
    this.nativeName,
    this.localeCode,
    this.continueText,
  );

  final String name;
  final String nativeName;
  final String localeCode;
  final String continueText;
}

// =============================================================================
// VOICE LANGUAGE DETECTION
// =============================================================================

class _VoiceLanguageButton extends StatefulWidget {
  const _VoiceLanguageButton({
    required this.onDetected,
  });

  final void Function(
    String code,
    String name,
  ) onDetected;

  @override
  State<_VoiceLanguageButton> createState() =>
      _VoiceLanguageButtonState();
}

class _VoiceLanguageButtonState
    extends State<_VoiceLanguageButton> {
  bool _recording = false;
  bool _detecting = false;

  final AudioRecorder _recorder = AudioRecorder();

  final List<Uint8List> _chunks = [];

  StreamSubscription<Uint8List>? _sub;

  @override
  void dispose() {
    _sub?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    _chunks.clear();

    try {
      final hasPermission =
          await _recorder.hasPermission();

      if (!hasPermission) {
        if (mounted) {
          _showMessage(
            'Microphone permission is required.',
          );
        }

        return;
      }

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      _sub = stream.listen(
        (chunk) {
          _chunks.add(
            Uint8List.fromList(chunk),
          );
        },
      );

      if (mounted) {
        setState(() {
          _recording = true;
        });
      }

      Future.delayed(
        const Duration(seconds: 4),
        () {
          if (mounted && _recording) {
            _stop();
          }
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _recording = false;
        });

        _showMessage(
          'Could not access the microphone.',
        );
      }
    }
  }

  Future<void> _stop() async {
    if (!_recording) return;

    try {
      await _recorder.stop();
    } catch (_) {}

    await _sub?.cancel();
    _sub = null;

    if (mounted) {
      setState(() {
        _recording = false;
      });
    }

    if (_chunks.isEmpty) {
      if (mounted) {
        _showMessage(
          'No voice was detected. Please try again.',
        );
      }

      return;
    }

    final wav = _buildWav(_chunks);

    if (mounted) {
      setState(() {
        _detecting = true;
      });
    }

    try {
      final result = await ApiService.detectLanguage(
        bytes: wav,
      );

      if (!mounted) return;

      setState(() {
        _detecting = false;
      });

      widget.onDetected(
        result['language_code'] ?? 'en',
        result['language_name'] ?? 'English',
      );

      _showMessage(
        'Language detected: '
        '${result['language_name'] ?? 'English'}',
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _detecting = false;
      });

      _showMessage(
        'Could not detect the language. Please select it manually.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  static Uint8List _buildWav(
    List<Uint8List> chunks, {
    int sampleRate = 16000,
  }) {
    final pcm = Uint8List.fromList(
      chunks.expand((c) => c).toList(),
    );

    final header = ByteData(44);

    void setStr(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        header.setUint8(
          offset + i,
          value.codeUnitAt(i),
        );
      }
    }

    setStr(0, 'RIFF');
    header.setUint32(
      4,
      36 + pcm.length,
      Endian.little,
    );

    setStr(8, 'WAVE');
    setStr(12, 'fmt ');

    header.setUint32(
      16,
      16,
      Endian.little,
    );

    header.setUint16(
      20,
      1,
      Endian.little,
    );

    header.setUint16(
      22,
      1,
      Endian.little,
    );

    header.setUint32(
      24,
      sampleRate,
      Endian.little,
    );

    header.setUint32(
      28,
      sampleRate * 2,
      Endian.little,
    );

    header.setUint16(
      32,
      2,
      Endian.little,
    );

    header.setUint16(
      34,
      16,
      Endian.little,
    );

    setStr(36, 'data');

    header.setUint32(
      40,
      pcm.length,
      Endian.little,
    );

    final result = Uint8List(
      44 + pcm.length,
    );

    result.setRange(
      0,
      44,
      header.buffer.asUint8List(),
    );

    result.setRange(
      44,
      result.length,
      pcm,
    );

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final bool active = _recording || _detecting;

    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: _detecting
            ? null
            : (_recording ? _stop : _start),

        borderRadius: BorderRadius.circular(18),

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),

          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(
            color: active
                ? KsColors.terracottaSoft
                : KsColors.surfaceWarm,

            borderRadius: BorderRadius.circular(18),

            border: Border.all(
              color: active
                  ? KsColors.terracotta
                  : KsColors.border,
            ),
          ),

          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),

                width: 44,
                height: 44,

                decoration: BoxDecoration(
                  color: active
                      ? KsColors.terracotta
                      : KsColors.surface,
                  shape: BoxShape.circle,
                ),

                child: _detecting
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: KsColors.terracotta,
                        ),
                      )
                    : Icon(
                        _recording
                            ? Icons.stop_rounded
                            : Icons.mic_none_rounded,
                        color: active
                            ? KsColors.white
                            : KsColors.terracotta,
                        size: 21,
                      ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prefer speaking?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: KsColors.ink,
                      ),
                    ),

                    SizedBox(height: 3),

                    Text(
                      'Speak for a few seconds and we’ll detect your language.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        height: 1.35,
                        color: KsColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Text(
                _detecting
                    ? 'Detecting'
                    : _recording
                        ? 'Listening'
                        : 'Try it',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: active
                      ? KsColors.terracottaDark
                      : KsColors.terracotta,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}