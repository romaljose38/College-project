import 'package:flutter/material.dart';
//import 'package:foo/Login/login.dart';
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
      debugShowCheckedModeBanner: false,
      title: 'Foo Register',
      theme: ThemeData.dark(),
      onGenerateRoute: generateRoute,
      // home:LoginScreen(),
    );
  }
}
