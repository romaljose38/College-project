import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:foo/chat/listscreen.dart';
import 'package:foo/notifications/notification_screen.dart';
import 'package:foo/profile/profile_test.dart';
import 'package:foo/screens/feed_screen.dart';
import 'package:foo/screens/search_screen.dart';
import 'package:foo/socket.dart';
import 'package:foo/upload_screens/audio_upload_screen.dart';
import 'package:foo/upload_screens/image_upload_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:foo/upload_screens/video_upload_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LandingPageProxy extends StatelessWidget {
  // NotificationController controller = NotificationController();

  @override
  Widget build(BuildContext context) {
    return LandingPage();
  }
}

class LandingPage extends StatefulWidget {
  int index;

  LandingPage({this.index = 0});

  @override
  LandingPageState createState() => LandingPageState();
}

class LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  AnimationController animationController;
  Animation animation;
  OverlayEntry overlayEntry;
  ImagePicker _picker = ImagePicker();
  int curpgviewIndex;
  PageController _pageController;
  SharedPreferences _prefs;
  Timer timer;
  static bool isConnected = false;
  SocketChannel socket;

  // NotificationController controller;

  @override
  void initState() {
    notifInit();
    setPrefs();
    super.initState();
    checkSocket();

    _pageController = PageController(initialPage: widget.index);
    animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    animation =
        Tween<double>(begin: 0.0, end: 1.0).animate(animationController);
    // timer = Timer.periodic(Duration(seconds: 10), (Timer t) => handleSocket());
  }

  checkSocket() {
    if (!SocketChannel.isConnected) {
      socket = SocketChannel();
      print("in landing page");
    }
  }

  Future<int> setPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getInt('id');
  }

  @override
  void dispose() {
    super.dispose();
    animationController.dispose();
    _pageController.dispose();
  }

  notifInit() async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings();
    final MacOSInitializationSettings initializationSettingsMacOS =
        MacOSInitializationSettings();
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
            macOS: initializationSettingsMacOS);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: handleEntry);
  }

  Future<dynamic> handleEntry(String payload) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => LandingPage(index: 1)));
  }

  // function that picks an image from the gallery
  Future<void> _getImage() async {
    FilePickerResult result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null) {
      File _image = File(result.files.single.path);

      // await animationController.reverse().whenComplete(() {
      //   overlayVisible = false;
      //   overlayEntry.remove();
      // });
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImageUploadScreen(
              mediaInserted: _image,
            ),
          ));
    }
  }

  Future<void> _getAudio() async {
    FilePickerResult result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );
    if (result != null) {
      File _audio = File(result.files.single.path);

      // await animationController.reverse().whenComplete(() {
      //   overlayVisible = false;
      //   overlayEntry.remove();
      // });
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AudioUploadScreen(
              audio: _audio,
            ),
          ));
    }
  }
  //

  //Function that picks up a video from the gallery

  Future<void> _getVideo() async {
    FilePickerResult result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );
    if (result != null) {
      File _video = File(result.files.single.path);

      // animationController.reverse().whenComplete(() {
      //   overlayVisible = false;
      //   overlayEntry.remove();
      // });

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => VideoUploadScreen(
                    mediaInserted: _video,
                  )));
    }
  }

  //

  // Function that takes an image using the camera

  Future<void> _takePic() async {
    File _image;

    final pickedFile = await _picker.getImage(source: ImageSource.camera);
    _image = File(pickedFile.path);

    if (_image != null) {
      // animationController.reverse().whenComplete(() {
      //   overlayVisible = false;
      //   overlayEntry.remove();
      // });

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ImageUploadScreen(
                    mediaInserted: _image,
                  )));
    }
  }

  //

  // To exit the overlay on back press

  bool overlayVisible = false;

  Future<bool> onBackPress() async {
    if (overlayVisible == true) {
      animationController.reverse().whenComplete(() {
        overlayVisible = false;
        overlayEntry.remove();
      });
    } else if (_page == 0) {
      //0th _page is home(feed)
      if (curpgviewIndex == 1) {
        _pageController.previousPage(
            duration: Duration(milliseconds: 100), curve: Curves.easeIn);
        return Future.value(false);
      }
      SystemNavigator.pop(); //Exits the app
    } else {
      setState(() {
        _page = 0;
      });
    }

    return Future.value(false);
  }

  //

  int _page = 0;

  GestureDetector bottomSheetTile(
          String type, Color color, IconData icon, Function onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 70,
              width: 70,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: Colors.grey.shade600,
                size: 30,
              ),
            ),
            SizedBox(height: 8),
            Text(
              type,
              style: GoogleFonts.raleway(
                color: Color.fromRGBO(176, 183, 194, 1),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );

  showOverlay() {
    showModalBottomSheet(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        context: context,
        builder: (context) {
          return Container(
            height: 300,
            margin: EdgeInsets.fromLTRB(10, 20, 10, 0),
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Create new post",
                        style: GoogleFonts.lato(
                            fontSize: 20, fontWeight: FontWeight.w600)),
                  ],
                ),
                SizedBox(height: 30),
                Expanded(
                  child: Container(
                    child: Center(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Spacer(),
                              bottomSheetTile(
                                  "Camera",
                                  Color.fromRGBO(232, 252, 246, 1),
                                  Ionicons.camera_outline,
                                  _takePic),
                              Spacer(),
                              bottomSheetTile(
                                  "Image",
                                  Color.fromRGBO(235, 221, 217, 1),
                                  Ionicons.image_outline,
                                  _getImage),
                              Spacer(),
                            ],
                          ),
                          SizedBox(height: 18),
                          Row(
                            children: [
                              Spacer(),
                              bottomSheetTile(
                                  "Audio",
                                  Color.fromRGBO(211, 224, 240, 1),
                                  Ionicons.mic_circle_outline,
                                  _getAudio),
                              Spacer(),
                              bottomSheetTile(
                                  "Video",
                                  Color.fromRGBO(250, 236, 255, 1),
                                  Ionicons.videocam_outline,
                                  _getVideo),
                              Spacer(),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    List pages = [
      WillPopScope(
        onWillPop: () async {
          setState(() {
            curpgviewIndex = 0;
          });
          print(_pageController.page);
          return false;
        },
        child: PageView(
          controller: _pageController,
          children: [FeedScreen(), ChatListScreen()],
          onPageChanged: (index) {
            print("current page is " + index.toString());
            setState(() {
              curpgviewIndex = index;
            });
          },
        ),
      ),
      SearchScreen(),
      Profile(
        myProfile: true,
      ),
      NotificationScreen(),
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: WillPopScope(
        onWillPop: onBackPress,
        child: pages[_page],
      ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // floatingActionButton: ClipOval(
      //   clipBehavior: Clip.antiAlias,
      //   child: Container(
      //     width: 40,
      //     height: 40,
      //     decoration: BoxDecoration(
      //       color: Colors.white.withOpacity(.2),
      //     ),
      //     child: BackdropFilter(
      //       filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      //       child: IconButton(
      //         icon: Icon(Ionicons.add, color: Colors.black, size: 20),
      //         onPressed: () {
      //           showOverlay(context);
      //         },
      //       ),
      //     ),
      //   ),
      // ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: Container(
            // color: Colors.transparent,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: new Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                IconButton(
                    icon: Icon(Ionicons.home, size: 22, color: Colors.black),
                    disabledColor: Colors.green,
                    onPressed: () => setState(() => _page = 0)),
                IconButton(
                    icon: Icon(Ionicons.search_outline,
                        size: 22, color: Colors.black),
                    disabledColor: Colors.green,
                    onPressed: () => setState(() => _page = 1)),
                // SizedBox(
                //   width: 14,
                // ),
                GestureDetector(
                  onTap: showOverlay,
                  child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(width: 1, color: Colors.black),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Ionicons.add, size: 20, color: Colors.black)),
                ),
                IconButton(
                    icon: Icon(Ionicons.person_outline,
                        size: 22, color: Colors.black),
                    disabledColor: Colors.green,
                    onPressed: () => setState(() => _page = 2)),
                IconButton(
                    icon: Icon(Ionicons.settings_outline,
                        size: 22, color: Colors.black),
                    disabledColor: Colors.green,
                    onPressed: () => setState(() => _page = 3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
