import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  static const supported = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (!supported.contains(locale) || _locale == locale) return;
    _locale = locale;
    notifyListeners();
  }
}
