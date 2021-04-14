import 'package:flutter/material.dart';
import 'Register/router.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
