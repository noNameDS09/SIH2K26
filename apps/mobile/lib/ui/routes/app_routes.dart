import 'package:go_router/go_router.dart';
import '../language_screen.dart';
import '../onboarding_screen.dart';
import '../screens/otp_screen.dart';
import '../screens/studio_screen.dart';
import '../screens/live_screen.dart';
import '../screens/costing_screen.dart';
import '../screens/pricing_screen.dart';
import '../screens/home_screen.dart';
import '../screens/catalog_screen.dart';
import '../screens/money_screen.dart';
import '../screens/insights_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/screen2_capture.dart';
import '../screens/screen3_intelligence.dart';
import '../screens/screen4_approval.dart';
import '../screens/screen5_outward.dart';

abstract final class AppRoutes {
  static const language     = '/language';
  static const otp          = '/otp';
  static const onboarding   = '/onboarding';
  static const capture      = '/capture';
  static const studio       = '/studio';
  static const live         = '/live';
  static const intelligence = '/intelligence';
  static const costing      = '/costing';
  static const pricing      = '/pricing';
  static const approval     = '/approval';
  static const distribute   = '/distribute';
  static const home         = '/home';
  static const shop         = '/shop';
  static const money        = '/money';
  static const insights     = '/insights';
  static const settings     = '/settings';

  /// Routes reachable without a signed-in artisan.
  static const publicPaths = {language, otp};
}

/// Route table only — the [GoRouter] itself is built in `app.dart` so its
/// `redirect`/`refreshListenable` can share the same [SessionProvider]
/// instance the widget tree uses (see `00_AGENT_RULES.md`: OTP gates
/// everything past language/otp).
final appRoutes = <RouteBase>[
  // ── Auth & onboarding ─────────────────────────────────────────────────
  GoRoute(path: AppRoutes.language,     builder: (ctx, _) => const LanguageScreen()),
  GoRoute(path: AppRoutes.otp,          builder: (ctx, _) => const OtpScreen()),
  GoRoute(path: AppRoutes.onboarding,   builder: (ctx, _) => const OnboardingScreen()),

  // ── Creation flow ──────────────────────────────────────────────────────
  GoRoute(path: AppRoutes.capture,      builder: (ctx, _) => const Screen2Capture()),
  GoRoute(path: AppRoutes.studio,       builder: (ctx, _) => const StudioScreen()),
  GoRoute(path: AppRoutes.live,         builder: (ctx, _) => const LiveScreen()),
  GoRoute(path: AppRoutes.intelligence, builder: (ctx, _) => const Screen3Intelligence()),
  GoRoute(path: AppRoutes.costing,      builder: (ctx, _) => const CostingScreen()),
  GoRoute(path: AppRoutes.pricing,      builder: (ctx, _) => const PricingScreen()),
  GoRoute(path: AppRoutes.approval,     builder: (ctx, _) => const Screen4Approval()),
  GoRoute(path: AppRoutes.distribute,   builder: (ctx, _) => const Screen5Outward()),

  // ── Management ────────────────────────────────────────────────────────
  GoRoute(path: AppRoutes.home,         builder: (ctx, _) => const HomeScreen()),
  GoRoute(path: AppRoutes.shop,         builder: (ctx, _) => const CatalogScreen()),
  GoRoute(path: AppRoutes.money,        builder: (ctx, _) => const MoneyScreen()),
  GoRoute(path: AppRoutes.insights,     builder: (ctx, _) => const InsightsScreen()),
  GoRoute(path: AppRoutes.settings,     builder: (ctx, _) => const SettingsScreen()),
];
