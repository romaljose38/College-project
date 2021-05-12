import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:foo/chat/listscreen.dart';
import 'package:foo/notification_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'initialscreen.dart';
import 'router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart' as pathProvider;
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:foo/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

Future<dynamic> handleEntry(String payload) async {
  await MyApp._key.currentState
      .push(MaterialPageRoute(builder: (context) => ChatListScreen()));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Directory directory = await pathProvider.getApplicationDocumentsDirectory();
  Hive.init(directory.path);

  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(ChatMessageAdapter());
  Hive.registerAdapter(ThreadAdapter());
  Hive.registerAdapter(FeedAdapter());
  Hive.registerAdapter(PostAdapter());
  Hive.registerAdapter(NotificationTypeAdapter());
  Hive.registerAdapter(NotificationsAdapter());

  await Hive.openBox('Threads');
  await Hive.openBox('Feed');
  await Hive.openBox('Notifications');
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString("curUser", "");
  await Firebase.initializeApp();
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print(message.data);
    print(message.messageType);
    showNotification(message.data['message'], message.data['username']);
  });
  // FirebaseMessaging.onBackgroundMessage((RemoteMessage message) async {
  //   print(message.data);
  //   print(message.messageType);
  //   showNotification(message.data['message'], message.data['username']);
  // });
  print(await FirebaseMessaging.instance.getToken());
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  SharedPreferences prefs;

  MyApp({this.prefs});
  static final GlobalKey<NavigatorState> _key = GlobalKey();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // navigatorKey: _key,
      debugShowCheckedModeBanner: false,
      title: 'Foo Register',
      // theme: ThemeData.dark(),
      onGenerateRoute: generateRoute,
      home: Renderer(prefs: prefs),
      // home: StackTest(),
      // home: Test(),
      // home: AudioPlayerP(),
    );
  }
}

class StackTest extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    getCircle(color) => CircleAvatar(
          backgroundColor: color,
          radius: 25,
        );

    return Scaffold(
      body: Container(
          height: 100,
          width: 300,
          color: Colors.white,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              Positioned(left: 0, child: getCircle(Colors.blue)),
              Positioned(left: 25, child: getCircle(Colors.black))
            ],
          )),
    );
  }
}
