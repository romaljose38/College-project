import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:foo/test_cred.dart';
import 'chatcloudlist.dart';
import 'socket.dart';
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

class ChatScreen extends StatefulWidget {
  // final NotificationController controller;
  final Thread thread;

  ChatScreen(
      {Key key,
      // this.controller,
      this.thread})
      : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String curUser;
  String otherUser;
  String threadName;
  TextEditingController _chatController = TextEditingController();
  Thread thread;
  SharedPreferences _prefs;
  Timer timer;
  String userStatus = "Offline";

  @override
  void initState() {
    super.initState();
    otherUser = widget.thread.second.name;
    curUser = widget.thread.first.name;
    threadName = widget.thread.first.name + "_" + widget.thread.second.name;
    //Initializing the _chatList as the chatList of the current thread
    thread = Hive.box('threads').get(threadName);

    _getUserName();
    timer = Timer.periodic(Duration(seconds: 5), (Timer t) => obtainStatus());
  }

  @override
  void dispose() {
    super.dispose();
    timer.cancel();
    _chatController.dispose();
  }

  Future<void> obtainStatus() async {
    var resp = await http
        .get(Uri.http(localhost, '/api/get_status', {"username": otherUser}));
    if (resp.statusCode == 200) {
      Map body = jsonDecode(resp.body);
      if (body['status'] == "online") {
        if (userStatus != "Online") {
          setState(() {
            userStatus = "Online";
          });
        }
      } else {
        DateTime time = DateTime.parse(body['status']);
        print(time.toString());
        setState(() {
          userStatus = timeago.format(time);
        });
      }
    }
  }

  void _getUserName() async {
    _prefs = await SharedPreferences.getInstance();
    // curUser = _prefs.getString('username');
    _prefs.setString("curUser", otherUser);
  }

  void _sendMessage(TextEditingController _chatController) {
    var _id = DateTime.now().microsecondsSinceEpoch;
    var curTime = DateTime.now();
    // print(widget.channel.protocol);
    var data = jsonEncode({
      'message': _chatController.text,
      'id': _id,
      'time': curTime.toString(),
      'from': curUser,
      'to': otherUser,
      'type': 'msg',
    });
    if (_chatController.text.isNotEmpty) {
      var threadBox = Hive.box('Threads');

      Thread currentThread = threadBox.get(threadName);
      currentThread.addChat(ChatMessage(
        message: _chatController.text,
        id: _id,
        time: curTime,
        senderName: curUser,
        msgType: "txt",
        isMe: true,
      ));
      currentThread.save();

      if (NotificationController.isActive) {
        NotificationController.sendToChannel(data);
      } else {
        print("not connected");
      }
      _chatController.text = "";
    }
  }

  void _sendAudio(String path) async {
    var _id = DateTime.now().microsecondsSinceEpoch;
    var curTime = DateTime.now();
    File file = File(path);
    String _extension = path.split('.').last;
    var bytes = await file.readAsBytes();
    String audString = base64Encode(bytes);
    print(audString);

    var data = jsonEncode({
      'type': 'aud',
      'ext': _extension,
      'audio': audString,
      'from': curUser,
      'id': _id,
      'to': otherUser,
      'time': curTime.toString(),
    });
    print(data);
    if (NotificationController.isActive) {
      var threadBox = Hive.box('Threads');

      Thread currentThread = threadBox.get(threadName);
      currentThread.addChat(ChatMessage(
        filePath: file.path,
        id: _id,
        time: curTime,
        base64string: audString,
        senderName: curUser,
        msgType: "aud",
        isMe: true,
      ));
      currentThread.save();
      NotificationController.sendToChannel(data);
    }
  }

