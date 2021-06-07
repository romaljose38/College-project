import 'dart:io';

import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:foo/chat/audiocloud.dart';
import 'package:foo/chat/chatcloud.dart';
import 'package:foo/chat/forward_screen.dart';
import 'package:foo/chat/listscreen.dart';
import 'package:foo/custom_overlay.dart';
import 'package:foo/profile/profile_test.dart';
import 'package:foo/socket.dart';
import 'package:foo/test_cred.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';

import 'chatcloudlist.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foo/models.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:timeago/timeago.dart' as timeago;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:foo/screens/feed_icons.dart' as icons;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';

String imageUTF = "\x69\x6d\x61\x67\x65";
String audioUTF = "\x61\x75\x64\x69\x6f";

class ChatScreen extends StatefulWidget {
  // final SocketChannel controller;
  final Thread thread;
  final SharedPreferences prefs;
  ChatScreen(
      {Key key,
      this.prefs,
      // this.controller,
      this.thread})
      : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  String curUser;
  String otherUser;
  String threadName;
  TextEditingController _chatController = TextEditingController();
  // AutoScrollController _scrollController;
  AnimationController _animationController;
  Thread thread;
  SharedPreferences _prefs;
  Timer timer;
  bool keyboardUp;
  bool overlayVisible = false;
  OverlayEntry entry;
  StreamSubscription test;
  ItemScrollController _scrollController = ItemScrollController();
  ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  //
  bool lastSeenHidden = false;
  String userStatus = "";

  //
  Widget replyingMsg;
  FocusNode focusNode = FocusNode();
  ChatMessage replyingMsgObj;

  //
  bool isForwarding = false;
  Map<int, ChatMessage> forwardedMsgs = <int, ChatMessage>{};

  //
  int refreshId = 0;
  int chatCount;

  bool hasSentSeenStatus = false;

