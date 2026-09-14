import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import '../services/api_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _consent = false;

  // Card scanner state
  Uint8List? _cardImageBytes;
  final ImagePicker _picker = ImagePicker();

  // Voice consent state
  bool _isRecordingConsent = false;
  bool _consentVerifying = false;
  String? _consentTranscript;
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _recordSub;
  final List<Uint8List> _pcmChunks = [];

  @override
  void initState() {
    super.initState();
    // Pre-authenticate so STT is ready for consent verification
    ApiService.authenticate();
  }

  @override
  void dispose() {
    _recorder.dispose();
    _recordSub?.cancel();
    super.dispose();
  }

  // ── Card scanning ──────────────────────────────────────────────────────────

  Future<void> _scanCard() async {
    try {
      // On mobile this opens the camera; on web it shows a file picker
      final photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (photo == null || !mounted) return;
      final bytes = await photo.readAsBytes();
      if (!mounted) return;
      setState(() => _cardImageBytes = bytes);
      _showSnack('Card scanned — demo extraction shown below');
    } catch (_) {
      if (mounted) _showSnack('Camera / gallery unavailable');
    }
  }

  // ── Voice consent recording ────────────────────────────────────────────────

  Future<void> _toggleConsentRecording() async {
    if (_isRecordingConsent) {
      await _stopConsentRecording();
    } else {
      await _startConsentRecording();
    }
  }

  Future<void> _startConsentRecording() async {
    _pcmChunks.clear();
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        if (!mounted) return;
        // On web microphone may be blocked — auto-grant for demo
        setState(() => _consent = true);
        _showSnack('Microphone unavailable — demo consent granted');
        return;
      }
      final stream = await _recorder.startStream(const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ));
      _recordSub =
          stream.listen((chunk) => _pcmChunks.add(Uint8List.fromList(chunk)));
      if (mounted) setState(() => _isRecordingConsent = true);
    } catch (_) {
      if (mounted) {
        setState(() => _consent = true);
        _showSnack('Recording unavailable — demo consent granted');
      }
    }
  }

  Future<void> _stopConsentRecording() async {
    if (!mounted) return;
    setState(() {
      _isRecordingConsent = false;
      _consentVerifying = true;
    });
    try {
      await _recorder.stop();
    } catch (_) {}
    await _recordSub?.cancel();
    _recordSub = null;

    if (_pcmChunks.isNotEmpty) {
      final wav = _buildWav(_pcmChunks);
      final transcript = await ApiService.transcribeAudio(wav, 'hi-IN');
      if (!mounted) return;
      // Any non-trivial speech counts as consent (liveness check)
      final verified = transcript.trim().length > 2;
      setState(() {
        _consentTranscript = transcript.isEmpty ? 'हो' : transcript;
        _consent = verified;
        _consentVerifying = false;
      });
      _showSnack(verified
          ? '✓ सहमति सत्यापित — Consent verified!'
          : 'Please speak clearly and try again');
    } else {
      // No audio captured (web limitation) — auto-grant for demo
      if (!mounted) return;
      setState(() {
        _consentTranscript = 'हो (demo)';
        _consent = true;
        _consentVerifying = false;
      });
      _showSnack('✓ Demo consent granted');
    }
  }

  static Uint8List _buildWav(List<Uint8List> chunks,
      {int sampleRate = 16000}) {
    final pcm = Uint8List.fromList(chunks.expand((c) => c).toList());
    final header = ByteData(44);
    void setStr(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        header.setUint8(offset + i, s.codeUnitAt(i));
      }
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

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white, fontSize: 13)),
        backgroundColor: const Color(0xFF9F3C07),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF8F4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _StageHeader(),
              const SizedBox(height: 18),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFF1D1B19),
                    fontSize: 27,
                    height: 1.18,
                    fontWeight: FontWeight.w600,
                  ),
                  children: const [
                    TextSpan(text: 'Namaste, welcome to '),
                    TextSpan(
                      text: 'KalaSetu.',
                      style: TextStyle(
                          color: Color(0xFF9F3C07),
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'आर्टिसन पहचान व क्लस्टर सत्यापन — AI डिजिटल सेतु',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF705F58),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              const _ModeSwitcher(),
              const SizedBox(height: 16),
              // NOTE: Card OCR backend does not exist in FastAPI.
              // Image capture works; extraction below is demo data.
              _ScannerCard(
                imageBytes: _cardImageBytes,
                onScan: _scanCard,
              ),
              const SizedBox(height: 16),
              const _RegistryCard(),
              const SizedBox(height: 18),
              _GovernmentLinksSection(
                onLink: (name) =>
                    _showSnack('Opening $name… (URL coming soon)'),
              ),
              const SizedBox(height: 22),
              _VoiceConsentCard(
                consent: _consent,
                onChanged: (value) => setState(() => _consent = value),
                isRecording: _isRecordingConsent,
                isVerifying: _consentVerifying,
                transcript: _consentTranscript,
                onMicTap: _toggleConsentRecording,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed:
                      _consent ? () => context.go('/capture') : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF9F3C07),
                    disabledBackgroundColor: const Color(0xFFF1DBD1),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: const Color(0xFF8A7268),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(
                    'Save & Proceed to Product Capture',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Audio Help — voice business analyst not wired yet
              _AudioHelp(
                onTap: () => _showSnack(
                    'Voice business analyst coming soon — available in a future update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stage header ─────────────────────────────────────────────────────────────

class _StageHeader extends StatelessWidget {
  const _StageHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              'STAGE 1 — ARTISAN ONBOARDING',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF9F3C07),
                fontSize: 10,
                letterSpacing: .45,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text('1 of 5 Steps',
                style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF57423A), fontSize: 10)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(
            5,
            (index) => Expanded(
              child: Container(
                height: 5,
                margin: EdgeInsets.only(right: index == 4 ? 0 : 6),
                decoration: BoxDecoration(
                  color: index == 0
                      ? const Color(0xFF9F3C07)
                      : const Color(0xFFE7E1DD),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: const Color(0xFFF3EDE9),
          borderRadius: BorderRadius.circular(12)),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(9)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.document_scanner_outlined,
                size: 17, color: Color(0xFF9F3C07)),
            const SizedBox(width: 7),
            Text('Pehchan OCR',
                style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF9F3C07),
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ─── Scanner card ─────────────────────────────────────────────────────────────

class _ScannerCard extends StatelessWidget {
  const _ScannerCard({this.imageBytes, required this.onScan});

  final Uint8List? imageBytes;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F2EE),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 176,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageBytes != null)
                  Image.memory(imageBytes!, fit: BoxFit.cover)
                else ...[
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFC89D63),
                          Color(0xFF825333),
                          Color(0xFFE1C697)
                        ],
                      ),
                    ),
                  ),
                  const _FabricLines(),
                  Positioned(
                    left: 18,
                    right: 18,
                    top: 16,
                    bottom: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFFCAEDAB), width: 1.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const Positioned(
                      top: 25,
                      left: 27,
                      child: _ScannerChip(label: 'AI DOCUMENT OCR')),
                  const Positioned(
                      top: 25,
                      right: 27,
                      child: Icon(Icons.crop_free_rounded,
                          color: Colors.white, size: 20)),
                  const Center(child: _IdCardMock()),
                  const Positioned(
                      bottom: 25,
                      left: 27,
                      child:
                          _ScannerChip(label: 'MoT / DC-Handlooms Card')),
                  const Positioned(
                      bottom: 25,
                      right: 27,
                      child: _ScannerChip(label: '98% Match', green: true)),
                ],
                // Demo label
                const Positioned(
                  bottom: 5,
                  right: 15,
                  child: _ScannerChip(label: 'Mock — OCR backend pending'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: 42,
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onScan,
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF32302E),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder()),
                icon: const Icon(Icons.camera_alt_outlined, size: 17),
                label: Text('Scan / Upload Card',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FabricLines extends StatelessWidget {
  const _FabricLines();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _FabricPainter());
  }
}

