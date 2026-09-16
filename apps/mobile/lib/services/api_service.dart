import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import '../models/artisan.dart';
import '../models/listing.dart';
import '../models/prices.dart';
import '../models/trend.dart';
import '../models/advisor_line.dart';
import '../models/live_turn.dart';

/// FastAPI client. Every AI-bearing response is parsed through a model in
/// `lib/models/` so a missing `provenance` block is a visible bug in the UI,
/// never silently dropped. Network/parse failures fall back to clearly
/// mock-tagged data (`mock: true` / `Provenance.source == 'mock'`) rather
/// than hanging — per `05_MAIN_PIPELINE.md` failure table.
class ApiService {
  static final String _base = ApiConfig.base;
  static String? _token;
  static String? uid;
  static String? lang;

  static Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// The real backend requires a bearer token on every `/v1/speech/*` call
  /// (`Depends(require_bearer)`), but `/language` — where a tile speaks its
  /// own name via TTS — runs before the artisan has done OTP. Without a
  /// token that call is a silent 401 ("voice preview does nothing").
  /// This gets a throwaway demo token purely so pre-login previews work;
  /// it is always overwritten by the artisan's own identity the moment
  /// `verifyOtp` succeeds, so it can never clobber a real session (unlike
  /// re-running auth *after* login would).
  static Future<void> ensurePreviewToken() async {
    if (_token != null) return;
    await requestOtp('9999999999');
    await verifyOtp('9999999999', '123456');
  }

  static Map<String, dynamic>? _decodeMap(String body) {
    try {
      final d = jsonDecode(body);
      return d is Map<String, dynamic> ? d : null;
    } catch (_) {
      return null;
    }
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  static Future<bool> requestOtp(String phone) async {
    try {
      final res = await http
          .post(Uri.parse('$_base/v1/auth/otp'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'phone': phone}))
          .timeout(const Duration(seconds: 15));
      return res.statusCode == 200;
    } catch (_) {
      return true; // mock success — OTP is always mocked per spec
    }
  }

