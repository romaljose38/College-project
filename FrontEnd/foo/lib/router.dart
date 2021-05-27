import 'package:flutter/material.dart';
import 'package:foo/chat/listscreen.dart';
import 'package:foo/landing_page.dart';
import 'auth/register.dart' as register;
import 'auth/login.dart' as login;
import 'initialscreen.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/register':
      return MaterialPageRoute(builder: (context) => register.RegisterView());
    case '/login':
      return MaterialPageRoute(builder: (context) => login.LoginScreen());
    case '/landingPage':
      return MaterialPageRoute(builder: (context) => LandingPageProxy());
    case '/chatlist':
      return MaterialPageRoute(builder: (_) => ChatListScreen());
    default:
      return MaterialPageRoute(builder: (context) => Renderer());
  }
}
