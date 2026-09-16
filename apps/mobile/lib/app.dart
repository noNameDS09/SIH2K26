import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'ui/theme/app_theme.dart';
import 'ui/routes/app_routes.dart';
import 'ui/l10n/locale_provider.dart';
import 'services/session_provider.dart';

class KalaSetuApp extends StatefulWidget {
  const KalaSetuApp({super.key});

  @override
  State<KalaSetuApp> createState() => _KalaSetuAppState();
}

class _KalaSetuAppState extends State<KalaSetuApp> {
  final _session = SessionProvider();
  late final GoRouter _router = GoRouter(
    initialLocation: AppRoutes.language,
    refreshListenable: _session,
    // `00_AGENT_RULES.md`: OTP gates everything past language/otp.
    redirect: (context, state) {
      final loggedIn = _session.isAuthenticated;
      final atPublicPath = AppRoutes.publicPaths.contains(state.matchedLocation);
      if (!loggedIn && !atPublicPath) return AppRoutes.language;
      return null;
    },
    routes: appRoutes,
  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider.value(value: _session),
      ],
      child: Consumer<LocaleProvider>(
        builder: (_, localeProvider, child) => MaterialApp.router(
          title: 'KalaSetu',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: _router,
          locale: localeProvider.locale,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: LocaleProvider.supported,
          builder: (ctx, widget) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: widget!,
            ),
          ),
        ),
      ),
    );
  }
}