  @override
  void initState() {
    super.initState();
    _prefs = widget.prefs;
    _getUserName();

    // _scrollController = AutoScrollController(
    //     // viewportBoundaryGetter: () => Rect.fromLTRB(0, 100, 0, 70),
    //     axis: Axis.vertical);

    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 100));

    otherUser = widget.thread.second.name;
    curUser = widget.thread.first.name;
    threadName = widget.thread.first.name + "-" + widget.thread.second.name;
    //Initializing the _chatList as the chatList of the current thread
    thread = Hive.box('Threads').get(threadName);
    chatCount = thread.chatList.length;
    sendSeenTickerIfNeeded();

    setPreferences();

    obtainStatus();
    updateLastChatMsgStatus();
    //
    timer = Timer.periodic(
        Duration(seconds: 5), (Timer t) => _checkConnectionStatus());

    //
    listenToHive();
  }

  void listenToHive() {
    test = Hive.box('Threads').watch(key: threadName).listen((BoxEvent event) {
      Thread existingThread = Hive.box('Threads').get(threadName);
      if (chatCount == existingThread.chatList.length) {
        print("hive listen");
        if (mounted) {
          if (!lastSeenHidden) {
            if (existingThread.isOnline ?? false) {
              print("hes online");

              setState(() {
                userStatus = "Online";
              });
            } else {
              if ((existingThread.lastSeen ?? null) != null) {
                setState(() {
                  userStatus = timeago.format(existingThread.lastSeen);
                });
              }
            }
          }
        }
        if (!lastSeenHidden) {
          if (existingThread.isTyping ?? false == true) {
            print("typing");
            if (mounted) {
              setState(() {
                userStatus = "typing..";
              });
            }
          } else if (existingThread.isTyping == false) {
            print("stopped");
            if (mounted) {
              print(existingThread.isOnline);
              print(existingThread.lastSeen);
              if (existingThread.isOnline ?? false) {
                setState(() {
                  userStatus = "Online";
                });
              } else if (existingThread.lastSeen != null) {
                setState(() {
                  userStatus = timeago.format(existingThread.lastSeen);
                });
              }
            }
          }
        }
      }
      chatCount = existingThread.chatList.length;
    }, onDone: () {
      print('done');
    });
  }

  void sendSeenTickerIfNeeded() async {
    _prefs = await SharedPreferences.getInstance();

    if ((thread.chatList != null) &&
        thread.chatList.length > 0 &&
        (thread.chatList.last.isMe != true) &&
        (thread.chatList.last.id != null) &&
        (thread.chatList.last.id != _prefs.getInt("lastSeenId"))) {
      var seenTicker = {
        "type": "seen_ticker",
        "to": otherUser,
        "id": thread.chatList.last.id,
      };
      if (SocketChannel.isConnected) {
        SocketChannel.sendToChannel(jsonEncode(seenTicker));
        _prefs.setInt("lastSeenId", thread.chatList.last.id);
        hasSentSeenStatus = true;
      }
    }
  }

  void updateLastChatMsgStatus() {
    if (thread.chatList != null) {
      if (thread.chatList.length > 0) {
        if (thread.chatList.last.isMe != true) {
          var threadBox = Hive.box("Threads");
          var thread = threadBox.get(curUser + '-' + otherUser);
          if ((thread.hasUnseen ?? -1) > 0) {
            thread.hasUnseen = 0;
            thread.save();
          }
        }
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
    test?.cancel();
    _chatController.dispose();
    // _scrollController.dispose();
    _animationController?.dispose();
  }

  Future<void> obtainStatus() async {
    var id = _prefs.getInt("id");
    Thread existingThread = Hive.box('Threads').get(threadName);
    var resp = await http.get(Uri.http(localhost, '/api/get_status',
        {"username": otherUser, "id": id.toString()}));
    if (resp.statusCode == 200) {
      Map body = jsonDecode(resp.body);
      if (body['status'] == "online") {
        existingThread.isOnline = true;
        existingThread.save();
        if (userStatus != "Online") {
          setState(() {
            userStatus = "Online";
          });
        }
      } else if (body['status'] == 'nope') {
        setState(() {
          userStatus = "";
          lastSeenHidden = true;
        });
      } else {
        DateTime time = DateTime.parse(body['status']);
        existingThread.lastSeen = time;
        existingThread.save();
        if (mounted) {
          setState(() {
            userStatus = timeago.format(time);
          });
        }
      }
    }
  }

  void _checkConnectionStatus() async {
    bool result = await DataConnectionChecker().hasConnection;
    if ((result == true) &&
        (hasSentSeenStatus == false) &&
        SocketChannel.isConnected) {
      sendSeenTickerIfNeeded();
    }
    if ((result == true) && (userStatus == "") && (lastSeenHidden != true)) {
      obtainStatus();
    } else if ((result == false) && (userStatus != "")) {
      setState(() {
        userStatus = "";
      });
    }
  }

  void _getUserName() async {
    _prefs = await SharedPreferences.getInstance();
    // curUser = _prefs.getString('username');
    _prefs.setString("curUser", otherUser);
  }

  void _sendMessage(TextEditingController _chatController) {
    if (_chatController.text.isNotEmpty) {
      var _id = DateTime.now().microsecondsSinceEpoch;
      var curTime = DateTime.now();

      var threadBox = Hive.box('Threads');
      Thread currentThread = threadBox.get(threadName);

      var data;
      ChatMessage obj;
      if (replyingMsgObj != null) {
        data = jsonEncode({
          'message': _chatController.text,
          'id': _id,
          'time': curTime.toString(),
          'to': otherUser,
          'reply_id': replyingMsgObj.id,
          'reply_txt': replyingMsgObj.msgType == "txt"
              ? replyingMsgObj.message
              : (replyingMsgObj.msgType == "img")
                  ? imageUTF
                  : audioUTF,
          'type': 'reply_txt',
        });

        obj = ChatMessage(
            message: _chatController.text,
            isMe: true,
            id: _id,
            msgType: "reply_txt",
            time: curTime,
            senderName: curUser,
            replyMsgId: replyingMsgObj.id,
            replyMsgTxt: (replyingMsgObj.msgType == "txt" ||
                    replyingMsgObj.msgType == "reply_txt")
                ? replyingMsgObj.message
                : (replyingMsgObj.msgType == "img" ||
                        replyingMsgObj.msgType == "reply_img")
                    ? imageUTF
                    : audioUTF);
      } else {
        data = jsonEncode({
          'message': _chatController.text,
          'id': _id,
          'time': curTime.toString(),
          'to': otherUser,
          'type': 'msg',
        });
        obj = ChatMessage(
          message: _chatController.text,
          id: _id,
          time: curTime,
          senderName: curUser,
          msgType: "txt",
          isMe: true,
        );
      }
      currentThread.addChat(obj);
      currentThread.save();

      if (SocketChannel.isConnected) {
        SocketChannel.sendToChannel(data);
      } else {
        print("not connected");
      }
      setState(() {
        replyingMsg = null;
        replyingMsgObj = null;
      });
      _chatController.text = "";
    }
  }

  void _sendAudio(String path) async {
    var _id = DateTime.now().microsecondsSinceEpoch;
    var curTime = DateTime.now();
    print(path);
    print("this is the path passed into this");
    ChatMessage obj;

    if (replyingMsgObj != null) {
      obj = ChatMessage(
          filePath: path,
          id: _id,
          time: curTime,
          senderName: curUser,
          msgType: "reply_aud",
          isMe: true,
          replyMsgId: replyingMsgObj.id,
          replyMsgTxt: replyingMsgObj.msgType == "txt"
              ? replyingMsgObj.message
              : (replyingMsgObj.msgType == "img")
                  ? imageUTF
                  : audioUTF);
    } else {
      obj = ChatMessage(
        filePath: path,
        id: _id,
        time: curTime,
        senderName: curUser,
        msgType: "aud",
        isMe: true,
      );
    }

    var threadBox = Hive.box('Threads');
    Thread currentThread = threadBox.get(threadName);
    currentThread.addChat(obj);
    currentThread.save();
    setState(() {
      replyingMsg = null;
      replyingMsgObj = null;
      refreshId += 1;
    });
    _chatController.text = "";
  }

  void _sendImage() async {
    var _id = DateTime.now().microsecondsSinceEpoch;
    var curTime = DateTime.now();
    FilePickerResult fetchedResult =
        await FilePicker.platform.pickFiles(withData: true);
    String ext = fetchedResult.files.single.path.split('.').last;
    String sentPath =
        '/storage/emulated/0/foo/images/sent/${DateTime.now().millisecondsSinceEpoch}.$ext';
    File result;
    if (fetchedResult.files.length > 0) {
      try {
        await Permission.storage.request();
        File(sentPath).createSync(recursive: true);
        File(fetchedResult.files.single.path).copySync(sentPath);
        result = File(sentPath);
      } catch (e) {
        print("Copy failed");
        return;
      }
      ChatMessage obj;
      File file = File(result.path);
      if (replyingMsgObj != null) {
        obj = ChatMessage(
            filePath: file.path,
            id: _id,
            time: curTime,
            senderName: curUser,
            msgType: "reply_img",
            isMe: true,
            replyMsgId: replyingMsgObj.id,
            replyMsgTxt: replyingMsgObj.msgType == "txt"
                ? replyingMsgObj.message
                : (replyingMsgObj.msgType == "img")
                    ? imageUTF
                    : audioUTF);
      } else {
        obj = ChatMessage(
            filePath: file.path,
            id: _id,
            time: curTime,
            senderName: curUser,
            msgType: "img",
            isMe: true);
      }
      var threadBox = Hive.box('Threads');
      Thread currentThread = threadBox.get(threadName);
      currentThread.addChat(obj);
      currentThread.save();
      setState(() {
        replyingMsg = null;
        replyingMsgObj = null;
      });
      _chatController.text = "";
    }
  }

  removeKey() {
    _prefs.setBool("${otherUser}_hasNew", false);
  }

  void showOverlay() {
    overlayVisible = true;
    OverlayState state = Overlay.of(context);
    entry = OverlayEntry(builder: (context) {
      return Positioned(
        bottom: 100,
        right: 30,
        child: GestureDetector(
          onTap: () {
            _prefs.setBool("${otherUser}_hasNew", false);
            overlayVisible = false;
            _scrollController.scrollTo(
                index: 0, duration: Duration(milliseconds: 400));
            // _scrollController.animateTo(
            //     _scrollController.position.minScrollExtent,
            //     duration: Duration(milliseconds: 100),
            //     curve: Curves.bounceIn);
            entry.remove();
          },
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.3),
                  offset: Offset(2, 5),
                  blurRadius: 10,
                )
              ],
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_drop_down_sharp,
              size: 30,
              color: Colors.pink[700],
            ),
          ),
        ),
      );
    });
    Future.delayed(Duration(milliseconds: 200), () {
      state.insert(entry);
    });
    // Future.delayed(Duration(seconds: 10), () {
    //   _prefs.setBool("${otherUser}_hasNew", false);
    //   print(_scrollController.offset);
    //   entry.remove();
    // });
    // Timer(Duration(se))
  }

  void sendTypingStarted() {
    var data = {
      'to': otherUser,
      'type': 'typing_status',
      'status': 'typing',
    };

    SocketChannel.sendToChannel(jsonEncode(data));
  }

  void sendTypingStopped() {
    var data = {
      'to': otherUser,
      'type': 'typing_status',
      'status': 'stopped',
    };

    SocketChannel.sendToChannel(jsonEncode(data));
  }

  //Fetches the preferences when the screen renders;
  void setPreferences() {
    String key = "am_i_hiding_last_seen_from_$otherUser";
    if (_prefs.containsKey(key)) {
      setState(() {
        hidingLastSeen = _prefs.getBool(key);
      });
    } else {
      _prefs.setBool(key, false);
      setState(() {
        hidingLastSeen = false;
      });
    }
  }

  //Changes the preferences;
  Future<void> changePreferences(bool val, Function innerSetState) async {
    String key = "am_i_hiding_last_seen_from_$otherUser";

    String action = "";
    if (val) {
      action = "add";
    } else {
      action = "remove";
    }
    var id = _prefs.getInt('id');
    try {
      var response = await http.get(Uri.http(localhost, '/api/last_seen',
          {'id': id.toString(), 'username': otherUser, 'action': action}));

      if (response.statusCode == 200) {
        _prefs.setBool(key, val);
        innerSetState(() {
          hidingLastSeen = val;
        });
      } else {
        CustomOverlay overlay = CustomOverlay(
            context: context, animationController: _animationController);
        overlay.show("Sorry. Something went wrong.\n Please try again later.");
      }
    } catch (e) {
      CustomOverlay overlay = CustomOverlay(
          context: context, animationController: _animationController);
      overlay.show("Sorry. Something went wrong.\n Please try again later.");
    }
  }

  deleteforMe() {
    var threadBox = Hive.box('Threads');
    Thread currentThread = threadBox.get(threadName);
    forwardedMsgs.forEach((key, value) {
      currentThread.deleteChat(key);
    });
    setState(() {
      isForwarding = false;
      forwardedMsgs.clear();
    });
    currentThread.save();
  }

  deleteForEveryone() {
    forwardedMsgs.forEach((key, value) {
      var data = jsonEncode({
        'type': "chat_delete",
        'id': value.id,
        'to': otherUser,
      });
      SocketChannel.sendToChannel(data);
    });
  }

  showDeletionSheet() {
    if (focusNode.hasFocus) focusNode.unfocus();
    bool _deleteForEveryone = false;
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setter) => AlertDialog(
              contentPadding: EdgeInsets.all(10),
              content: CheckboxListTile(
                activeColor: Colors.black,
                value: _deleteForEveryone,
                onChanged: (val) {
                  setter(() {
                    _deleteForEveryone = val;
                  });
                },
                title: Text("Delete for everyone",
                    style:
                        TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              ),
              title: Text(
                  (forwardedMsgs.length > 1)
                      ? "Do you want to delete these messages?"
                      : "Do you want to delete this message?",
                  style: GoogleFonts.lato(
                      fontWeight: FontWeight.w400, fontSize: 18)),
              actions: [
                TextButton(
                    onPressed: () {
                      if (_deleteForEveryone) {
                        if (SocketChannel.isConnected) {
                          deleteForEveryone();
                          deleteforMe();
                          Navigator.pop(context);
                        } else {
                          CustomOverlay overlay = CustomOverlay(
                              context: context,
                              animationController: _animationController);
                          overlay.show(
                              "Something went wrong.\n Please check your network connection and try again later");
                        }
                      } else {
                        deleteforMe();
                        Navigator.pop(context);
                      }
                    },
                    child: Text("Yes")),
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("No")),
              ],
            ),
          );
        });
    // showModalBottomSheet(
    //   context: context,
    //   builder: (context) {
    //     return Container(
    //       height: 300,
    //       child: Column(
    //         children: [
    //           Container(
    //             child: Text(
    //               "Settings",
    //               style: GoogleFonts.lato(
    //                 fontSize: 23,
    //                 fontWeight: FontWeight.w600,
    //               ),
    //             ),
    //             alignment: Alignment.centerLeft,
    //             margin: EdgeInsets.fromLTRB(20, 20, 0, 8),
    //           ),
    //           Divider(),
    //           Container(
    //             // height: 70,
    //             width: double.infinity,
    //             child: Row(
    //               children: [
    //                 Spacer(),
    //                 TextButton(
    //                   child: Text(
    //                     "Delete for me",
    //                     style: GoogleFonts.openSans(
    //                       fontSize: 16,
    //                     ),
    //                   ),
    //                   onPressed: () {
    //                     deleteforMe();
    //                     Navigator.pop(context);
    //                   },
    //                 ),
    //                 Spacer(flex: 4),
    //               ],
    //             ),
    //           ),
    //           Divider(),
    //           Container(
    //             // height: 70,
    //             width: double.infinity,
    //             child: Row(
    //               children: [
    //                 Spacer(),
    //                 TextButton(
    //                   child: Text(
    //                     "Delete for everyone",
    //                     style: GoogleFonts.openSans(
    //                       fontSize: 16,
    //                     ),
    //                   ),
    //                   onPressed: () {
    //                     if (SocketChannel.isConnected) {
    //                       deleteForEveryone();
    //                       deleteforMe();
    //                       Navigator.pop(context);
    //                     } else {
    //                       CustomOverlay overlay = CustomOverlay(
    //                           context: context,
    //                           animationController: _animationController);
    //                       overlay.show(
    //                           "Something went wrong.\n Please check your network connection and try again later");
    //                     }
    //                   },
    //                 ),
    //                 Spacer(flex: 4),
    //               ],
    //             ),
    //           ),
    //           Divider(),
    //         ],
    //       ),
    //     );
    //   },
    // );
  }

  //
  bool hidingLastSeen;

  showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, tester) {
          return Container(
            height: 300,
            child: Column(
              children: [
                Container(
                  child: Text(
                    "Settings",
                    style: GoogleFonts.lato(
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  margin: EdgeInsets.fromLTRB(20, 20, 0, 8),
                ),
                Divider(),
                Container(
                  // height: 70,
                  width: double.infinity,
                  child: Row(
                    children: [
                      Spacer(),
                      Text("Hide last seen",
                          style: GoogleFonts.openSans(
                            fontSize: 16,
                          )),
                      Spacer(flex: 4),
                      Switch(
                        value: hidingLastSeen,
                        onChanged: (val) => changePreferences(val, tester),
                      ),
                      Spacer(),
                    ],
                  ),
                ),
                Divider(),
              ],
            ),
          );
        });
      },
    );
  }

  void checkAndSendKeyboardStatus() {
    if (MediaQuery.of(context).viewInsets.bottom != 0) {
      if ((keyboardUp == false) || (keyboardUp == null)) {
        print("keyboard up");
        keyboardUp = true;
        sendTypingStarted();
      }
    } else {
      if (keyboardUp == true) {
        print("keyboard down");
        keyboardUp = false;
        sendTypingStopped();
      }
    }
  }

  swipingHandler(ChatMessage msgObj) {
    if (msgObj.msgType == "txt" || msgObj.msgType == "reply_txt") {
      setState(() {
        replyingMsgObj = msgObj;
        replyingMsg = ChatCloud(
          disableSwipe: true,
          msgObj: msgObj,
        );
      });
    } else if (msgObj.msgType == "img" || msgObj.msgType == "reply_img") {
      setState(() {
        replyingMsgObj = msgObj;
        replyingMsg = ImageThumb(
          msgObj: msgObj,
        );
      });
    } else if (msgObj.msgType == "aud" || msgObj.msgType == "reply_aud") {
      setState(() {
        replyingMsgObj = msgObj;
        replyingMsg = AudioCloud(
          disableSwipe: true,
          msgObj: msgObj,
        );
      });
    }
    if (!focusNode.hasFocus) {
      focusNode.requestFocus();
    }
  }

  forwardMessage([bool val = true]) {
    if (val == false) {
      if (isForwarding) {
        setState(() {
          isForwarding = false;
          forwardedMsgs = {};
        });
      }
    } else {
      setState(() {
        isForwarding = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    checkAndSendKeyboardStatus();
    return WillPopScope(
      onWillPop: () async {
        _prefs.setString("curUser", "");
        Navigator.pop(context);
        // Navigator.pushNamedAndRemoveUntil(
        // context, '/chatlist', (Route route) => route is ChatListScreen);
        // Navigator.push(context,);
        // if (isForwarding) {
        //   setState(() {
        //     isForwarding = false;
        //   });
        //   return false;
        // }
        return false;
      },
      child: Scaffold(
        extendBodyBehindAppBar: false,
        backgroundColor: Color.fromRGBO(240, 247, 255, 1),
        appBar: PreferredSize(
            preferredSize: Size(double.infinity, 100),
            child: SafeArea(
              child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    // gradient: LinearGradient(
                    //     begin: Alignment.topLeft,
                    //     end: Alignment.bottomRight,
                    //     stops: [
                    //       .3,
                    //       1
                    //     ],
                    //     colors: [
                    //       Color.fromRGBO(248, 251, 255, 1),
                    //       Color.fromRGBO(240, 247, 255, 1)
                    //     ]),
                    // borderRadius: BorderRadius.all(Radius.circular(10)),
                    // boxShadow: [
                    //   BoxShadow(
                    //     spreadRadius: 2,
                    //     blurRadius: 5,
                    //     offset: Offset(0, 3),
                    //     color: Color.fromRGBO(226, 235, 243, 1),
                    //   )
                  ),
                  child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Icon(Icons.arrow_back_rounded,
                                color: Colors.black, size: 23),
                          ),
                          Spacer(),
                          // CircleAvatar(
                          //   //child: Text(otherUser[0].toUpperCase()),
                          //   child: CachedNetworkImage(
                          //       errorWidget: (a, b, c) {
                          //         return Text(otherUser[0].toUpperCase());
                          //       },
                          //       imageUrl: widget.thread.second?.dpUrl),
                          //   radius: 20,
                          // ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                      pageBuilder: (context, animation,
                                              secAnimation) =>
                                          Profile(
                                              userId: thread.second?.userId),
                                      transitionsBuilder: (context, animation,
                                          secAnimation, child) {
                                        return SlideTransition(
                                          position: Tween<Offset>(
                                                  begin: Offset(1, 0),
                                                  end: Offset(0, 0))
                                              .animate(animation),
                                          child: child,
                                        );
                                      }));
                            },
                            child: Container(
                                height: 56,
                                width: 56,
                                //child: Text(this.thread.second.name[0].toUpperCase()),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: CachedNetworkImageProvider(
                                        thread.second.dpUrl == null
                                            ? ''
                                            : 'http://$localhost' +
                                                thread.second?.dpUrl,
                                      )),
                                )),
                          ),
                          Spacer(),
                          Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  otherUser,
                                  textAlign: TextAlign.left,
                                  textDirection: TextDirection.ltr,
                                  style: GoogleFonts.lato(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600),
                                ),
                                SizedBox(height: 6),
                                Text(userStatus,
                                    textDirection: TextDirection.ltr,
                                    textAlign: TextAlign.left,
                                    style: GoogleFonts.lato(
                                        fontSize: 11,
                                        color: Colors.grey.shade600)),
                              ]),
                          Spacer(flex: 7),
                          isForwarding
                              ? Container(
                                  width: 70,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      GestureDetector(
                                          onTap: showDeletionSheet,
                                          child: Icon(Icons.delete_rounded,
                                              size: 23)),
                                      GestureDetector(
                                          onTap: () {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ForwardScreen(
                                                  msgs: this.forwardedMsgs,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Icon(Icons.forward_rounded,
                                              size: 23)),
                                    ],
                                  ))
                              : GestureDetector(
                                  onTap: () => showSettings(context),
                                  child: Container(
                                      width: 70,
                                      // transform: Matrix4.identity()..rotateZ(pi / 2),
                                      // transformAlignment: Alignment.center,
                                      child: RotatedBox(
                                        quarterTurns: 3,
                                        child: Icon(icons.Feed.colon,
                                            color: Colors.black, size: 26),
                                      )
                                      // child: Icon(icons.Feed.colon,
                                      //     color: Colors.black, size: 20),
                                      ),
                                )
                        ],
                      ))),
            )),
        body: Column(children: <Widget>[
          Expanded(
            child: ValueListenableBuilder(
              key: ValueKey(0),
              valueListenable:
                  Hive.box("Threads").listenable(keys: [threadName]),
              // child: ChatCloudList(
              //   chatList: thread.chatList,
              //   curUser: curUser,
              //   otherUser: otherUser,
              //   prefs: _prefs,
              //   scrollController: _scrollController,
              // ),
              builder: (context, box, widget) {
                var thread = box.get(threadName);

                List __chatList = thread.chatList ?? [];

                if (_prefs.containsKey("${otherUser}_hasNew") &&
                    _prefs.getBool("${otherUser}_hasNew") &&
                    !overlayVisible) {
                  try {
                    if ((_itemPositionsListener
                                ?.itemPositions?.value?.last?.index >
                            15) ??
                        -1) {
                      showOverlay();
                    } else {
                      removeKey();
                    }
                  } catch (e) {
                    print(e);
                    removeKey();
                  }
                  //removeKey();
                  // if (_scrollController.hasClients) {
                  //   if ((_scrollController?.offset ?? 0) < 300) {
                  //     removeKey();
                  //   } else if (_scrollController.offset > 300) {
                  //     showOverlay();
                  //   }
                  // }
                }

                return ChatCloudList(
                    chatList: __chatList,
                    curUser: curUser,
                    otherUser: otherUser,
                    prefs: _prefs,
                    swipingHandler: swipingHandler,
                    positionsListener: _itemPositionsListener,
                    scrollController: _scrollController,
                    msgMap: forwardedMsgs,
                    forwardMsgHandler: forwardMessage);
              },
            ),
          ),
          Container(
              // height: 70,
              width: double.infinity,
              // color: Colors.black,
              color: Colors.transparent,
              child: Dismissible(
                key: UniqueKey(),
                direction: DismissDirection.startToEnd,
                onDismissed: (DismissDirection direction) {
                  setState(() {
                    replyingMsg = null;
                    replyingMsgObj = null;
                  });
                },
                confirmDismiss: (DismissDirection direction) {
                  setState(() {
                    replyingMsg = null;
                    replyingMsgObj = null;
                  });
                  return Future.value(true);
                },
                child: Container(
                  color: Colors.transparent,
                  child: Row(children: [
                    replyingMsg != null
                        ? Icon(Icons.reply_rounded)
                        : Container(),
                    replyingMsg ?? Container(),
                  ]),
                ),
              )),
          RecordApp(
            refreshId: refreshId,
            sendMessage: _sendMessage,
            sendImage: _sendImage,
            sendAudio: _sendAudio,
            focusNode: focusNode,
            prefs: widget.prefs,
          ),
        ]),
      ),
    );
  }
}