  static Future<bool> verifyOtp(String phone, String code) async {
    try {
      final res = await http
          .post(Uri.parse('$_base/v1/auth/verify'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'phone': phone, 'code': code}))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = _decodeMap(res.body);
        _token = data?['token'] as String?;
        uid = data?['uid'] as String?;
        lang = data?['lang'] as String?;
        return _token != null;
      }
    } catch (_) {}
    if (code == '123456') {
      _token = 'demo.mock';
      uid = uid ?? 'demo-uid';
      return true;
    }
    return false;
  }

  static Future<Artisan?> me() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/v1/auth/me'), headers: _authHeaders)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = _decodeMap(res.body);
        return Artisan.tryParse(data?['artisan'] as Map<String, dynamic>?);
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> updateProfile(Map<String, dynamic> profile) async {
    try {
      final res = await http
          .patch(Uri.parse('$_base/v1/auth/profile'),
              headers: _authHeaders, body: jsonEncode(profile))
          .timeout(const Duration(seconds: 15));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Speech: STT (also carries language auto-detect) ─────────────────────

  /// [langCode] may be `'unknown'` to ask the server to auto-detect
  /// (`10_VOICE_AND_AGENTS.md`). Returns `(transcript, detectedLangCode)`.
  static Future<(String, String?)> transcribeAudio(
      Uint8List wavBytes, String langCode) async {
    try {
      final req =
          http.MultipartRequest('POST', Uri.parse('$_base/v1/speech/stt'));
      req.headers['Authorization'] = 'Bearer $_token';
      req.files.add(http.MultipartFile.fromBytes('file', wavBytes,
          filename: 'audio.wav'));
      req.fields['language_code'] = langCode;
      final streamed = await req.send().timeout(const Duration(seconds: 30));
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode == 200) {
        final data = _decodeMap(body);
        return (
          (data?['transcript'] as String?) ?? '',
          data?['detected_language_code'] as String?,
        );
      }
    } catch (_) {}
    return ('', null);
  }

  // ── Speech: TTS ───────────────────────────────────────────────────────────

  static Future<Uint8List?> synthesizeSpeech(
      String text, String langCode) async {
    try {
      final res = await http
          .post(Uri.parse('$_base/v1/speech/tts'),
              headers: _authHeaders,
              body: jsonEncode({'text': text, 'language_code': langCode}))
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final b64 = _decodeMap(res.body)?['audio_b64'] as String?;
        if (b64 != null) return base64Decode(b64);
      }
    } catch (_) {}
    return null;
  }

  // ── Live cataloger (Agent A) ─────────────────────────────────────────────

  /// One turn with the real turn-based cataloger
  /// (`apps/api/.../routers/speech.py:live_turn`) — stateless, JSON,
  /// transcript in / speak out. [session] is the opaque blob from the
  /// previous turn (empty map to start a new session); [transcript] is
  /// empty to just fetch the first question. There is no audio upload and
  /// no `listing_id` at this endpoint — STT happens separately first via
  /// [transcribeAudio], and the finished `listing` is persisted by the
  /// caller once [LiveTurn.done] via `patchListing`.
  static Future<LiveTurn> liveTurn({
    required Map<String, dynamic> session,
    String transcript = '',
    required String langCode,
    String cluster = 'varanasi',
  }) async {
    try {
      final res = await http
          .post(Uri.parse('$_base/v1/speech/live/turn'),
              headers: _authHeaders,
              body: jsonEncode({
                'transcript': transcript,
                'language_code': langCode,
                'cluster': cluster,
                'session': session,
              }))
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final data = _decodeMap(res.body);
        if (data != null) return LiveTurn.fromJson(data);
      }
    } catch (_) {}
    return const LiveTurn(); // caller must hard-fail visibly, not fake JSON
  }

  // ── Image: enhance (studio quality gate) ─────────────────────────────────

  static Future<Map<String, dynamic>?> enhanceImage({
    required Uint8List imageBytes,
    required String listingId,
    String bgPreset = 'linen',
  }) async {
    try {
      final req = http.MultipartRequest(
          'POST', Uri.parse('$_base/v1/images/enhance'));
      req.headers['Authorization'] = 'Bearer $_token';
      req.files.add(http.MultipartFile.fromBytes('file', imageBytes,
          filename: 'product.jpg'));
      req.fields['listing_id'] = listingId;
      req.fields['bg_preset'] = bgPreset;
      final streamed = await req.send().timeout(const Duration(seconds: 60));
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode == 200) return _decodeMap(body);
    } catch (_) {}
    return null; // caller shows original + "waiting for network"
  }

  static Future<Map<String, dynamic>?> uploadOriginal({
    required String listingId,
    required Uint8List imageBytes,
  }) async {
    try {
      final req = http.MultipartRequest(
          'POST', Uri.parse('$_base/v1/listings/$listingId/original'));
      req.headers['Authorization'] = 'Bearer $_token';
      req.files.add(http.MultipartFile.fromBytes('file', imageBytes,
          filename: 'original.jpg'));
      final streamed = await req.send().timeout(const Duration(seconds: 30));
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode == 200) return _decodeMap(body);
    } catch (_) {}
    return null;
  }

  static Future<Uint8List?> fetchBytes(String url) async {
    try {
      final res = await http
          .get(Uri.parse(url),
              headers: {if (_token != null) 'Authorization': 'Bearer $_token'})
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) return res.bodyBytes;
    } catch (_) {}
    return null;
  }

  // ── Listings ──────────────────────────────────────────────────────────────

  static Future<Listing> createListing() async {
    try {
      final res = await http
          .post(Uri.parse('$_base/v1/listings'),
              headers: _authHeaders, body: jsonEncode({}))
          .timeout(const Duration(seconds: 15));
      // Real endpoint has no explicit status_code=201 — default FastAPI 200.
      if (res.statusCode == 200) {
        final data = _decodeMap(res.body);
        if (data != null) return Listing.fromJson(data);
      }
    } catch (_) {}
    return Listing(id: 'listing-${DateTime.now().millisecondsSinceEpoch}');
  }

  static Future<Listing?> getListing(String id) async {
    try {
      final res = await http
          .get(Uri.parse('$_base/v1/listings/$id'), headers: _authHeaders)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = _decodeMap(res.body);
        if (data != null) return Listing.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  static Future<Listing?> patchListing(
      String id, Map<String, dynamic> partial) async {
    try {
      final res = await http
          .patch(Uri.parse('$_base/v1/listings/$id'),
              headers: _authHeaders, body: jsonEncode(partial))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = _decodeMap(res.body);
        if (data != null) return Listing.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  /// The real `GET /v1/listings` takes no query params — it always returns
  /// every listing for this artisan. [status]/[limit] are applied
  /// client-side after the fetch.
  static Future<List<Listing>> listListings({String? status, int? limit}) async {
    try {
      final res = await http
          .get(Uri.parse('$_base/v1/listings'), headers: _authHeaders)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        // Real response is {"items": [...]}, not a bare list.
        final data = _decodeMap(res.body);
        final items = data?['items'];
        if (items is List) {
          var result = items.whereType<Map<String, dynamic>>().map(Listing.fromJson).toList();
          if (status != null) {
            final wanted = status == 'published' ? ListingStatus.published : ListingStatus.draft;
            result = result.where((l) => l.status == wanted).toList();
          }
          if (limit != null && result.length > limit) result = result.sublist(0, limit);
          return result;
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<Prices> priceListing(String id) async {
    try {
      final res = await http
          .post(Uri.parse('$_base/v1/listings/$id/price'), headers: _authHeaders)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        // Real response is {listing_id, prices: {...}, source_label}.
        final data = _decodeMap(res.body);
        return Prices.fromJson(data?['prices'] as Map<String, dynamic>?);
      }
    } catch (_) {}
    return const Prices(); // hasBands == false — UI must show a hard-fail, not a fake price
  }

  static Future<Map<String, dynamic>?> exportListing(
      String id, String channel) async {
    try {
      final res = await http
          .post(Uri.parse('$_base/v1/listings/$id/export'),
              headers: _authHeaders, body: jsonEncode({'channel': channel}))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return _decodeMap(res.body);
    } catch (_) {}
    return {'status': 'scheduled', 'channel': channel, 'mock': true};
  }

  static Future<Map<String, dynamic>?> signListing(String listingId) async {
    try {
      final res = await http
          .post(Uri.parse('$_base/v1/listings/$listingId/sign'), headers: _authHeaders)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return _decodeMap(res.body);
    } catch (_) {}
    return {
      'listing_id': listingId,
      'status': 'published',
      'signature': 'demo-hmac-sha256',
      'qrUrl': null,
      'publicUrl': 'https://kalasetu.demo/v/$listingId',
      'mock': true,
    };
  }

  // ── Trends (Agent C) / Advisor (Agent B) / Insights ──────────────────────

  static Future<Trend?> trends() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/v1/trends/current'), headers: _authHeaders)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return Trend.tryParse(_decodeMap(res.body));
    } catch (_) {}
    return null;
  }

  static Future<AdvisorLine?> advisor() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/v1/advisor'), headers: _authHeaders)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return AdvisorLine.tryParse(_decodeMap(res.body));
    } catch (_) {}
    return null; // silence — never fill with a generic tip
  }

  /// Real `GET /v1/insights` bundles advisor + event history + trend in one
  /// call: `{advisor, history, trends, n, seed}`. `history` is a list of
  /// raw `insight.generated` event records (`{payload: {rule_id, sentence},
  /// ts, ...}`), not pre-shaped `AdvisorLine`s.
  static Future<InsightsBundle> insights() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/v1/insights'), headers: _authHeaders)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = _decodeMap(res.body);
        if (data != null) return InsightsBundle.fromJson(data);
      }
    } catch (_) {}
    return const InsightsBundle();
  }

  static Future<Map<String, dynamic>?> money() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/v1/money'), headers: _authHeaders)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return _decodeMap(res.body);
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> createSale(
      String listingId, int amount) async {
    try {
      final res = await http
          .post(Uri.parse('$_base/v1/sales'),
              headers: _authHeaders,
              body: jsonEncode({'listing_id': listingId, 'amount': amount}))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return _decodeMap(res.body);
    } catch (_) {}
    return null;
  }

  // ── Seed lookups (Pehchan-shaped onboarding registry) ────────────────────

  static Future<List<Map<String, dynamic>>> pehchanLookup(String query) async {
    try {
      final uri = Uri.parse('$_base/v1/seed/pehchan')
          .replace(queryParameters: {'q': query});
      final res = await http.get(uri, headers: _authHeaders).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) return data.whereType<Map<String, dynamic>>().toList();
      }
    } catch (_) {}
    return [];
  }
}
