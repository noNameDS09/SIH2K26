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
