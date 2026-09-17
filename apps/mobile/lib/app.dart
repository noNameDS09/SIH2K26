import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'ui/theme/app_theme.dart';
import 'ui/routes/app_routes.dart';
import 'ui/l10n/locale_provider.dart';
import 'services/session_provider.dart';

class KalaSetuApp extends StatelessWidget {
  final String initialRoute;
  
  const KalaSetuApp({super.key, this.initialRoute = AppRoutes.language});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (_, localeProvider, child) => MaterialApp.router(
          title: 'KalaSetu',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: getAppRouter(initialRoute),
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
