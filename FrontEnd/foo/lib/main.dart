import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound_lite/flutter_sound.dart';
import 'package:foo/notification_handler.dart';
import 'package:foo/socket.dart';
import 'package:ionicons/ionicons.dart';
import 'package:permission_handler/permission_handler.dart';
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
import 'package:google_fonts/google_fonts.dart';
import 'package:foo/auth/register.dart';

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
  Hive.registerAdapter(UserStoryModelAdapter());
  Hive.registerAdapter(StoryAdapter());
  Hive.registerAdapter(StoryUserAdapter());
  Hive.registerAdapter(StoryCommentAdapter());

  await Hive.openBox('Threads');
  await Hive.openBox('Feed');
  await Hive.openBox('Notifications');
  await Hive.openBox('MyStories');

  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString("curUser", "");
  SocketChannel socket;
  if (prefs.containsKey('username')) {
    print("in main");
    socket = SocketChannel();
  }

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
    );
  }
}

class CalendarBackground extends StatefulWidget {
  @override
  _CalendarBackgroundState createState() => _CalendarBackgroundState();
}

class _CalendarBackgroundState extends State<CalendarBackground> {
  FixedExtentScrollController _dateController;
  FixedExtentScrollController _monthController;
  FixedExtentScrollController _yearController;
  int date = 1, month = 1, year = 2000;

  Map months = {
    1: 'Jan',
    2: 'Feb',
    3: 'Mar',
    4: 'Apr',
    5: 'May',
    6: 'Jun',
    7: 'Jul',
    8: 'Aug',
    9: 'Sept',
    10: 'Oct',
    11: 'Nov',
    12: 'Dec',
  };

  @override
  void initState() {
    super.initState();
    _dateController = FixedExtentScrollController();
    _monthController = FixedExtentScrollController();
    _yearController = FixedExtentScrollController();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle style() => GoogleFonts.titilliumWeb(
          color: Colors.black,
          fontSize: 20.0,
          fontWeight: FontWeight.w400,
        );

    return Scaffold(
      // backgroundColor: Color.fromARGB(255, 120, 129, 213),
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * .7),
          padding: EdgeInsets.fromLTRB(0, 50, 0, 10),
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border:
                            Border.all(color: Colors.grey.shade400, width: 1),

                        // color: Colors.grey.shade100,
                      ),
                      child: Icon(Icons.person_rounded,
                          size: 50, color: Colors.black),
                    ),
                    // Positioned(
                    //   child: Container(
                    //     height: 8,
                    //     width: 8,
                    //     child: Icon(Icons.add),
                    //   ),
                    // )
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        // color: Colors.black.withOpacity(.3),
                      ),
                      child: Center(
                          // child: Text("Change photo"),
                          ),
                    )
                  ],
                )
              ]),
              SizedBox(height: 50),
              Text(
                "When is your birthday?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      height: 80,
                      width: 50,
                      margin: EdgeInsets.all(5),
                      child: ListWheelScrollView(
                          controller: _dateController,
                          itemExtent: 30,
                          children: [
                            for (int i = 1; i <= 31; i++)
                              Text(
                                '$i',
                                style: style(),
                              ),
                          ],
                          overAndUnderCenterOpacity: 0.5,
                          useMagnifier: true,
                          diameterRatio: 1.5,
                          offAxisFraction: .5,
                          physics: BouncingScrollPhysics(),
                          onSelectedItemChanged: (data) {
                            date = data + 1;
                            print('$date/$month/$year');
                          })),
                  Container(
                      height: 80,
                      width: 50,
                      margin: EdgeInsets.all(5),
                      child: ListWheelScrollView(
                          controller: _monthController,
                          itemExtent: 30,
                          children: [
                            for (int i = 1; i <= 12; i++)
                              Text(
                                months[i],
                                textAlign: TextAlign.left,
                                textDirection: TextDirection.ltr,
                                style: style(),
                              ),
                          ],
                          overAndUnderCenterOpacity: 0.5,
                          useMagnifier: true,
                          diameterRatio: 1.5,
                          offAxisFraction: .5,
                          physics: BouncingScrollPhysics(),
                          onSelectedItemChanged: (data) {
                            month = data + 1;
                            print('$date/$month/$year');
                          })),
                  Container(
                      height: 80,
                      width: 50,
                      margin: EdgeInsets.all(5),
                      child: ListWheelScrollView(
                          controller: _yearController,
                          itemExtent: 30,
                          children: [
                            for (int i = 1980; i <= 2021; i++)
                              Text(
                                '$i',
                                style: style(),
                              ),
                          ],
                          overAndUnderCenterOpacity: 0.5,
                          useMagnifier: true,
                          diameterRatio: 1.5,
                          offAxisFraction: .5,
                          physics: BouncingScrollPhysics(),
                          onSelectedItemChanged: (data) {
                            year = data + 1980; //to increment the index by 1980
                            print('$date/$month/$year');
                          }))
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 70,
        width: MediaQuery.of(context).size.width,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {},
              child: Text(
                "Next",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class Story {
  final String url;
  final String type;
  Story({this.url, this.type});
}

class StoryPage extends StatefulWidget {
  @override
  _StoryPageState createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> {
  int index = 0;
  VideoPlayerController _controller;
  ValueNotifier notifier;
  List assets = [
    Story(url: "http://10.0.2.2:8000/media/user_1/user.png", type: "img"),
    Story(
        url: "http://10.0.2.2:8000/media/user_1/stories/outp.mp4", type: "vid"),
    Story(url: "http://10.0.2.2:8000/media/user_2/anna.mp4", type: "vid"),
  ];

  _tapHandler() async {
    if (assets[index + 1].type == "vid") {
      if (assets[index].type == "vid") {
        await _controller.pause();
      }
      _controller = VideoPlayerController.network(assets[index + 1].url);
      setState(() {
        notifier = ValueNotifier(_controller);
      });
    }
    setState(() {
      index += 1;
    });
  }

  void checkAndSendKeyboardStatus() {
    if (assets[index].type == "vid") {
      // if (MediaQuery.of(context).viewInsets.bottom != 0) {
      //   _controller.pause();
      // } else {
      //   _controller.play();
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    checkAndSendKeyboardStatus();
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: GestureDetector(
        onTap: _tapHandler,
        child: Container(
          height: size.height,
          width: size.width,
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    assets[index].type == "img"
                        ? StoryImage(story: assets[index])
                        : StoryVideo(
                            story: assets[index],
                            controller: _controller,
                            notifier: notifier),
                    Positioned(
                      child:
                          Text("hello", style: TextStyle(color: Colors.white)),
                      bottom: 50,
                    )
                  ],
                ),
              ),
              Container(
                  height: 70,
                  width: size.height,
                  child: Row(
                    children: [Expanded(child: TextField())],
                  ))
            ],
          ),
        ),
      ),
    );
  }
}

