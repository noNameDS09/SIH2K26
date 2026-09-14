import 'package:go_router/go_router.dart';
import '../screens/screen4_approval.dart';
import '../screens/screen5_outward.dart';

abstract final class AppRoutes {
  static const approval = '/approval';
  static const distribute = '/distribute';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.approval,
  routes: [
    GoRoute(
      path: AppRoutes.approval,
      builder: (context, state) => const Screen4Approval(),
    ),
    GoRoute(
      path: AppRoutes.distribute,
      builder: (context, state) => const Screen5Outward(),
    ),
  ],
);
