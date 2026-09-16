import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'api_service.dart';
import 'wav_utils.dart';
import '../models/live_turn.dart';
import '../models/provenance.dart';

/// Cataloger + capture session state for the current listing.
///
/// NOTE: per the plan's A4 split this will eventually separate into
/// `SessionProvider` (auth/artisan only) + `ListingDraftProvider` (one
/// current `listingId`) + `VoiceService` (recorder/player). That split was
/// deliberately deferred (touching every pipeline screen at once was judged
/// higher-risk than the win); this class keeps one unified surface instead.
/// Internals talk to the REAL `apps/api` contract (verified by reading the
/// actual FastAPI routers/engines, not the aspirational spec) — the
/// cataloger in particular is a stateless, transcript-based turn endpoint,
/// not an audio-per-turn one. `listingId` is always server-issued, never
/// client-generated (`00_AGENT_RULES.md`).
class SessionProvider extends ChangeNotifier {
  // ── Auth ──────────────────────────────────────────────────────────────────
  bool isAuthenticated = false;

  /// The artisan's cluster, used as the cataloger's pricing/trend context.
  /// Populated opportunistically from `/v1/auth/me`; 'varanasi' is the
  /// server's own default and a safe fallback.
  String cluster = 'varanasi';

  /// Gates auto-TTS on home/money (`/settings` toggle). Manual "listen"
  /// buttons elsewhere are unaffected — this only controls speech the app
  /// initiates on its own.
  bool speakScreensEnabled = true;

  void setSpeakScreensEnabled(bool value) {
    speakScreensEnabled = value;
    notifyListeners();
  }

  void signOut() {
    isAuthenticated = false;
    reset();
  }

  // ── Catalog session ───────────────────────────────────────────────────────
  /// Opaque blob round-tripped with the server on every turn
  /// (`CatalogerSession.to_dict()` server-side) — contains per-slot
  /// raw/value/confirmed/provenance, which is what the live-screen
  /// checklist reads.
  Map<String, dynamic> _catalogSession = {};
  Map<String, dynamic> get catalogSlots =>
      (_catalogSession['slots'] as Map?)?.cast<String, dynamic>() ?? const {};

  /// interviewing | confirming | copy | complete — the server's
  /// `CatalogerSession.phase`. `confirming` means the current question is
  /// actually a reread asking "theek hai / galat", not a new question.
  String get catalogPhase => _catalogSession['phase'] as String? ?? 'interviewing';
  bool get isConfirmingSlot => catalogPhase == 'confirming';

  String? currentQuestion;
  String? lastTranscript;
  String? lastSpokenText;
  bool isDone = false;
  Map<String, dynamic>? listing;
  List<Map<String, dynamic>> table = const [];

  // ── Recording ─────────────────────────────────────────────────────────────
  bool isLoading = false;
  bool isRecording = false;
  String? _statusMessage;
  String? get statusMessage => _statusMessage;

  final AudioRecorder _recorder = AudioRecorder();
  final List<Uint8List> _pcmChunks = [];
  StreamSubscription<Uint8List>? _recordSub;

  // ── Playback ──────────────────────────────────────────────────────────────
  bool isPlayingAudio = false;
  final AudioPlayer _player = AudioPlayer();

  // ── Image ──────────────────────────────────────────────────────────────────
  Uint8List? capturedImageBytes;
  Uint8List? enhancedImageBytes;
  bool isEnhancing = false;
  String? listingId;
  /// True only when the server ran the quality gate and rejected the
  /// studio image (ΔE > 2.0) — the original is kept, never a bad mask
  /// (`09_IMAGE_PIPELINE.md`).
  bool enhanceRejected = false;

  /// True when the server was unreachable and this is a placeholder, not
  /// a real gate result — distinct from [enhanceRejected] so the UI can
  /// say "waiting for network" instead of implying a real ΔE failure.
  bool enhanceOffline = false;
  double? imageEnhanceDeltaE;
  Provenance? enhanceProvenance;

  /// One of the six spec-bundled presets (`09_IMAGE_PIPELINE.md`):
  /// white, linen, beige, slate, jute, wood. Linen is the textile default.
  String _currentBgPreset = 'linen';

  SessionProvider() {
    _player.onPlayerStateChanged.listen((state) {
      isPlayingAudio = state == PlayerState.playing;
      notifyListeners();
    });
  }

  /// Called once after a successful OTP verify (not an auth call itself —
  /// that would silently clobber whichever phone the artisan actually
  /// logged in with). Just tries to learn the artisan's cluster.
  Future<void> loadArtisan() async {
    final artisan = await ApiService.me();
    if (artisan?.cluster != null) cluster = artisan!.cluster!;
  }

  Future<void> _ensureListing() async {
    if (listingId != null) return;
    final created = await ApiService.createListing();
    listingId = created.id;
  }

  // ── Recording lifecycle ───────────────────────────────────────────────────

