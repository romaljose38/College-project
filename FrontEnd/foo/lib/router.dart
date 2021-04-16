import 'package:flutter/material.dart';
import 'Register/index.dart' as index;
import 'Register/register.dart' as register;
import 'Login/login.dart' as login;

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(builder: (context) => index.IndexView());
    case '/register':
      return MaterialPageRoute(builder: (context) => register.RegisterView());
    case '/login':
      return MaterialPageRoute(builder: (context) => login.LoginScreen());
    default:
      return MaterialPageRoute(builder: (context) => index.IndexView());
  }
}
