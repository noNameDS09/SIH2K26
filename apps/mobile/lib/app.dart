import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'ui/theme/app_theme.dart';
import 'ui/routes/app_routes.dart';
import 'ui/l10n/locale_provider.dart';
import 'services/session_provider.dart';

class KalaSetuApp extends StatelessWidget {
  const KalaSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0.04,
            child: Image.asset('assets/heroes/KS-Hero-transparent.png', fit: BoxFit.cover, repeat: ImageRepeat.repeatY),
          ),
        ),
        MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (_, localeProvider, child) => MaterialApp.router(
          title: 'KalaSetu',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: appRouter,
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
      ],
    );
  }
}
