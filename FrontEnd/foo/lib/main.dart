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
      // home: Test(),
      // home: AudioPlayerP(),
    );
  }
}

class Test extends StatefulWidget {
  @override
  _TestState createState() => _TestState();
}

class _TestState extends State<Test> with SingleTickerProviderStateMixin {
  double z = 0;
  double x = 0;
  double y = 0;
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(seconds: 5));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: TextButton(
          child: Text("T"),
          onPressed: () {
            _controller.forward().whenComplete(() => _controller.reverse());
          },
        ),
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            double val = _controller.value;
            print(val);
            return Center(
              child: Transform(
                transform: Matrix4.identity()
                  ..rotateX(90)
                  ..rotateY(pi * val),
                // ..rotateZ(val * 2),
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.black,
                ),
              ),
            );
          },
        ));
  }
}
      //   body: Column(childaren: [
      // Transform(
      //   transform: Matrix4.identity()
      //     ..rotateZ(z)
      //     ..rotateX(x)
      //     ..rotateY(y),
      //   // ..rotateY(0)
      //   // ..rotateX(90),
      //   child: Container(
      //     height: 200,
      //     width: 200,
      //     color: Colors.black,
      //   ),
      // ),
      // TextButton(
      //   onPressed: () {
      //     setState(() {
      //       z++;
      //     });
      //   },
      //   child: Text("z up"),
      // ),
      // TextButton(
      //   onPressed: () {
      //     setState(() {
      //       z--;
      //     });
      //   },
      //   child: Text("z down"),
      // ),
      // TextButton(
      //   onPressed: () {
      //     setState(() {
      //       x++;
      //     });
      //   },
      //   child: Text("x up"),
      // ),
      // TextButton(
      //   onPressed: () {
      //     setState(() {
      //       x--;
      //     });
      //   },
      //   child: Text("x down"),
      // ),
      // TextButton(
      //   onPressed: () {
      //     setState(() {
      //       y++;
      //     });
      //   },
      //   child: Text("y up"),
      // ),
      // TextButton(
      //   onPressed: () {
      //     setState(() {
      //       y--;
      //     });
      //   },
      //   child: Text("y down"),
      // ),
