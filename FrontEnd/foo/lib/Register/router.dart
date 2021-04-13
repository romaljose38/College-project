import 'package:flutter/material.dart';
import 'index.dart';
import 'register.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(builder: (context) => IndexView());
    case '/register':
      return MaterialPageRoute(builder: (context) => RegisterView());
    default:
      return MaterialPageRoute(builder: (context) => IndexView());
  }
}
