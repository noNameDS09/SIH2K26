import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  static const List<Locale> supported = [
    Locale('en'), // English
    Locale('hi'), // Hindi
    Locale('mr'), // Marathi
    Locale('kn'), // Kannada
  ];

  static const Map<String, String> languageNames = {
    'en': 'English',
    'hi': 'हिंदी',
    'mr': 'मराठी',
    'kn': 'ಕನ್ನಡ',
  };
}
