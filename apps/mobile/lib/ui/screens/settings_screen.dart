import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/session_provider.dart';
import '../routes/app_routes.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import '../widgets/ks_app_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KsColors.background,
      body: Column(
        children: [
          KsAppHeader(title: 'Settings', onBack: () => context.go(AppRoutes.home)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Profile section
                _SectionHeader('Profile'),
                _SettingsTile(
                  icon: Icons.person_outline,
                  title: 'Artisan Profile',
                  subtitle: 'Name, cluster, mastery',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.verified_outlined,
                  title: 'KYC Status',
                  subtitle: 'Government ID verification',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: KsColors.paleGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Verified',
                        style: KsTextStyles.label(color: KsColors.deepGreen, size: 9)),
                  ),
                  onTap: () {},
                ),

                const SizedBox(height: 16),
                _SectionHeader('Preferences'),
                _SettingsTile(
                  icon: Icons.language,
                  title: 'App Language',
                  subtitle: 'Change display language',
                  onTap: () => context.go(AppRoutes.language),
                ),
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Order alerts, market updates',
                  onTap: () {},
                ),

                const SizedBox(height: 16),
                _SectionHeader('Marketplace'),
                _SettingsTile(
                  icon: Icons.store_outlined,
                  title: 'ONDC Integration',
                  subtitle: 'Connect your ONDC seller account',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.shopping_bag_outlined,
                  title: 'GeM Integration',
                  subtitle: 'Government e-Marketplace',
                  onTap: () {},
                ),

                const SizedBox(height: 16),
                _SectionHeader('Data & Privacy'),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.delete_outline,
                  title: 'Clear Session Data',
                  onTap: () {
                    context.read<SessionProvider>().reset();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Session data cleared')),
                    );
                  },
                ),

                const SizedBox(height: 16),
                _SectionHeader('About'),
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: 'About KalaSetu',
                  subtitle: 'Version 1.0.0 — SIH 2026 PS-26090',
                  onTap: () {},
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
  final VoidCallback onTap;

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
        trailing: trailing ?? const Icon(Icons.chevron_right, color: KsColors.textSecondary, size: 18),
      ),
    );
  }
}