class StoryImage extends StatelessWidget {
  final Story story;
  StoryImage({this.story});
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
        height: size.height,
        width: size.width,
        child: Image.network(
          story.url,
          fit: BoxFit.contain,
        ));
  }
}

class StoryVideo extends StatefulWidget {
  final Story story;
  VideoPlayerController controller;
  ValueNotifier notifier;
  StoryVideo({this.story, this.controller, this.notifier});

  @override
  _StoryVideoState createState() => _StoryVideoState();
}

class _StoryVideoState extends State<StoryVideo> {
  VideoPlayerController _controller;
  bool isInit = false;
  String url;
  @override
  void initState() {
    super.initState();
    // initVideo();
  }

  runIt() async {
    if (url != widget.story.url) {
      url = widget.story.url;
      await widget.notifier.value.initialize();
      setState(() {
        isInit = true;
      });
      widget.notifier.value.play();
    }
  }

  // void checkAndSendKeyboardStatus() {
  //   if (MediaQuery.of(context).viewInsets.bottom != 0) {
  //     print("keboard up");
  //     _controller.pause();
  //   } else {
  //     _controller.play();
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    print("again and again");
    // checkAndSendKeyboardStatus();
    print('hello');
    final size = MediaQuery.of(context).size;
    return ValueListenableBuilder(
        valueListenable: widget.notifier.value,
        builder: (context, snapshot, widg_et) {
          runIt();
          print(snapshot.runtimeType);
          return Container(
              height: size.height,
              width: size.width,
              child: isInit
                  ? VideoPlayer(widget.notifier.value)
                  : Center(child: CircularProgressIndicator()));
        });
  }

  @override
  void dispose() {
    super.dispose();
    _controller?.dispose();
  }
}