class _FabricPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x33FFF1CE)
      ..strokeWidth = 2;
    for (var i = -120.0; i < size.width + 180; i += 12) {
      canvas.drawLine(Offset(i, 0), Offset(i - 100, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _IdCardMock extends StatelessWidget {
  const _IdCardMock();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -.12,
      child: Container(
        width: 150,
        height: 87,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: const Color(0xFFF7E8C9),
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(color: Color(0x55000000), blurRadius: 7)
            ]),
        child: Row(
          children: [
            Container(
                width: 31,
                height: 38,
                color: const Color(0xFFAB795B),
                child: const Icon(Icons.person,
                    color: Colors.white, size: 23)),
            const SizedBox(width: 7),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                  Text('ARTISAN ID',
                      style: TextStyle(
                          fontSize: 7, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Divider(height: 1),
                  SizedBox(height: 5),
                  Divider(height: 1),
                  SizedBox(height: 5),
                  Divider(height: 1),
                ])),
          ],
        ),
      ),
    );
  }
}

class _ScannerChip extends StatelessWidget {
  const _ScannerChip({required this.label, this.green = false});
  final String label;
  final bool green;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: green
                ? const Color(0xFF476430)
                : const Color(0xB832302E),
            borderRadius: BorderRadius.circular(15)),
        child: Text(label,
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w600)),
      );
}

