import 'package:flutter/material.dart';
import 'package:testproj/chat/socket.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart' as pathProvider;
import 'package:testproj/loginscreen.dart';
import 'models.dart';
// import 'package:http/http.dart' as http;
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'models.g.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  Directory directory = await pathProvider.getApplicationDocumentsDirectory();
  Hive.init(directory.path);
  
  //Registering the hive model adapters. Will change this to register the adapters for corresponding boxes only.
  //Eg:"Threads" box is the only box which uses ThreadAdpater
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(ChatMessageAdapter());
  Hive.registerAdapter(ThreadAdapter());
  await Hive.openBox('Threads');
  runApp(MyApp());
NotificationController();
}

class MyApp extends StatelessWidget {


  //Only one subscriber is allowed for a stream at a time. So it is initialized here.
 
  // var controller = NotificationController();

  @override
  Widget build(BuildContext context) {
    final title = 'WebSocket Demo';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: title,
      home: LoginScreen(),
    );
  }
}