  Future<void> startRecording() async {
    if (isRecording || isLoading) return;
    _pcmChunks.clear();
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        _setStatus('माइक परवानगी नाही');
        return;
      }
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );
      _recordSub = stream.listen(
        (chunk) => _pcmChunks.add(Uint8List.fromList(chunk)),
        onError: (_) {},
      );
      isRecording = true;
      notifyListeners();
    } catch (_) {
      isRecording = true; // allow toggle even if real recording fails
      notifyListeners();
    }
  }

  /// Stops recording and returns the raw WAV bytes without submitting to
  /// the Live cataloger — used by [KsVoiceCommandSheet], which only needs
  /// a transcript to match against the fixed command grammar.
  Future<Uint8List?> stopRecordingRaw() async {
    if (!isRecording) return null;
    isRecording = false;
    notifyListeners();
    try {
      await _recorder.stop();
    } catch (_) {}
    await _recordSub?.cancel();
    _recordSub = null;
    if (_pcmChunks.isEmpty) return null;
    return buildWav(_pcmChunks);
  }

  /// Stops recording, transcribes it (`POST /v1/speech/stt`), then sends
  /// that transcript to the turn-based cataloger (`POST
  /// /v1/speech/live/turn`) — the real endpoint takes JSON transcript +
  /// session, not raw audio (`apps/api/.../routers/speech.py`).
  Future<void> stopRecordingAndSubmit({String langCode = 'mr-IN'}) async {
    if (!isRecording) return;
    isRecording = false;
    _setLoading(true, 'ऐकत आहे…');

    try {
      await _recorder.stop();
    } catch (_) {}
    await _recordSub?.cancel();
    _recordSub = null;

    if (_pcmChunks.isEmpty) {
      _setLoading(false, null);
      return;
    }
    final wav = buildWav(_pcmChunks);
    _setStatus('उलट अनुवाद करत आहे…');
    final (transcript, _) = await ApiService.transcribeAudio(wav, langCode);
    lastTranscript = transcript.isEmpty ? null : transcript;
    _setStatus('माहिती नोंदवत आहे…');
    await _runTurn(transcript, langCode);
    _setLoading(false, null);
  }

  /// Typed fallback (spec: "text is fallback" after voice-first OTP).
  Future<void> submitTypedText(String text, {String langCode = 'mr-IN'}) async {
    if (isLoading) return;
    _setLoading(true, 'माहिती नोंदवत आहे…');
    lastTranscript = text;
    await _runTurn(text, langCode);
    _setLoading(false, null);
  }

  /// Fetches just the first question without submitting anything — call
  /// once when `/live` opens so `currentQuestion` isn't empty.
  Future<void> startCatalogSession({String langCode = 'mr-IN'}) async {
    if (currentQuestion != null || isLoading) return;
    _setLoading(true, null);
    await _runTurn('', langCode);
    _setLoading(false, null);
  }

  Future<void> _runTurn(String transcript, String langCode) async {
    // The server's confirm/reject classifier requires the WHOLE folded
    // transcript to exactly equal a fixed phrase ("theek hai", "haan", …).
    // Real STT output is noisier ("haan, sahi hai", "yes that's correct"),
    // so it falls through to "answer" and re-captures the same slot —
    // the reported "asks the same question again" loop. While confirming
    // a slot, normalise a loosely-matching transcript to the exact phrase
    // the classifier expects; only the raw transcript is shown to the user.
    final toSend = isConfirmingSlot ? (_normalizeConfirmPhrase(transcript) ?? transcript) : transcript;
    final turn = await ApiService.liveTurn(
      session: _catalogSession,
      transcript: toSend,
      langCode: langCode,
      cluster: cluster,
    );
    _catalogSession = turn.session;
    currentQuestion = turn.reread ?? turn.question;
    isDone = turn.done;
    table = turn.table;
    if (isDone && turn.listing != null) {
      await _persistCatalogerListing(turn.listing!);
    }
    notifyListeners();
  }

  static const _confirmWords = ['theek', 'haan', 'ha', 'yes', 'ok', 'okay', 'correct', 'ठीक', 'हो', 'होय', 'हाँ', 'हां', 'बरोबर', 'सही'];
  static const _rejectWords = ['galat', 'nahin', 'nahi', 'no', 'wrong', 'गलत', 'चुकीचे', 'नाही', 'नको'];
  static const _repeatWords = ['phir se', 'peeche', 'repeat', 'again', 'परत', 'पुन्हा'];

  /// Loose contains-match against the server's own confirm/reject/repeat
  /// vocabulary (`engines/cataloger.py`); returns the exact canonical
  /// phrase the server's classifier accepts, or null if nothing matched.
  String? _normalizeConfirmPhrase(String transcript) {
    final folded = transcript.trim().toLowerCase();
    if (folded.isEmpty) return null;
    if (_confirmWords.any(folded.contains)) return 'theek hai';
    if (_rejectWords.any(folded.contains)) return 'galat';
    if (_repeatWords.any(folded.contains)) return 'phir se';
    return null;
  }

  /// Explicit "✓ Correct" action — bypasses STT ambiguity entirely by
  /// sending the canonical confirm phrase directly.
  Future<void> confirmSlot({String langCode = 'mr-IN'}) async {
    if (isLoading) return;
    _setLoading(true, null);
    await _runTurn('theek hai', langCode);
    _setLoading(false, null);
  }

  /// Explicit "✗ Redo" action — repairs the current slot.
  Future<void> rejectSlot({String langCode = 'mr-IN'}) async {
    if (isLoading) return;
    _setLoading(true, null);
    await _runTurn('galat', langCode);
    _setLoading(false, null);
  }

  /// The finished cataloger `listing` is wrapped as `{value, provenance}`
  /// per field — flatten it and PATCH it onto the SAME draft `listingId`
  /// created back at capture (the cataloger session itself has no concept
  /// of a listing id; persistence is the client's job).
  Future<void> _persistCatalogerListing(Map<String, dynamic> wrapped) async {
    await _ensureListing();
    final flat = flattenCatalogerListing(wrapped);
    final updated = await ApiService.patchListing(listingId!, flat);
    listing = updated?.toJson() ?? {'id': listingId, ...flat};
  }

  // ── TTS + audio playback ──────────────────────────────────────────────────

  Future<void> speakText(String text, {String langCode = 'mr-IN'}) async {
    if (isPlayingAudio) {
      await _player.stop();
      return;
    }
    lastSpokenText = text;
    final bytes = await ApiService.synthesizeSpeech(text, langCode);
    if (bytes != null) {
      await _player.play(BytesSource(bytes));
    }
  }

  // ── Image capture + enhance ───────────────────────────────────────────────

  Future<void> setCapturedImage(Uint8List bytes) async {
    capturedImageBytes = bytes;
    enhancedImageBytes = null;
    notifyListeners();
    await _ensureListing();
    unawaited(ApiService.uploadOriginal(listingId: listingId!, imageBytes: bytes));
    _enhanceInBackground(bytes);
  }

  /// Re-enhances the already-captured image with a different background preset.
  Future<void> reEnhanceWithPreset({required String preset}) async {
    if (capturedImageBytes == null) return;
    _currentBgPreset = preset;
    await _enhanceInBackground(capturedImageBytes!, bgPreset: preset);
  }

  /// Stores the artisan's explicit price choice separately from the AI
  /// recommendation so the approval card can clearly use the override.
  void setListedPrice(int price) {
    final currentListing = listing ?? <String, dynamic>{};
    final currentPrices = currentListing['prices'];
    final prices = <String, dynamic>{
      if (currentPrices is Map) ...currentPrices,
      'listed': price,
      'override': true,
    };
    listing = <String, dynamic>{...currentListing, 'prices': prices};
    notifyListeners();
  }

  void updateListing(Map<String, dynamic> data) {
    listing = data;
    notifyListeners();
  }

  Future<void> _enhanceInBackground(Uint8List bytes, {String? bgPreset}) async {
    isEnhancing = true;
    enhanceRejected = false;
    enhanceOffline = false;
    notifyListeners();
    await _ensureListing();
    final id = listingId!;
    // Run API call and minimum animation time in parallel
    final results = await Future.wait([
      ApiService.enhanceImage(
        imageBytes: bytes,
        listingId: id,
        bgPreset: bgPreset ?? _currentBgPreset,
      ),
      Future.delayed(const Duration(seconds: 3)),
    ]);
    final result = results[0] as Map<String, dynamic>?;
    isEnhancing = false;
    if (result != null) {
      // 09_IMAGE_PIPELINE.md: deltaE > 2.0 -> reject studio, keep original.
      final rejected = result['rejected'] == true || result['accepted'] == false;
      enhanceRejected = rejected;
      enhanceOffline = false;
      enhanceProvenance = Provenance.tryParse(result['provenance']);
      imageEnhanceDeltaE = (result['deltaE'] as num? ?? result['delta_e'] as num?)?.toDouble();
      if (rejected) {
        enhancedImageBytes = null; // never show a bad mask as the studio result
      } else {
        final studioUrl = result['studioUrl'] as String? ?? result['studio_url'] as String?;
        enhancedImageBytes = studioUrl != null
            ? (await ApiService.fetchBytes(studioUrl)) ?? bytes
            : bytes;
      }
    } else {
      // Backend offline — keep original, tell the user (05_MAIN_PIPELINE failure table)
      enhancedImageBytes = null;
      enhanceOffline = true;
      enhanceRejected = false;
      enhanceProvenance = null;
      imageEnhanceDeltaE = null;
    }
    notifyListeners();
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void reset() {
    _catalogSession = {};
    currentQuestion = null;
    lastTranscript = null;
    isDone = false;
    listing = null;
    table = const [];
    capturedImageBytes = null;
    enhancedImageBytes = null;
    enhanceRejected = false;
    enhanceOffline = false;
    enhanceProvenance = null;
    imageEnhanceDeltaE = null;
    listingId = null;
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _setLoading(bool loading, String? status) {
    isLoading = loading;
    _statusMessage = status;
    notifyListeners();
  }

  void _setStatus(String? status) {
    _statusMessage = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }
}
