import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'initialscreen.dart';
import 'router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart' as pathProvider;
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:foo/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Directory directory = await pathProvider.getApplicationDocumentsDirectory();
  Hive.init(directory.path);

  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(ChatMessageAdapter());
  Hive.registerAdapter(ThreadAdapter());
  Hive.registerAdapter(FeedAdapter());
  Hive.registerAdapter(PostAdapter());

  await Hive.openBox('Threads');
  await Hive.openBox('Feed');
  SharedPreferences prefs = await SharedPreferences.getInstance();

  await Firebase.initializeApp();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  SharedPreferences prefs;

  MyApp({this.prefs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Foo Register',
      // theme: ThemeData.dark(),
      onGenerateRoute: generateRoute,
      home: Renderer(prefs: prefs),
      // home: AudioPlayerP(),
    );
  }
}
