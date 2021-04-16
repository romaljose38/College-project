import 'package:flutter/material.dart';
import 'auth/register.dart' as register;
import 'auth/login.dart' as login;
import 'initialscreen.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/register':
      return MaterialPageRoute(builder: (context) => register.RegisterView());
    case '/login':
      return MaterialPageRoute(builder: (context) => login.LoginScreen());
    default:
      return MaterialPageRoute(builder: (context) => Renderer());
  }
}
