import 'package:go_router/go_router.dart';
import '../language_screen.dart';
import '../onboarding_screen.dart';
import '../screens/screen2_capture.dart';
import '../screens/screen2_5_studio.dart';
import '../screens/screen3_5_live_catalog.dart';
import '../screens/screen2_5_pricing.dart';
import '../screens/screen3_intelligence.dart';
import '../screens/screen4_approval.dart';
import '../screens/screen5_outward.dart';
import '../screens/management/shop.dart';
import '../screens/management/money.dart';
import '../screens/management/insights.dart';
import '../screens/management/settings.dart';

abstract final class AppRoutes {
  static const language      = '/';
  static const onboarding    = '/onboarding';
  static const capture       = '/capture';
  static const studio        = '/studio';
  static const live          = '/live';
  static const intelligence  = '/intelligence';
  static const pricing       = '/pricing';
  static const approval      = '/approval';
  static const distribute    = '/distribute';
  static const shop          = '/shop';
  static const money         = '/money';
  static const insights      = '/insights';
  static const settings      = '/settings';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.language,
  routes: [
    GoRoute(path: AppRoutes.language,     builder: (ctx, _) => const LanguageScreen()),
    GoRoute(path: AppRoutes.onboarding,   builder: (ctx, _) => const OnboardingScreen()),
    GoRoute(path: AppRoutes.capture,      builder: (ctx, _) => const Screen2Capture()),
    GoRoute(path: AppRoutes.studio,       builder: (ctx, _) => const ScreenStudio()),
    GoRoute(path: AppRoutes.live,         builder: (ctx, _) => const LiveCatalogPage()),
    GoRoute(path: AppRoutes.intelligence, builder: (ctx, _) => const Screen3Intelligence()),
    GoRoute(path: AppRoutes.pricing,      builder: (ctx, _) => const PricingPage()),
    GoRoute(path: AppRoutes.approval,     builder: (ctx, _) => const Screen4Approval()),
    GoRoute(path: AppRoutes.distribute,   builder: (ctx, _) => const Screen5Outward()),
    GoRoute(path: AppRoutes.shop,          builder: (ctx, _) => const CatalogPage()),
    GoRoute(path: AppRoutes.money,         builder: (ctx, _) => const MoneyPage()),
    GoRoute(path: AppRoutes.insights,      builder: (ctx, _) => const InsightsPage()),
    GoRoute(path: AppRoutes.settings,       builder: (ctx, _) => const SettingsPage()),
  ],
);
