import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/session_provider.dart';
import '../routes/app_routes.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_mock_badge.dart';

/// `00_AGENT_RULES.md`: OTP is keypad-only, default code `123456`, no
/// voice OTP, badge always visible. Real request/verify go through
/// FastAPI (`POST /v1/auth/otp`, `POST /v1/auth/verify`) which falls back
/// to the mock code itself if the server is unreachable.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String? _error;

  Future<void> _sendOtp() async {
    if (_phoneCtrl.text.length < 10) return;
    setState(() { _loading = true; _error = null; });
    await ApiService.requestOtp(_phoneCtrl.text);
    if (!mounted) return;
    setState(() { _otpSent = true; _loading = false; });
  }

  Future<void> _verifyOtp() async {
    setState(() { _loading = true; _error = null; });
    final ok = await ApiService.verifyOtp(_phoneCtrl.text, _otpCtrl.text);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _loading = false;
        _error = 'Invalid OTP. Use 123456 for testing.';
      });
      return;
    }
    final provider = context.read<SessionProvider>();
    provider.isAuthenticated = true;
    unawaited(provider.loadArtisan());
    setState(() => _loading = false);
    context.go(AppRoutes.onboarding);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KsColors.background,
      body: Column(
        children: [
          const KsAppHeader(title: 'Verify Phone'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  Text('Enter your mobile number', style: KsTextStyles.h2),
                  const SizedBox(height: 8),
                  Text('We will send a verification code to confirm your identity.',
                      style: KsTextStyles.body(color: KsColors.textSecondary)),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                    decoration: InputDecoration(
                      prefixText: '+91  ',
                      hintText: '9876543210',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: KsColors.terracotta, width: 2),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  if (!_otpSent) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _phoneCtrl.text.length == 10 && !_loading ? _sendOtp : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KsColors.terracotta,
                          foregroundColor: KsColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _loading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text('Send OTP', style: KsTextStyles.buttonLabel),
                      ),
                    ),
                  ] else ...[
                    Text('OTP sent to +91 ${_phoneCtrl.text}',
                        style: KsTextStyles.body(color: KsColors.terracotta)),
                    const SizedBox(height: 16),
                    // Numeric keypad only — no free-text keyboard, per spec.
                    TextField(
                      controller: _otpCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                      decoration: InputDecoration(
                        hintText: 'Enter 6-digit OTP',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: KsColors.terracotta, width: 2),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: KsTextStyles.caption.copyWith(color: Colors.red)),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _otpCtrl.text.length == 6 && !_loading ? _verifyOtp : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KsColors.terracotta,
                          foregroundColor: KsColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _loading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text('Verify & Continue', style: KsTextStyles.buttonLabel),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() { _otpSent = false; _otpCtrl.clear(); _error = null; }),
                      child: const Text('Change number'),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const KsMockBadge(),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: KsColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: KsColors.textSecondary),
                        SizedBox(width: 8),
                        Text('Test OTP: 123456'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
