import 'package:flutter/material.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
class SettingsPage extends StatelessWidget { const SettingsPage({super.key}); @override Widget build(BuildContext context) => Scaffold(backgroundColor: KsColors.background, appBar: AppBar(title: Text('Settings', style: KsTextStyles.section), backgroundColor: KsColors.surface, elevation: 0), body: Center(child: Text('Profile updates, language, large-text, sign-out from /v1/auth/profile + clearSession.'))); }
