import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:foo/upload_screens/image_upload_screen.dart';
import 'package:foo/landing_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
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
  await Hive.openBox('Threads');

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
      //home: LandingPage(),
      // home:TestScreen(),1
    );
  }
}

class TestScreen extends StatelessWidget {
  String test =
      "iVBORw0KGgoAAAANSUhEUgAAAhwAAAPACAYAAAB+daCcAAAABHNCSVQICAgIfAhkiAAAIABJREFUeJzs3VmPZEea5vf/a2bn+BJL7jszuVcVWV2tnmnNTI8wkiAIutadvuBczt0AA0iAAEGCMF3Vqq6d7CKLW5JMZiaTucXmyzlmpgs7x8MzGLmSzmJGPD/C6R4RHh4nMhJpT5i99pr9x//0nzPLMmDdfSdlyGTIkFL3GOONS5u8DHLOz/zxxz1+Hmb21MdP+zwREZEfm09ubgEZw3AOMMrj5eGrzxAHhrTwg13lX1E/kD8uQBwMBf3zDgaAZ/n8Z3n/iz5PRETkZXUsAkdveWB/0uzFdw0Qz3stIiIiR92xChzLnnX2YlVfT0RE5Dg5toHjoMMCwfdRwyEiIiIKHE/0PMHhRYtNn+W5q559ERF52T3Lv9cv+sugfon8fihwvKDnDQGPe/7z7KAREZHD5ZxXFigO/jusAPJiFDhW5OBf0O9ju62IiDze8/wC96TQoECxGgocz+F5lz+eJ2Q86eMKKCIiT/a8AeJJbQ4e1xrhsM9VOHl2ChxP8aIh42lLKJrxEBH5/jzt39HDmjAe1qPpcUszCh/fnQLHEzxvh9LDnn8wYDxPEHmeaxEROa6e1jtpedYC+NYMxuMCSB8+nmXWY/n5R0UIgdFoRNu2TCaT7/5638M1HUnPssTxuJCwHD4eV8vxuIDyLNeg8CEix93jGjk+rcFjHyCWHRZAlsPHYUHiSTMeqwgd58+f5/z586ytrfGrX/1qpa8zGo146623OHXqFM45AKbTKV988UXX2vzFKHAc4lkG+sMCQ/++xz3vSUsvzxoiFDZERIrnPT6in6l40vIKPDqzcdiyy9NmPL6v0HHixAkuXrzI6dOnGQwGAMzn85W+TlVV/OIXv2A8HgMQY8R7z3A45O233+bu1oz3P/z4hb4fBY4DnndZ5LBA8aTg4ZzDe7+4HaXpNxGRH7OcMyklUkrEGBePDwaI5ZBxcNbjWWc";

  File file;

  bool done = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: this.done
          ? Center(child: Image.file(this.file))
          : Center(child: Text("hello")),
      floatingActionButton: IconButton(
        icon: Icon(Icons.add),
        color: Colors.black,
        onPressed: () async {
          FilePickerResult result = await FilePicker.platform.pickFiles();
          print(result);
          File file = File(result.files.single.path);
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => VideoApp(file: file)));
          // var bytes = file.readAsBytesSync();
          // print(bytes);
          // String img64 = base64Encode(bytes);
          // print(img64);
          // var decodedBytes = base64Decode(img64);
          // this.file = File("/data/user/0/com.example.foo/cache/file_picker/test.png");

          // this.file.writeAsBytesSync(decodedBytes);
          // setState((){
          //   done=true;
          // });
          // Directory appDocDir = await getApplicationDocumentsDirectory();
          // print(appDocDir.path);
        },
      ),
    );
  }
}

class VideoApp extends StatefulWidget {
  File file;

  VideoApp({Key key, this.file}) : super(key: key);

  @override
  _VideoAppState createState() => _VideoAppState();
}

class _VideoAppState extends State<VideoApp> {
  VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      })
      ..setLooping(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _controller.value.isInitialized
            ? Container(
                height: 200,
                // decoration: B,
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              )
            : Container(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play();
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}
