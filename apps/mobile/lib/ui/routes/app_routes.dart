// ─── KalaSetu App Router ───────────────────────────────────────────────────────
//
// MERGE GUIDE (for teammates):
//   1. Add your route file import below (one import per person).
//   2. Spread your routes list inside GoRouter's `routes:` array.
//   3. Update initialLocation if the landing screen changes.
//   Each person owns their own route file → zero merge conflicts on screen files.
// ──────────────────────────────────────────────────────────────────────────────

import 'package:go_router/go_router.dart';

// Kush — Screens 2 & 3
import 'screen2_3_routes.dart';

// TODO (Person 1 — Insiya): import 'screen1_6_routes.dart';
// TODO (Person 3): import 'screen4_5_routes.dart';

final appRouter = GoRouter(
  initialLocation: '/capture', // change to '/language' after Screen 1 is merged
  routes: [
    // Kush — Screens 2 & 3
    ...screen2And3Routes,

    // TODO (Person 1 — Insiya): ...screen1And6Routes,
    // TODO (Person 3): ...screen4And5Routes,
  ],
);
