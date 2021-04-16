import 'package:flutter/material.dart';
//import 'package:foo/Login/login.dart';
import 'router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'dart:io';
import 'package:data_connection_checker/data_connection_checker.dart';

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
      home:Renderer(),
    );
  }
}


class Renderer extends StatefulWidget {
  @override
  _RendererState createState() => _RendererState();
}

class _RendererState extends State<Renderer> {

  Timer timer;
  bool isConnected;

  @override
  void initState(){
    super.initState();
    timer = Timer.periodic(Duration(seconds: 5), (Timer t) => _checkConnectionStatus());
  }

  void _checkConnectionStatus() async{
 bool result = await DataConnectionChecker().hasConnection;  

      if(result == true) {
        setState((){
          isConnected=true;
        });
        print('YAY! Free cute dog pics!');
      } else {
         setState((){
          isConnected=false;
        });
      }
  } 

  @override
  Widget build(BuildContext context) {
    return Container(
      
    );
  }
}