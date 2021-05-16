import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:foo/chat/listscreen.dart';
import 'package:foo/chat/socket.dart';
import 'package:foo/colour_palette.dart';
import 'package:foo/models.dart';
import 'package:foo/notification_handler.dart';
import 'package:foo/notifications/notification_screen.dart';
import 'package:foo/profile/profile_test.dart';
import 'package:foo/screens/feed_screen.dart';
import 'package:foo/screens/search_screen.dart';
import 'package:foo/test_cred.dart';
import 'package:foo/upload_screens/audio_upoad_screen.dart';
import 'package:foo/upload_screens/image_upload_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:ionicons/ionicons.dart';
import 'package:foo/upload_screens/video_upload_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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
  // NotificationController controller;

  @override
  void initState() {
    notifInit();
    super.initState();
    setPrefs();
    _pageController = PageController(initialPage: widget.index);
    animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    animation =
        Tween<double>(begin: 0.0, end: 1.0).animate(animationController);
    timer = Timer.periodic(Duration(seconds: 10), (Timer t) => handleSocket());
  }

  Future<void> setPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  void dispose() {
    super.dispose();
    animationController.dispose();
    timer.cancel();
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

      await animationController.reverse().whenComplete(() {
        overlayVisible = false;
        overlayEntry.remove();
      });
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

      await animationController.reverse().whenComplete(() {
        overlayVisible = false;
        overlayEntry.remove();
      });
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

      animationController.reverse().whenComplete(() {
        overlayVisible = false;
        overlayEntry.remove();
      });

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
      animationController.reverse().whenComplete(() {
        overlayVisible = false;
        overlayEntry.remove();
      });

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

  showOverlay(BuildContext context) {
    overlayVisible = true;
    OverlayState overlayState = Overlay.of(context);
    overlayEntry = OverlayEntry(
      builder: (context) => Scaffold(
        backgroundColor: Colors.black.withOpacity(.3),
        body: FadeTransition(
          opacity: animation,
          child: GestureDetector(
            onTap: () {
              animationController
                  .reverse()
                  .whenComplete(() => {overlayEntry.remove()});
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    InkWell(
                      onTap: _getAudio,
                      child: Column(
                        children: [
                          Icon(
                            Ionicons.image_outline,
                            color: Colors.white,
                            size: 30,
                          ),
                          Text(
                            "Audio",
                            style: GoogleFonts.raleway(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: _getImage,
                      child: Column(
                        children: [
                          Icon(
                            Ionicons.image_outline,
                            color: Colors.white,
                            size: 30,
                          ),
                          Text(
                            "Image",
                            style: GoogleFonts.raleway(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: _getVideo,
                      splashFactory: InkRipple.splashFactory,
                      child: Column(
                        children: [
                          Icon(
                            Ionicons.videocam_outline,
                            color: Colors.white,
                            size: 30,
                          ),
                          Text(
                            "Video",
                            style: GoogleFonts.raleway(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: _takePic,
                      child: Column(
                        children: [
                          Icon(
                            Ionicons.camera_outline,
                            color: Colors.white,
                            size: 30,
                          ),
                          Text(
                            "Camera",
                            style: GoogleFonts.raleway(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    animationController.addListener(() {
      overlayState.setState(() {});
    });
    animationController.forward();
    overlayState.insert(overlayEntry);
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
      Profile(),
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
                Container(
                    decoration: BoxDecoration(
                      border: Border.all(width: 1, color: Colors.black),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Ionicons.add, size: 20, color: Colors.black)),
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

  //Socket things
  static WebSocket channel;
  LocalNotificationHandler _handler = LocalNotificationHandler();

  Future<void> handleSocket() async {
    try {
      var resp = await http.get(Uri.http(localhost, '/api/ping'));
      if (resp.statusCode == 200) {
        if (!isConnected) {
          await setPrefs();
          String wsUrl = 'ws://$localhost/ws/chat_room/' +
              _prefs.getString("username") +
              "/";
          // ignore: unused_local_variable
          channel = await WebSocket.connect(wsUrl);
          initWebSocketConnection();
        }
      } else {
        isConnected = false;
      }
    } catch (e) {
      isConnected = false;
    }
  }

  initWebSocketConnection() async {
    print("connected.");
    isConnected = true;
    print("socket connection initializied");
    channel.done.then((dynamic _) => _onDisconnected());

    getPendingMessages();
    broadcastNotifications();
  }

  getPendingMessages() {
    List msgList = [];
    var threadList = Hive.box("Threads").values.toList();
    threadList.forEach((e) {
      print(e);
      if (e.needToCheck()) {
        msgList.add([e.getUnsentMessages(), e.second.name]);
      }
    });
    print(msgList);
    if (msgList.length > 0) {
      msgList.forEach((element) {
        String senderName = element[1];
        element[0].forEach((e) {
          print(e.msgType);
          if (e.msgType == "txt") {
            var data = jsonEncode({
              'message': e.message,
              'id': e.id,
              'time': e.time.toString(),
              'from': _prefs.getString("username"),
              'to': senderName,
              'type': 'msg',
            });
            print(data);
            channel.add(data);
          }
        });
      });
    }
  }

  broadcastNotifications() {
    channel.listen((streamData) {
      print(streamData);
      dataHandler(jsonDecode(streamData));
    }, onDone: () {
      isConnected = false;
      print("conecting aborted");
    }, onError: (e) {
      isConnected = false;
      print('Server error: $e');
    });
  }

  dataHandler(data) {
    if (data.containsKey('received')) {
      _updateChatStatus(data['received'], data['name']);
    } else if (data.containsKey("r_s")) {
      _updateReachedServerStatus(
          id: data['r_s']['id'],
          newId: data['r_s']['n_id'],
          name: data['r_s']['to']);
    } else if (data['type'] == 'chat_message') {
      if ((_prefs.containsKey('lastMsgId') &
              (_prefs.getInt('lastMsgId') != data['message']['id'])) |
          !_prefs.containsKey('lastMsgId')) {
        _prefs.setInt("lastMsgId", data['message']['id']);
        if (data['message']['to'] == _prefs.getString('username')) {
          print(data['message']['id']);

          _createThread(data);
          sendToChannel(jsonEncode({'received': data['message']['id']}));
        }
      }
    } else if (data['type'] == 'notification') {
      addNotification(data);
    } else if (data['type'] == 'seen_ticker') {
      updateMsgSeenStatus(data);
    } else if (data['type'] == 'typing_status') {
      updateTypingStatus(data);
    }
  }

  void updateTypingStatus(data) {
    String me = _prefs.getString('username');
    String threadName = me + '_' + data['from'];
    var threadBox = Hive.box('Threads');
    var existingThread = threadBox.get(threadName);
    if (data['status'] == "typing") {
      existingThread.isTyping = true;
    } else {
      existingThread.isTyping = false;
    }

    existingThread.save();
  }

  void updateMsgSeenStatus(data) {
    print("in messaeg seen status");
    String me = _prefs.getString('username');
    String threadName = me + '_' + data['from'];
    var threadBox = Hive.box('Threads');
    var existingThread = threadBox.get(threadName);
    existingThread.updateChatSeenStatus(data['id']);
    existingThread.save();
  }

  void addNotification(data) async {
    if ((_prefs.containsKey('lastNotifId') &
            (_prefs.getInt('lastNotifId') != data['id'])) |
        !_prefs.containsKey('lastNotifId')) {
      _prefs.setInt("lastNotifId", data['id']);
      DateTime curTime = DateTime.now();
      _handler.friendRequestNotif(data['username']);
      var notif = Notifications(
          type: NotificationType.friendRequest,
          userName: data['username'],
          timeCreated: curTime,
          userId: data['user_id']);
      var notifBox = await Hive.openBox('Notifications');
      await notifBox.put(curTime.toString(), notif);
    }
  }

  void _updateReachedServerStatus({id, newId, name}) {
    String me = _prefs.getString('username');
    String threadName = me + '_' + name;
    var threadBox = Hive.box('Threads');
    var existingThread = threadBox.get(threadName);
    existingThread.updateChatId(id: id, newId: newId);
    existingThread.save();
  }

  void _updateChatStatus(int id, String name) {
    String me = _prefs.getString('username');
    String threadName = me + '_' + name;
    var threadBox = Hive.box('Threads');
    var existingThread = threadBox.get(threadName);
    existingThread.updateChatStatus(id);
    existingThread.save();
  }

  _chicanery(threadName, thread, data) async {
    // showNotification(data['message']['message'], data['message']['from']);
    _handler.chatNotif(data['message']['from'], data['message']['message']);

    var box = Hive.box("Threads");
    await box.put(threadName, thread);
    if (data['msg_type'] == 'txt') {
      thread.addChat(ChatMessage(
        message: data['message']['message'],
        senderName: data['message']['from'],
        time: DateTime.now(),
        isMe: false,
        msgType: 'txt',
        id: data['message']['id'],
      ));
    } else if (data['msg_type'] == 'img') {
      thread.addChat(ChatMessage(
        base64string: data['message']['img'],
        senderName: data['message']['from'],
        msgType: 'img',
        time: DateTime.now(),
        isMe: false,
        id: data['message']['id'],
      ));
    } else if (data['msg_type'] == 'aud') {
      thread.addChat(ChatMessage(
        base64string: data['message']['aud'],
        senderName: data['message']['from'],
        msgType: 'aud',
        time: DateTime.now(),
        isMe: false,
        id: data['message']['id'],
      ));
    }
    if (thread.hasUnseen != null) {
      thread.hasUnseen += 1;
    } else {
      thread.hasUnseen = 1;
    }

    thread.save();
  }

  Future _createThread(data) async {
    if (data == "None") {
      return null;
    }
    var threadBox = Hive.box('Threads');
    var me = _prefs.getString('username');

    //Creating thread with the given data
    var thread = Thread(
        first: User(name: me), second: User(name: data['message']['from']));

    //Thread is named in the format "self_sender" eg:anna_deepika
    var threadName = me + '_' + data['message']['from'];

    //Checking if thread already exists in box, if exists, the new chat messaeg if added else new thread is created and saved to box.
    if (!threadBox.containsKey(threadName)) {
      print("new_thread");
      print(data['message']['id']);

      await _chicanery(threadName, thread, data);
    } else {
      var existingThread = threadBox.get(threadName);

      if (_prefs.getString("curUser") != data['message']['from']) {
        _handler.chatNotif(data['message']['from'], data['message']['message']);
        if (existingThread.hasUnseen != null) {
          existingThread.hasUnseen += 1;
        } else {
          existingThread.hasUnseen = 1;
        }
      }

      // else{
      //   existingThread.hasUnseen=true;
      // }
      if (data['msg_type'] == 'txt') {
        existingThread.addChat(ChatMessage(
          message: data['message']['message'],
          senderName: data['message']['from'],
          time: DateTime.now(),
          isMe: false,
          msgType: "txt",
          id: data['message']['id'],
        ));
      } else if (data['msg_type'] == 'aud') {
        existingThread.addChat(ChatMessage(
          base64string: data['message']['aud'],
          senderName: data['message']['from'],
          time: DateTime.now(),
          ext: data['message']['ext'],
          msgType: "aud",
          isMe: false,
          id: data['message']['id'],
        ));
      } else if (data['msg_type'] == 'img') {
        existingThread.addChat(ChatMessage(
          base64string: data['message']['img'],
          senderName: data['message']['from'],
          time: DateTime.now(),
          ext: data['message']['ext'],
          msgType: "img",
          isMe: false,
          id: data['message']['id'],
        ));
      }

      existingThread.save();
    }
  }

  static sendToChannel(data) {
    if (isConnected) {
      if (channel != null) {
        channel.add(data);
      }
    } else {
      return false;
    }
  }

  void _onDisconnected() {
    isConnected = false;
  }
}
