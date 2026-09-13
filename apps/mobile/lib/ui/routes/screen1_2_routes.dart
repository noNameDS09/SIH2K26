// Routes owned by Insiya — Screens 1 & 2 (Language + Onboarding).
import 'package:go_router/go_router.dart';
import '../language_screen.dart';
import '../onboarding_screen.dart';

final screen1And2Routes = <RouteBase>[
  GoRoute(
    path: '/',
    builder: (ctx, state) => const LanguageScreen(),
  ),
  GoRoute(
    path: '/onboarding',
    builder: (ctx, state) => const OnboardingScreen(),
  ),
];
