// Routes owned by Kush — Screens 2 & 3.
// Import this file in app_routes.dart and spread into the routes list.

import 'package:go_router/go_router.dart';
import '../screens/screen2_capture.dart';
import '../screens/screen3_intelligence.dart';

final screen2And3Routes = <RouteBase>[
  GoRoute(
    path: '/capture',
    builder: (ctx, state) => const Screen2Capture(),
  ),
  GoRoute(
    path: '/intelligence',
    builder: (ctx, state) => const Screen3Intelligence(),
  ),
];
