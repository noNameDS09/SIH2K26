import 'package:flutter/material.dart';
import 'app.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'ui/routes/app_routes.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  bool isAuth = prefs.getBool('is_authenticated') ?? false;
  final String? token = prefs.getString('api_token');
  
  if (token != null) {
    ApiService.setToken(token);
  } else if (isAuth) {
    // If authenticated but no token, force re-login
    isAuth = false;
    await prefs.setBool('is_authenticated', false);
  }
  String initial = AppRoutes.language;
  if (isAuth && token != null) {
    initial = AppRoutes.home;
  } else if (prefs.getBool('is_authenticated') != null) {
    initial = AppRoutes.otp;
  }
  
  runApp(KalaSetuApp(initialRoute: initial));
}
