import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _base = 'http://localhost:8000';
  static String? _token;

  static Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ── Auth ──────────────────────────────────────────────────────────────────

  static Future<bool> authenticate() async {
    try {
      await http.post(
        Uri.parse('$_base/v1/auth/otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': '9999999999'}),
      );
      final res = await http.post(
        Uri.parse('$_base/v1/auth/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': '9999999999', 'code': '123456'}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _token = data['token'] as String?;
        return _token != null;
      }
    } catch (_) {}
    _token = 'demo.mock';
    return false;
  }

  // ── Speech: STT ───────────────────────────────────────────────────────────

  static Future<String> transcribeAudio(
      Uint8List wavBytes, String langCode) async {
    try {
      final req = http.MultipartRequest(
          'POST', Uri.parse('$_base/v1/speech/stt'));
      req.headers['Authorization'] = 'Bearer $_token';
      req.files.add(http.MultipartFile.fromBytes(
        'file',
        wavBytes,
        filename: 'audio.wav',
      ));
      req.fields['language_code'] = langCode;
      final streamed = await req.send().timeout(const Duration(seconds: 30));
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode == 200) {
        final data = jsonDecode(body) as Map<String, dynamic>;
        return (data['transcript'] as String?) ?? '';
      }
    } catch (_) {}
    return '';
  }

  // ── Speech: TTS ───────────────────────────────────────────────────────────

  static Future<Uint8List?> synthesizeSpeech(
      String text, String langCode) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/v1/speech/tts'),
            headers: _authHeaders,
            body: jsonEncode({'text': text, 'language_code': langCode}),
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final b64 = data['audio_b64'] as String?;
        if (b64 != null) return base64Decode(b64);
      }
    } catch (_) {}
    return null;
  }

  // ── Cataloger: turn-based ────────────────────────────────────────────────

  static Future<Map<String, dynamic>> catalogTurn({
    Map<String, dynamic>? session,
    String? transcript,
    String langCode = 'mr-IN',
    String? cluster,
  }) async {
    try {
      final body = <String, dynamic>{
        'session': session ?? {},
        'language_code': langCode,
        'transcript': transcript,
        'cluster': cluster,
      }..removeWhere((_, v) => v == null);
      final res = await http
          .post(
            Uri.parse('$_base/v1/speech/live/turn'),
            headers: _authHeaders,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return _mockTurn(session, transcript);
  }

  // ── Image: enhance ────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> enhanceImage({
    required Uint8List imageBytes,
    required String listingId,
    String bgPreset = 'linen',
  }) async {
    try {
      final req = http.MultipartRequest(
          'POST', Uri.parse('$_base/v1/images/enhance'));
      req.headers['Authorization'] = 'Bearer $_token';
      req.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'product.jpg',
      ));
      req.fields['listing_id'] = listingId;
      req.fields['bg_preset'] = bgPreset;
      final streamed = await req.send().timeout(const Duration(seconds: 60));
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode == 200) {
        return jsonDecode(body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // ── Auth: OTP ─────────────────────────────────────────────────────────────

  static Future<bool> requestOtp(String phone) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/v1/auth/otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      ).timeout(const Duration(seconds: 15));
      return res.statusCode == 200;
    } catch (_) {
      return true; // mock success
    }
  }

  static Future<String?> verifyOtp(String phone, String code) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/v1/auth/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'code': code}),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _token = data['token'] as String?;
        return _token;
      }
    } catch (_) {}
    if (code == '123456') { _token = 'demo.mock'; return _token; }
    return null;
  }

  // ── Listings: CRUD ────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> createListing() async {
    try {
      final res = await http.post(
        Uri.parse('$_base/v1/listings'),
        headers: _authHeaders,
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 201) return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    return {'id': 'listing-${DateTime.now().millisecondsSinceEpoch}', 'status': 'draft'};
  }

  static Future<Map<String, dynamic>?> getListing(String id) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/v1/listings/$id'), headers: _authHeaders,
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> patchListing(
      String id, Map<String, dynamic> partial) async {
    try {
      final res = await http.patch(
        Uri.parse('$_base/v1/listings/$id'),
        headers: _authHeaders,
        body: jsonEncode(partial),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  static Future<List<Map<String, dynamic>>> listListings() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/v1/listings'), headers: _authHeaders,
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) return List<Map<String, dynamic>>.from(data);
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> priceListing(String id) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/v1/listings/$id/price'), headers: _authHeaders,
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    return {'floor': 3800, 'recommended': 5200, 'ceiling': 7500};
  }

  static Future<Map<String, dynamic>?> exportListing(
      String id, String channel) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/v1/listings/$id/export'),
        headers: _authHeaders,
        body: jsonEncode({'channel': channel}),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    return {'status': 'scheduled', 'channel': channel};
  }

  // ── User: me & advisor ────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> me() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/v1/auth/me'), headers: _authHeaders,
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> advisor() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/v1/advisor'), headers: _authHeaders,
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  // ── Market data ───────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> trends() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/v1/market/trends'), headers: _authHeaders,
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> insights() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/v1/market/insights'), headers: _authHeaders,
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> money() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/v1/money'), headers: _authHeaders,
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> market() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/v1/market'), headers: _authHeaders,
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> createSale(
      String listingId, int amount) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/v1/sales'),
        headers: _authHeaders,
        body: jsonEncode({'listing_id': listingId, 'amount': amount}),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 201) return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    return {'id': 'sale-${DateTime.now().millisecondsSinceEpoch}', 'status': 'created'};
  }

  // ── Multi-lingual: detect language ───────────────────────────────────────

  static Future<String?> detectLanguage(Uint8List audioBytes) async {
    try {
      final req = http.MultipartRequest(
          'POST', Uri.parse('$_base/v1/speech/detect-language'));
      req.headers['Authorization'] = 'Bearer $_token';
      req.files.add(http.MultipartFile.fromBytes(
        'file', audioBytes, filename: 'audio.wav',
      ));
      final streamed = await req.send().timeout(const Duration(seconds: 30));
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode == 200) {
        final data = jsonDecode(body) as Map<String, dynamic>;
        return data['language_code'] as String?;
      }
    } catch (_) {}
    return null; // caller should fall back gracefully
  }

  // ── Multi-lingual: voice action ───────────────────────────────────────────

  static Future<Map<String, dynamic>?> voiceAction({
    String? transcript,
    required String languageCode,
    String? listingId,
  }) async {
    try {
      final body = <String, dynamic>{
        'language_code': languageCode,
        if (transcript != null) 'transcript': transcript,
        if (listingId != null) 'listing_id': listingId,
      };
      final res = await http.post(
        Uri.parse('$_base/v1/speech/voice-action'),
        headers: _authHeaders,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  // ── Multi-lingual: assistant Q&A ─────────────────────────────────────────

  static Future<Map<String, dynamic>?> queryAssistant({
    required String query,
    required String langCode,
    String? listingId,
  }) async {
    try {
      final body = <String, dynamic>{
        'query': query,
        'language_code': langCode,
        if (listingId != null) 'listing_id': listingId,
      };
      final res = await http.post(
        Uri.parse('$_base/v1/assistant/query'),
        headers: _authHeaders,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    // Mock fallback
    return {
      'answer': 'माफ करा, सध्या AI सहाय्यक उपलब्ध नाही. कृपया पुन्हा प्रयत्न करा.',
      'sources': [],
    };
  }

  // ── Multi-lingual: translate listing ─────────────────────────────────────

  static Future<Map<String, dynamic>?> translateListing(
    String id, {
    String? targetLang,
  }) async {
    try {
      final body = <String, dynamic>{
        if (targetLang != null) 'target_lang': targetLang,
      };
      final res = await http.post(
        Uri.parse('$_base/v1/listings/$id/translate'),
        headers: _authHeaders,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  // ── Auth: profile update ─────────────────────────────────────────────────

  static Future<bool> updateProfile(Map<String, dynamic> profile) async {
    try {
      final res = await http
          .patch(
            Uri.parse('$_base/v1/auth/profile'),
            headers: _authHeaders,
            body: jsonEncode(profile),
          )
          .timeout(const Duration(seconds: 15));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Listings: sign & publish ──────────────────────────────────────────────

  static Future<Map<String, dynamic>?> signListing(String listingId) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/v1/listings/$listingId/sign'),
            headers: _authHeaders,
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {
      'listing_id': listingId,
      'status': 'published',
      'signature': 'demo-hmac-sha256',
      'qr_url': 'https://kalasetu.demo/v/$listingId',
    };
  }

  // ── Generic byte fetch (for studio_url, etc.) ────────────────────────────

  static Future<Uint8List?> fetchBytes(String url) async {
    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {if (_token != null) 'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) return res.bodyBytes;
    } catch (_) {}
    return null;
  }

  // ── Mock fallback (demo without backend) ──────────────────────────────────

  static int _mockStep = -1;

  static const List<String> _mockQuestions = [
    'नमस्ते! तुमच्या कारागिरीचे नाव काय आहे?',
    'तुम्ही कोणते साहित्य वापरता?',
    'कोणते विणण्याचे तंत्र वापरता?',
    'हे बनवण्यास किती तास लागतात?',
    'उत्पादनाचा रंग काय आहे?',
  ];

  static Map<String, dynamic> _mockTurn(
      Map<String, dynamic>? session, String? transcript) {
    _mockStep++;
    if (_mockStep >= _mockQuestions.length) {
      _mockStep = -1;
      return {
        'done': true,
        'phase': 'complete',
        'speak': 'तुमची यादी तयार आहे!',
        'session': session ?? {},
        'listing': {
          'title_mr': 'हस्तनिर्मित बांस-जरी कापड',
          'title_en': 'Handcrafted Bamboo-Zari Cotton Fabric',
          'desc_mr':
              'मध्यप्रदेशातील महेश्वर येथे हाताने विणलेले पारंपारिक कापड. जीआय टॅग प्रमाणित.',
          'desc_en':
              'Traditional handwoven fabric from Maheshwar, Madhya Pradesh. GI Tag certified.',
          'prices': {'floor': 3800, 'recommended': 5200, 'ceiling': 7500},
          'cluster': 'Maheshwar, MP',
        },
        'table': [],
      };
    }
    return {
      'done': false,
      'phase': 'interviewing',
      'speak': _mockQuestions[_mockStep],
      'question': _mockQuestions[_mockStep],
      'session': {
        ...(session ?? {}),
        '_step': _mockStep,
        'last_transcript': transcript ?? '',
      },
    };
  }

  static void resetMock() => _mockStep = -1;
}
