import 'dart:convert';
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

/// `00_AGENT_RULES.md` compliance fixes made here:
/// - "KYC Status: Verified" was a permanent green claim with nothing behind
///   it — Aadhaar/ID checks are always mocked, so it now carries the
///   standard mock badge instead of asserting a real verification.
/// - The "ONDC Integration" / "GeM Integration" tiles offered to "connect
///   your seller account" — a live-write claim the spec forbids outright.
///   Removed; the mocked, labelled adapters already live on `/distribute`.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _exportListings(BuildContext context) async {
    final listings = await ApiService.listListings();
    final json = const JsonEncoder.withIndent('  ')
        .convert(listings.map((l) => l.toJson()).toList());
    await Clipboard.setData(ClipboardData(text: json));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${listings.length} listing(s) copied as JSON')),
      );
    }
  }

  void _signOut(BuildContext context) {
    context.read<SessionProvider>().signOut();
    context.go(AppRoutes.language);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SessionProvider>();
    return Scaffold(
      backgroundColor: KsColors.background,
      body: Column(
        children: [
          KsAppHeader(title: 'Settings', onBack: () => context.go(AppRoutes.home)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                const _SectionHeader('Profile'),
                _SettingsTile(
                  icon: Icons.person_outline,
                  title: 'Artisan Profile',
                  subtitle: 'Name, cluster, mastery',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.verified_outlined,
                  title: 'Identity Check',
                  subtitle: 'Aadhaar-style scan on onboarding',
                  trailing: const KsMockBadge(),
                  onTap: () {},
                ),

                const SizedBox(height: 16),
                const _SectionHeader('Preferences'),
                _SettingsTile(
                  icon: Icons.language,
                  title: 'App Language',
                  subtitle: 'Change display language',
                  onTap: () => context.go(AppRoutes.language),
                ),
                SwitchListTile(
                  value: provider.speakScreensEnabled,
                  onChanged: (v) => provider.setSpeakScreensEnabled(v),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: KsColors.surface1,
                  activeThumbColor: KsColors.terracotta,
                  title: Text('Speak screens', style: KsTextStyles.bodyMedium(size: 13)),
                  subtitle: Text('Home and Earnings read a line aloud when opened',
                      style: KsTextStyles.caption.copyWith(color: KsColors.textSecondary)),
                ),

                const SizedBox(height: 16),
                const _SectionHeader('Data & Privacy'),
                _SettingsTile(
                  icon: Icons.download_outlined,
                  title: 'Export my listings',
                  subtitle: 'Copy all listings as JSON',
                  onTap: () => _exportListings(context),
                ),
                _SettingsTile(
                  icon: Icons.logout,
                  title: 'Sign out',
                  onTap: () => _signOut(context),
                ),

                const SizedBox(height: 16),
                const _SectionHeader('About'),
                const _SettingsTile(
                  icon: Icons.info_outline,
                  title: 'About KalaSetu',
                  subtitle: 'SIH 2026 · PS-26090',
                  onTap: null,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: KsTextStyles.label(color: KsColors.brown3, size: 10)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: KsColors.surface1,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: KsColors.peach3,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: KsColors.terracotta, size: 18),
        ),
        title: Text(title, style: KsTextStyles.bodyMedium(size: 13)),
        subtitle: subtitle != null
            ? Text(subtitle!, style: KsTextStyles.caption.copyWith(color: KsColors.textSecondary))
            : null,
        trailing: trailing ?? (onTap != null
            ? const Icon(Icons.chevron_right, color: KsColors.textSecondary, size: 18)
            : null),
      ),
    );
  }
}
