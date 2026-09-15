import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  static const supported = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
    Locale('ta'),
    Locale('te'),
    Locale('kn'),
    Locale('bn'),
    Locale('gu'),
    Locale('pa'),
    Locale('ml'),
    Locale('as'),
    Locale('or'),
    Locale('ur'),
    Locale('mai'),
    Locale('sat'),
    Locale('ks'),
    Locale('ne'),
    Locale('sd'),
    Locale('doi'),
    Locale('mni'),
    Locale('brx'),
    Locale('sa'),
    Locale('kok'),
  ];

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }
}