class RecordApp extends StatefulWidget {
  final Function sendMessage;
  final Function sendImage;
  final Function sendAudio;
  final FocusNode focusNode;
  final int refreshId;
  final SharedPreferences prefs;

  RecordApp(
      {this.sendMessage,
      this.sendImage,
      this.prefs,
      this.sendAudio,
      this.focusNode,
      this.refreshId});

  @override
  _RecordAppState createState() => _RecordAppState();
}

class _RecordAppState extends State<RecordApp>
    with SingleTickerProviderStateMixin {
  String path;
  File file;
  bool _isRecording = false;
  bool _hasTyped = false;
  bool _emojiVisible = false;
  bool _keyboardVisible = false;
  bool _isDarkMode = false;
  int _timeRemaining = 60;
  TextEditingController _chatController = TextEditingController();
  KeyboardVisibilityController _keyboardVisibilityController;
  AnimationController _animationController;
  Animation _colorTween;
  Timer _timer;
  FocusNode _chatFocus;
  bool hasSent = false;
  int curSec;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _colorTween = ColorTween(begin: Colors.black, end: Colors.red)
        .animate(_animationController);
    // ..addListener(() {
    //   setState(() {
    //     // any change that has to be here can be heres
    //   });
    // });
    _chatFocus = FocusNode();
    // ..addListener(() {
    //   if (!_chatFocus.hasFocus) {
    //     setState(() {
    //       _emojiVisible = false;
    //     });
    //   }
    // });
    _keyboardVisibilityController = KeyboardVisibilityController()
      ..onChange.listen((bool _keyboardVisible) {
        this._keyboardVisible = _keyboardVisible;

        if (_keyboardVisible && _emojiVisible) {
          setState(() {
            _emojiVisible = false;
          });
        }
      });
  }

  void animateMicColor() {
    _animationController.repeat(
        min: 0, max: 1, reverse: true, period: Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _chatFocus.dispose();
    _animationController.dispose();
    _chatController.dispose();

    // _keyboardVisibilityController.dispose()
    super.dispose();
  }

  void _startTimer() {
    const tick = const Duration(seconds: 1);
    _timeRemaining = 60;

    _timer?.cancel();

    _timer = Timer.periodic(tick, (Timer t) {
      setState(() {
        _timeRemaining--;
        if (_timeRemaining == 0) {
          _stopRecording();
          _isRecording = false;
        }
      });
    });
  }

  String _displayTime() {
    if (_timeRemaining > 0) {
      int minutes = _timeRemaining ~/ 60; // ~/ is integer division
      int seconds = _timeRemaining % 60;

      String minuteString = '$minutes';
      String secondString = (seconds > 9) ? '$seconds' : '0$seconds';

      return '$minuteString:$secondString';
    }
    return "0:00";
  }

  Future<void> _startRecording() async {
    _startTimer();
    animateMicColor();
    dynamic appDir = await getApplicationDocumentsDirectory();
    curSec = DateTime.now().millisecondsSinceEpoch;
    path = appDir.path + '/Audio/' + curSec.toString() + '.m4a';
    File(path).createSync(recursive: true);
    try {
      if (await Record.hasPermission()) {
        widget.prefs.setInt('lastAudio', curSec);
        await Record.start(path: path);

        _isRecording = await Record.isRecording();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _stopRecording() async {
    print("calling stop");
    await Record.stop();
    // String _path = await recorder.stopRecorder();
    if ((widget.prefs.getInt('lastAudio') == curSec) && _timeRemaining <= 59) {
      print("sending");
      widget.prefs.setInt('lastAudio', curSec + 1);
      widget.sendAudio(path);
    }
  }

  Future<void> _cancelRecording() async {
    await Record.stop();

    file = File(path);
    print(file.path);
    file.delete();
  }

  Widget myTextBox() {
    return Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10), topRight: Radius.circular(10)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: _emojiVisible
                    ? Icon(Icons.keyboard)
                    : Icon(Icons.emoji_emotions_outlined),
                onPressed: onClickedEmoji, //_toggleEmoji
                splashColor: Colors.pinkAccent,
                splashRadius: 16,
                padding: EdgeInsets.fromLTRB(0, 0, 0, 16),
              ),
              Expanded(
                child: TextField(
                  focusNode: widget.focusNode,
                  controller: _chatController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration.collapsed(
                      hintText: "Send a message",
                      hintStyle: TextStyle(
                        color: Color.fromRGBO(150, 150, 150, 1),
                      )),
                  onChanged: (typedword) {
                    if (typedword == '')
                      setState(() {
                        _hasTyped = false;
                      });
                    else
                      setState(() {
                        _hasTyped = true;
                      });
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.image_outlined),
                onPressed: () {
                  widget.sendImage();
                  setState(() {
                    _hasTyped = false;
                  });
                },
                splashColor: Colors.pinkAccent,
                splashRadius: 16,
                padding: EdgeInsets.fromLTRB(0, 0, 0, 16),
              ),
              (_hasTyped)
                  ? IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () {
                        widget.sendMessage(_chatController);
                        setState(() {
                          _hasTyped = false;
                        });
                      },
                      splashColor: Colors.pinkAccent,
                      splashRadius: 16,
                      padding: EdgeInsets.fromLTRB(0, 0, 0, 16),
                    )
                  : IconButton(
                      icon: Icon(Icons.mic),
                      onPressed: () {
                        setState(() {
                          _isRecording = true;
                        });
                        _startRecording();
                      },
                      splashColor: Colors.pinkAccent,
                      splashRadius: 16,
                      padding: EdgeInsets.fromLTRB(0, 0, 0, 16),
                    )
            ],
          ),
        ));
  }

  Widget myAudioBox() {
    return Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10), topRight: Radius.circular(10)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeIn,
                child: Icon(
                  Icons.mic,
                  color: _colorTween.value,
                ),
              ),
              Expanded(
                child: Container(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(_displayTime()),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _cancelRecording();
                    _isRecording = false;
                  });
                },
                child: Text("Cancel"),
              ),
              IconButton(
                icon: Icon(Ionicons.send_outline),
                onPressed: () {
                  setState(() {
                    _isRecording = false;
                  });
                  _stopRecording();
                },
                splashColor: Colors.pinkAccent,
                splashRadius: 16,
                padding: EdgeInsets.fromLTRB(0, 0, 0, 16),
              ),
            ],
          ),
        ));
  }

  Widget myEmojiKeyBoard() => EmojiPicker(
        onEmojiSelected: (category, emoji) {
          String text = _chatController.text;
          TextSelection textSelection = _chatController.selection;
          if (textSelection.extentOffset == -1) {
            //Before first selection
            _chatController.text += emoji.emoji;
          } else {
            String newText = text.replaceRange(
                textSelection.start, textSelection.end, emoji.emoji);
            final emojiLength = emoji.emoji.length;
            _chatController.text = newText;
            _chatController.selection = textSelection.copyWith(
              baseOffset: textSelection.start + emojiLength,
              extentOffset: textSelection.start + emojiLength,
            );
          }
          setState(() {
            _hasTyped = true;
          });
        },
        config: Config(
            columns: 7,
            emojiSizeMax: 32.0,
            verticalSpacing: 0,
            horizontalSpacing: 0,
            initCategory: Category.RECENT,
            bgColor: _isDarkMode
                ? Color.fromARGB(255, 16, 28, 37)
                : Color.fromARGB(255, 234, 238, 242),
            indicatorColor: Colors.blue,
            iconColor: Colors.grey,
            iconColorSelected: Colors.blue,
            progressIndicatorColor: Colors.blue,
            showRecentsTab: true,
            recentsLimit: 28,
            noRecentsText: "No Recents",
            noRecentsStyle: _isDarkMode
                ? const TextStyle(fontSize: 20, color: Colors.white24)
                : const TextStyle(fontSize: 20, color: Colors.black26),
            categoryIcons: const CategoryIcons(),
            buttonMode: ButtonMode.MATERIAL),
      );

  onClickedEmoji() async {
    setState(() {
      _emojiVisible = !_emojiVisible;
    });
    if (_emojiVisible) {
      await SystemChannels.textInput.invokeMethod('TextInput.hide');
      await Future.delayed(Duration(milliseconds: 100));
    } else {
      await SystemChannels.textInput.invokeMethod('TextInput.show');
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  @override
  Widget build(BuildContext context) {
    var brightness = SchedulerBinding.instance.window.platformBrightness;
    setState(() {
      _isDarkMode = brightness == Brightness.dark;
    });
    return WillPopScope(
      onWillPop: () async {
        if (_emojiVisible)
          setState(() {
            _emojiVisible = false;
          });
        else
          Navigator.pop(context);

        return false;
      },
      child: Column(
        children: [
          _isRecording ? myAudioBox() : myTextBox(),
          (_emojiVisible)
              ? Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.35,
                  child: myEmojiKeyBoard(),
                )
              : Container(),
        ],
      ),
    );
  }
}

class ImageThumb extends StatelessWidget {
  final ChatMessage msgObj;
  ImageThumb({this.msgObj});

  FutureOr getImage() async {
    if (await File(this.msgObj.filePath).exists()) {
      return File(this.msgObj.filePath);
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      width: 70,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: FutureBuilder(
            future: getImage(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.data == null) {
                  return Container(
                    width: 70,
                    child: Row(
                      children: [Icon(Ionicons.image_outline), Text("Image")],
                    ),
                  );
                }
                return Image.file(snapshot.data, fit: BoxFit.cover);
              }
              return Container();
            }),
      ),
    );
  }
}