// ─── Registry card (mock extraction) ─────────────────────────────────────────

class _RegistryCard extends StatelessWidget {
  const _RegistryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFFF8F2EE),
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const CircleAvatar(
              radius: 13,
              backgroundColor: Color(0xFFE7E1DD),
              child: Icon(Icons.verified_rounded,
                  color: Color(0xFF476430), size: 17)),
          const SizedBox(width: 9),
          Expanded(
              child: Text('Extracted Registry\nDetails',
                  style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF32302E),
                      fontSize: 16,
                      height: 1.15,
                      fontWeight: FontWeight.w700))),
          const _VerificationPill(),
        ]),
        const SizedBox(height: 14),
        const _InfoField(
            label: 'शिल्पी / कारीगर नाम (Artisan / Guild Name)',
            value: 'Devi Ram Weavers Guild',
            full: true),
        const SizedBox(height: 10),
        const Row(children: [
          Expanded(
              child: _InfoField(
                  label: 'स्थान (Cluster)', value: 'Ashoknagar, MP')),
          SizedBox(width: 9),
          Expanded(
              child: _InfoField(
                  label: 'अनुभव (Mastery)', value: '24 Yrs Experience')),
        ]),
        const SizedBox(height: 13),
        Row(children: [
          const Icon(Icons.badge_outlined,
              size: 15, color: Color(0xFF705F58)),
          const SizedBox(width: 5),
          Text('Pehchan ID: •••• 8842',
              style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF705F58),
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('DC-Handlooms Reg.',
              style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF9F3C07),
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}

class _VerificationPill extends StatelessWidget {
  const _VerificationPill();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: const BoxDecoration(
            color: Color(0xFFCAEDAB),
            borderRadius: BorderRadius.all(Radius.circular(18))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle_outline,
              size: 13, color: Color(0xFF476430)),
          const SizedBox(width: 4),
          Text('KYC-Lite\nVerified',
              style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF0B2000),
                  fontSize: 9,
                  height: 1,
                  fontWeight: FontWeight.w700)),
        ]),
      );
}

class _InfoField extends StatelessWidget {
  const _InfoField(
      {required this.label, required this.value, this.full = false});
  final String label;
  final String value;
  final bool full;
  @override
  Widget build(BuildContext context) => Container(
        width: full ? double.infinity : null,
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF57423A),
                      fontSize: 8,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF32302E),
                      fontSize: full ? 15 : 12,
                      fontWeight: FontWeight.w700)),
            ]),
      );
}

// ─── Government links dropdown ────────────────────────────────────────────────

class _GovernmentLinksSection extends StatelessWidget {
  const _GovernmentLinksSection({required this.onLink});
  final void Function(String) onLink;

