import 'package:flutter/material.dart';
import 'Register/router.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Foo Register',
      theme: ThemeData.dark(),
      onGenerateRoute: generateRoute,
    );
  }
}
