import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _phoneCtrl = TextEditingController(text: '9999999999');
  final TextEditingController _codeCtrl = TextEditingController(text: '123456');
  bool _requested = false;
  bool _busy = false;
  String _notice = '';
  String _error = '';

  Future<void> _request() async {
    setState(() => _busy = true);
    try {
      final res = await ApiService.requestOtp(_phoneCtrl.text.trim());
      setState(() {
        _requested = true;
        _notice = res['label'] ?? 'Code requested';
        _error = '';
      });
    } catch (e) {
      setState(() => _error = 'Could not request code');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    if (_codeCtrl.text.length < 4) {
      setState(() => _error = 'Enter code');
      return;
    }
    setState(() => _busy = true);
    try {
      final ok = await ApiService.verifyOtp(
        _phoneCtrl.text.trim(),
        _codeCtrl.text.trim(),
      );
      if (ok && mounted) {
        context.go('/onboarding');
      } else {
        setState(() => _error = 'Invalid code');
      }
    } catch (e) {
      setState(() => _error = 'Verification failed');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF8F4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            children: [
              Text('OTP', style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.w600, color: const Color(0xFF1D1B19))),
              const SizedBox(height: 12),
              if (!_requested) ...[
                TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
                const SizedBox(height: 16),
                FilledButton(onPressed: _request, child: const Text('Request code')),
              ] else ...[
                TextField(controller: _codeCtrl, decoration: const InputDecoration(labelText: 'Code')),
                const SizedBox(height: 8),
                Text(_notice, style: const TextStyle(color: Color(0xFF9F3C07))),
                const SizedBox(height: 12),
                FilledButton(onPressed: _verify, child: const Text('Verify')),
              ],
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_error, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
