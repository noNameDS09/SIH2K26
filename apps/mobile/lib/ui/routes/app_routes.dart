import 'package:go_router/go_router.dart';

// Insiya — Screens 1 & 2
import 'screen1_2_routes.dart';

// Kush — Screens 3 & 4
import 'screen2_3_routes.dart';

// TODO (Person 3): import 'screen5_6_routes.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Insiya — Screens 1 & 2
    ...screen1And2Routes,

    // Kush — Screens 3 & 4
    ...screen2And3Routes,

    // TODO (Person 3): ...screen5And6Routes,
  ],
);
