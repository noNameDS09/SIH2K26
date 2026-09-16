import 'package:go_router/go_router.dart';
import '../language_screen.dart';
import '../onboarding_screen.dart';
import '../otp_screen.dart';
import '../screens/screen2_capture.dart';
import '../screens/studio_screen.dart';
import '../screens/live_screen.dart';
import '../screens/pricing_screen.dart';
import '../screens/screen3_intelligence.dart';
import '../screens/screen4_approval.dart';
import '../screens/screen5_outward.dart';

abstract final class AppRoutes {
  static const language     = '/';
  static const otp          = '/otp';
  static const onboarding   = '/onboarding';
  static const capture      = '/capture';
  static const intelligence = '/intelligence';
  static const approval     = '/approval';
  static const distribute   = '/distribute';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.language,
  routes: [
    GoRoute(path: AppRoutes.language,     builder: (ctx, _) => const LanguageScreen()),
    GoRoute(path: AppRoutes.otp,          builder: (ctx, _) => const OtpScreen()),
    GoRoute(path: AppRoutes.onboarding,   builder: (ctx, _) => const OnboardingScreen()),
    GoRoute(path: AppRoutes.capture,      builder: (ctx, _) => const Screen2Capture()),
    GoRoute(path: '/studio',      builder: (ctx, _) => const StudioScreen()),
    GoRoute(path: '/live',        builder: (ctx, _) => const LiveScreen()),
    GoRoute(path: '/pricing',     builder: (ctx, _) => const PricingScreen()),
    GoRoute(path: AppRoutes.intelligence, builder: (ctx, _) => const Screen3Intelligence()),
    GoRoute(path: AppRoutes.approval,     builder: (ctx, _) => const Screen4Approval()),
    GoRoute(path: AppRoutes.distribute,   builder: (ctx, _) => const Screen5Outward()),
  ],
);
