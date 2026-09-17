import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../ui/theme/ks_colors.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();

  bool _requested = false;
  bool _busy = false;

  String _notice = '';
  String _error = '';

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  // ===========================================================================
  // REQUEST OTP
  // ===========================================================================

  Future<void> _request() async {
    final phone = _phoneCtrl.text.trim();

    if (phone.length != 10) {
      setState(() {
        _error = 'Enter a valid 10-digit mobile number';
        _notice = '';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _busy = true;
      _error = '';
      _notice = '';
    });

    try {
      final res = await ApiService.requestOtp(phone);

      if (!mounted) return;

      setState(() {
        _requested = true;
        _notice =
            res['label']?.toString() ??
            'Verification code sent';
        _error = '';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Could not send verification code';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // ===========================================================================
  // VERIFY OTP
  // ===========================================================================

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();

    if (code.length < 4) {
      setState(() {
        _error = 'Enter the verification code';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _busy = true;
      _error = '';
    });

    try {
      final ok = await ApiService.verifyOtp(
        _phoneCtrl.text.trim(),
        code,
      );

      if (!mounted) return;

      if (ok) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_authenticated', true);
        final token = ApiService.getToken();
        if (token != null) {
          await prefs.setString('api_token', token);
        }
        if (mounted) context.go('/onboarding');
      } else {
        setState(() {
          _error = 'Invalid verification code';
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Verification failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KsColors.background,

      body: SafeArea(
        child: SingleChildScrollView(
          physics:
              const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              30,
              24,
              30,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildBrandHeader(),

                const SizedBox(height: 52),

                _buildIllustration(),

                const SizedBox(height: 28),

                _buildHeading(),

                const SizedBox(height: 30),

                AnimatedSwitcher(
                  duration:
                      const Duration(milliseconds: 250),
                  child: _requested
                      ? _buildOtpForm()
                      : _buildPhoneForm(),
                ),

                const SizedBox(height: 28),

                _buildSecurityNote(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BRAND HEADER
  // ===========================================================================

  Widget _buildBrandHeader() {
    return Center(
      child: Image.asset(
        'assets/images/kalasetu_logo.png',
        height: 60,
        fit: BoxFit.contain,
      ),
    );
  }

  // ===========================================================================
  // ILLUSTRATION
  // ===========================================================================

  Widget _buildIllustration() {
    return Center(
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          color: KsColors.surfaceWarm,
          shape: BoxShape.circle,
          border: Border.all(
            color: KsColors.peach1,
            width: 2,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: KsColors.surface,
                borderRadius:
                    BorderRadius.circular(19),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: KsColors.terracotta,
                size: 29,
              ),
            ),

            Positioned(
              right: 8,
              top: 9,
              child: Container(
                width: 19,
                height: 19,
                decoration: const BoxDecoration(
                  color: KsColors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: KsColors.white,
                  size: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // HEADING
  // ===========================================================================

  Widget _buildHeading() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          _requested
              ? 'Enter OTP'
              : 'Verify your mobile number',
          style: const TextStyle(
            fontSize: 28,
            height: 1.15,
            fontWeight: FontWeight.w700,
            color: KsColors.ink,
          ),
        ),

        const SizedBox(height: 9),

        Text(
          _requested
              ? 'Enter the 6-digit verification code sent to '
                  '${_phoneCtrl.text.trim()}.'
              : 'We will send you a verification code to securely '
                  'log in to your account.',
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: KsColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // PHONE FORM
  // ===========================================================================

  Widget _buildPhoneForm() {
    return Column(
      key: const ValueKey('phone'),
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Mobile number',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: KsColors.ink,
          ),
        ),

        const SizedBox(height: 8),

        _buildPhoneField(),

        const SizedBox(height: 16),

        _buildPrimaryButton(
          label: 'Send verification code',
          icon: Icons.arrow_forward_rounded,
          onPressed: _busy ? null : _request,
        ),

        if (_error.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildError(),
        ],
      ],
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: KsColors.surface,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: KsColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
            ),
            height: 54,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: KsColors.border,
                ),
              ),
            ),
            child: const Text(
              '+91',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: KsColors.textSecondary,
              ),
            ),
          ),

          Expanded(
            child: TextField(
              controller: _phoneCtrl,
              keyboardType:
                  TextInputType.phone,
              maxLength: 10,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: KsColors.ink,
                letterSpacing: .5,
              ),
              decoration:
                  const InputDecoration(
                hintText: 'Enter mobile number',
                hintStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: KsColors.textMuted,
                ),
                counterText: '',
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(
                  horizontal: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // OTP FORM
  // ===========================================================================

  Widget _buildOtpForm() {
    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _buildNotice(),

        const SizedBox(height: 18),

        const Text(
          'Verification code',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: KsColors.ink,
          ),
        ),

        const SizedBox(height: 8),

        _buildOtpField(),

        if (_error.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildError(),
        ],

        const SizedBox(height: 16),

        _buildPrimaryButton(
          label: 'Verify OTP',
          icon: Icons.arrow_forward_rounded,
          onPressed: _busy ? null : _verify,
        ),

        const SizedBox(height: 13),

        Center(
          child: TextButton(
            onPressed: _busy
                ? null
                : () {
                    setState(() {
                      _requested = false;
                      _error = '';
                      _notice = '';
                    });
                  },
            style: TextButton.styleFrom(
              foregroundColor:
                  KsColors.terracotta,
            ),
            child: const Text(
              'Change mobile number',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpField() {
    return Container(
      decoration: BoxDecoration(
        color: KsColors.surface,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: KsColors.border,
        ),
      ),
      child: TextField(
        controller: _codeCtrl,
        keyboardType:
            TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 8,
          color: KsColors.ink,
        ),
        decoration:
            const InputDecoration(
          hintText: '••••••',
          hintStyle: TextStyle(
            color: KsColors.textMuted,
            letterSpacing: 7,
          ),
          counterText: '',
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(
            vertical: 15,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // NOTICE
  // ===========================================================================

  Widget _buildNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: KsColors.greenSoft,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 17,
            color: KsColors.greenDark,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              _notice.isNotEmpty
                  ? _notice
                  : 'Verification code sent successfully.',
              style: const TextStyle(
                fontSize: 11,
                height: 1.4,
                color: KsColors.greenDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BUTTON
  // ===========================================================================

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final disabled = onPressed == null;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor:
              KsColors.terracotta,
          foregroundColor:
              KsColors.white,
          disabledBackgroundColor:
              KsColors.surfaceMuted,
          disabledForegroundColor:
              KsColors.textMuted,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
        child: AnimatedSwitcher(
          duration:
              const Duration(milliseconds: 150),
          child: disabled && _busy
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color: KsColors.white,
                  ),
                )
              : Row(
                  key: const ValueKey('button'),
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      icon,
                      size: 17,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ===========================================================================
  // ERROR
  // ===========================================================================

  Widget _buildError() {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 16,
          color: KsColors.terracottaDark,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _error,
            style: const TextStyle(
              fontSize: 11,
              height: 1.35,
              color: KsColors.terracottaDark,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SECURITY NOTE
  // ===========================================================================

  Widget _buildSecurityNote() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 13,
            color: KsColors.textMuted,
          ),
          const SizedBox(width: 5),
          Text(
            _requested
                ? 'Never share your verification code'
                : 'Your number is used for secure sign-in',
            style: const TextStyle(
              fontSize: 10,
              color: KsColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}