  void _sendImage() async {
    var _id = DateTime.now().microsecondsSinceEpoch;
    var curTime = DateTime.now();
    FilePickerResult result =
        await FilePicker.platform.pickFiles(withData: true);
    File file = File(result.files.single.path);
    String _extension = result.files.single.extension;
    var bytes = result.files.single.bytes;
    print(bytes);
    Directory appDir = await getApplicationDocumentsDirectory();
    String path = appDir.path +
        '/images/sent/' +
        '${curUser}_${otherUser}_${curTime.toString()}' +
        '.$_extension';
    File(path).createSync(recursive: true);
    File savedFile = await file.copy(path);

    print(savedFile.path);

    String imgString = base64Encode(bytes);
    print(imgString);

    var data = jsonEncode({
      'type': 'img',
      'ext': _extension,
      'image': imgString,
      'from': curUser,
      'id': _id,
      'to': otherUser,
      'time': curTime.toString(),
    });
    print(data);
    if (NotificationController.isActive) {
      var threadBox = Hive.box('Threads');

      Thread currentThread = threadBox.get(threadName);
      currentThread.addChat(ChatMessage(
        filePath: savedFile.path,
        id: _id,
        time: curTime,
        base64string: imgString,
        senderName: curUser,
        msgType: "img",
        isMe: true,
      ));
      currentThread.save();
      NotificationController.sendToChannel(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _prefs.setString("curUser", "");
        return true;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Color.fromRGBO(240, 247, 255, 1),
        appBar: PreferredSize(
            preferredSize: Size(double.infinity, 100),
            child: SafeArea(
              child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: [
                            .3,
                            1
                          ],
                          colors: [
                            Color.fromRGBO(248, 251, 255, 1),
                            Color.fromRGBO(240, 247, 255, 1)
                          ]),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      boxShadow: [
                        BoxShadow(
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                          color: Color.fromRGBO(226, 235, 243, 1),
                        )
                      ]),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ValueListenableBuilder(
                                    valueListenable: Hive.box("Threads")
                                        .listenable(keys: [threadName]),
                                    builder: (context, box, widget) {
                                      var existingThread = box.get(threadName);

                                      return Text(
                                        existingThread.isTyping == true
                                            ? "typing..."
                                            : userStatus,
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: Color.fromRGBO(
                                                180, 190, 255, 1)),
                                      );
                                    }),
                                SizedBox(height: 7),
                                Text(widget.thread.second.name,
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromRGBO(59, 79, 108, 1)))
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: CircleAvatar(
                              radius: 35,
                              child: Text(widget.thread.second.name),
                            ),
                          )
                        ]),
                  )),
            )),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
          child: Column(children: <Widget>[
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box("Threads").listenable(),
                builder: (context, box, widget) {
                  var thread = box.get(threadName);

                  List __chatList = thread.chatList ?? [];

                  return ChatCloudList(
                      chatList: __chatList,
                      needScroll: (__chatList.length == 0) ? false : true,
                      curUser: curUser,
                      otherUser: otherUser,
                      prefs: _prefs);
                },
              ),
            ),
            RecordApp(
              sendMessage: _sendMessage,
              sendImage: _sendImage,
              sendAudio: _sendAudio,
              otherUser: otherUser,
            ),
          ]),
        ),
      ),
    );
  }
}

class RecordApp extends StatefulWidget {
  final Function sendMessage;
  final Function sendImage;
  final Function sendAudio;
  final String otherUser;

  RecordApp({this.sendMessage, this.sendImage, this.sendAudio, this.otherUser});

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
        if (_keyboardVisible) {
          sendTypingStarted();
          print("typing thudangi");
        } else {
          sendTypingStopped();
          print("typing theernnu");
        }
        if (_keyboardVisible && _emojiVisible) {
          setState(() {
            _emojiVisible = false;
          });
        }
      });
  }

  void sendTypingStarted() {
    var data = {
      'to': widget.otherUser,
      'type': 'typing_status',
      'status': 'typing',
    };

    NotificationController.sendToChannel(jsonEncode(data));
  }

  void sendTypingStopped() {
    var data = {
      'to': widget.otherUser,
      'type': 'typing_status',
      'status': 'stopped',
    };

    NotificationController.sendToChannel(jsonEncode(data));
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
    path = appDir.path +
        '/Audio/' +
        DateTime.now().millisecondsSinceEpoch.toString() +
        '.m4a';
    File(path).createSync(recursive: true);
    try {
      if (await Record.hasPermission()) {
        await Record.start(path: path);

        _isRecording = await Record.isRecording();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _stopRecording() async {
    await Record.stop();

    file = File(path);
    print(file.path);
    widget.sendAudio(file.path);
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
                  controller: _chatController,
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
                icon: Icon(Icons.send),
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