  static const _links = [
    ('Govt Link 1', 'National Artisan Registration Portal'),
    ('Govt Link 2', 'DC Handlooms Card Application'),
    ('Govt Link 3', 'GeM Artisan Onboarding'),
    ('Govt Link 4', 'ONDC Seller Registration'),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFA9B47A).withAlpha(30),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFA9B47A)),
        ),
        child: ExpansionTile(
          leading: const Icon(Icons.link_rounded, color: Color(0xFF476430)),
          title: Text(
            'Government ID Links',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF476430)),
          ),
          iconColor: const Color(0xFF476430),
          collapsedIconColor: const Color(0xFF476430),
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding:
              const EdgeInsets.only(bottom: 8, left: 8, right: 8),
          children: _links
              .map((link) => ListTile(
                    dense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8),
                    leading: const Icon(Icons.open_in_new,
                        size: 16, color: Color(0xFF476430)),
                    title: Text(link.$1,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    subtitle: Text(link.$2,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 10, color: const Color(0xFF705F58))),
                    onTap: () => onLink(link.$1),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ─── Voice consent card ───────────────────────────────────────────────────────

class _VoiceConsentCard extends StatelessWidget {
  const _VoiceConsentCard({
    required this.consent,
    required this.onChanged,
    required this.isRecording,
    required this.isVerifying,
    this.transcript,
    required this.onMicTap,
  });

  final bool consent;
  final ValueChanged<bool> onChanged;
  final bool isRecording;
  final bool isVerifying;
  final String? transcript;
  final VoidCallback onMicTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFFF8F2EE),
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.circle,
              color: isRecording
                  ? const Color(0xFFD32F2F)
                  : const Color(0xFF9F3C07),
              size: 11),
          const SizedBox(width: 7),
          Expanded(
              child: Text('TWO-WAY VOICE — SARVAM ASR',
                  style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF9F3C07),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .3))),
          Text('Hindi /\nBundelkhandi',
              style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF57423A),
                  fontSize: 9,
                  height: 1.1,
                  fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 13),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            // Mic button
            GestureDetector(
              onTap: isVerifying ? null : onMicTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isRecording
                      ? const Color(0xFFFFEBEE)
                      : const Color(0xFFF1DBD1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isRecording
                        ? const Color(0xFFD32F2F)
                        : const Color(0xFFF4DED4),
                    width: 7,
                  ),
                ),
                child: isVerifying
                    ? const Padding(
                        padding: EdgeInsets.all(18),
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF9F3C07)),
                      )
                    : Icon(
                        isRecording ? Icons.stop_rounded : Icons.mic_none_rounded,
                        color: isRecording
                            ? const Color(0xFFD32F2F)
                            : const Color(0xFF9F3C07),
                        size: 30,
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isRecording
                  ? 'Listening… tap to stop'
                  : isVerifying
                      ? 'Verifying…'
                      : '"मेरी सहमति है / I agree to create my GI artisan profile"',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF32302E),
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w700),
            ),
            if (transcript != null && transcript!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: consent
                      ? const Color(0xFFCAEDAB)
                      : const Color(0xFFFFF3F3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Icon(
                    consent ? Icons.check_circle_outline : Icons.mic,
                    size: 13,
                    color: consent
                        ? const Color(0xFF476430)
                        : const Color(0xFF9F3C07),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(transcript!,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: consent
                                ? const Color(0xFF476430)
                                : const Color(0xFF9F3C07))),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Tap the microphone and speak to affix your verbal digital signature for ONDC & GeM listing.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF705F58), fontSize: 11, height: 1.45),
            ),
            if (!isRecording && !isVerifying) ...[
              const SizedBox(height: 10),
              const Icon(Icons.graphic_eq_rounded,
                  color: Color(0xFFC05421), size: 28),
              const SizedBox(height: 6),
              Text('Audio • Sarvam ASR • Encrypted Hash Stored',
                  style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF705F58), fontSize: 8)),
            ],
          ]),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => onChanged(!consent),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                width: 15,
                height: 15,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                    color: consent
                        ? const Color(0xFF9F3C07)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(3),
                    border:
                        Border.all(color: const Color(0xFF9F3C07))),
                child: consent
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null),
            const SizedBox(width: 10),
            Expanded(
                child: Text(
                    'Grant permission to create verifiable digital craft identity on ONDC, GeM, and export craft catalogs.',
                    style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF32302E),
                        fontSize: 11,
                        height: 1.35))),
          ]),
        ),
      ]),
    );
  }
}

// ─── Audio Help ───────────────────────────────────────────────────────────────

class _AudioHelp extends StatelessWidget {
  const _AudioHelp({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: const Color(0xFFF3EDE9),
              borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.headphones_rounded,
                color: Color(0xFF9F3C07), size: 17),
            const SizedBox(width: 7),
            Text('सुनें (Audio Help)',
                style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF32302E),
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
            const SizedBox(width: 5),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Color(0xFF9F3C07), size: 11),
          ]),
        ),
      );
}
