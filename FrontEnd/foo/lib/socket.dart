import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:foo/models.dart';
import 'package:foo/test_cred.dart';
import 'package:http/http.dart' as http;
import 'package:foo/notification_handler.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SocketChannel {
  static final SocketChannel socket = SocketChannel._internal();

  static WebSocket channel;
  LocalNotificationHandler _handler = LocalNotificationHandler();
  String username;
  Timer _timer;
  SharedPreferences _prefs;
  static bool isConnected = false;

  factory SocketChannel() {
    return socket;
  }

  SocketChannel._internal() {
    setPrefs();
    _timer = Timer.periodic(Duration(seconds: 10), (timer) => handleSocket());
  }

  Future<void> setPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

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
      _updateChatStatus(data);
    } else if (data.containsKey("r_s")) {
      _updateReachedServerStatus(
          id: data['r_s']['id'],
          newId: data['r_s']['n_id'],
          name: data['r_s']['to']);
    } else if (data['type'] == 'chat_message') {
      if ((_prefs.containsKey('lastMsgId') &&
              (_prefs.getInt('lastMsgId') != data['message']['id'])) ||
          !_prefs.containsKey('lastMsgId')) {
        _prefs.setInt("lastMsgId", data['message']['id']);

        print(data['message']['id']);
        sendToChannel(jsonEncode({'received': data['message']['id']}));
        _createThread(data);
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
    String me = _prefs.getString('username');
    String threadName = me + '_' + data['from'];
    var threadBox = Hive.box('Threads');
    var existingThread = threadBox.get(threadName);
    existingThread.updateChatSeenStatus(data['id']);
    existingThread.save();
    sendToChannel(jsonEncode({'n_r': data['notif_id']}));
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

  void _updateChatStatus(data) {
    int id = data['received'];
    String name = data['from'];
    String me = _prefs.getString('username');
    String threadName = me + '_' + name;
    var threadBox = Hive.box('Threads');
    var existingThread = threadBox.get(threadName);
    existingThread.updateChatStatus(id);
    existingThread.save();
    sendToChannel(jsonEncode({'n_r': data['notif_id']}));
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
        time: DateTime.parse(data['message']['time']),
        isMe: false,
        msgType: 'txt',
        id: data['message']['id'],
      ));
    } else if (data['msg_type'] == 'img') {
      thread.addChat(ChatMessage(
        base64string: data['message']['img'],
        senderName: data['message']['from'],
        msgType: 'img',
        time: DateTime.parse(data['message']['time']),
        isMe: false,
        id: data['message']['id'],
      ));
    } else if (data['msg_type'] == 'aud') {
      thread.addChat(ChatMessage(
        base64string: data['message']['aud'],
        senderName: data['message']['from'],
        msgType: 'aud',
        time: DateTime.parse(data['message']['time']),
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

      String currentUser = _prefs.getString("curUser");

      if (currentUser != data['message']['from']) {
        _handler.chatNotif(data['message']['from'], data['message']['message']);
        if (existingThread.hasUnseen != null) {
          existingThread.hasUnseen += 1;
        } else {
          existingThread.hasUnseen = 1;
        }
      } else if (currentUser == data['message']['from']) {
        print("here");
        var seenTicker = {
          "type": "seen_ticker",
          "to": data['message']['from'],
          "id": data['message']['id'],
        };
        sendToChannel(jsonEncode(seenTicker));
      }

      // else{
      //   existingThread.hasUnseen=true;
      // }
      if (data['msg_type'] == 'txt') {
        existingThread.addChat(ChatMessage(
          message: data['message']['message'],
          senderName: data['message']['from'],
          time: DateTime.parse(data['message']['time']),
          isMe: false,
          msgType: "txt",
          id: data['message']['id'],
        ));
      } else if (data['msg_type'] == 'aud') {
        existingThread.addChat(ChatMessage(
          base64string: data['message']['aud'],
          senderName: data['message']['from'],
          time: DateTime.parse(data['message']['time']),
          ext: data['message']['ext'],
          msgType: "aud",
          isMe: false,
          id: data['message']['id'],
        ));
      } else if (data['msg_type'] == 'img') {
        existingThread.addChat(ChatMessage(
          base64string: data['message']['img'],
          senderName: data['message']['from'],
          time: DateTime.parse(data['message']['time']),
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
