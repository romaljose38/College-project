import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:foo/models.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foo/test_cred.dart';

class NotificationController {
  static final NotificationController _singleton =
      new NotificationController._internal();

  static StreamController streamController =
      new StreamController.broadcast(sync: true);

  String wsUrl = 'ws://$localhost/ws/chat_room/';

  String username;
  SharedPreferences prefs;

  static WebSocket channel;
  static bool isActive = false;

  factory NotificationController() {
    return _singleton;
  }

  NotificationController._internal() {
    initWebSocketConnection();
  }

  getUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    this.prefs = prefs;
    this.username = prefs.getString('username');
  }

  initWebSocketConnection() async {
    print("conecting...");
    if (NotificationController.isActive == false) {
      channel = await connectWs();

      NotificationController.isActive = true;
      print("socket connection initializied");
      channel.done.then((dynamic _) => _onDisconnected());
      getPendingMessages();
      broadcastNotifications();
    }
  }

  getPendingMessages() {
    List msgList = [];
    var threadList = Hive.box("Threads").values.toList();
    threadList.forEach((e) {
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
              'from': this.username,
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
      print(jsonDecode(streamData).runtimeType);
      streamController.add(streamData);
    }, onDone: () {
      NotificationController.isActive = false;
      print("conecting aborted");
      initWebSocketConnection();
    }, onError: (e) {
      NotificationController.isActive = false;
      print('Server error: $e');
      initWebSocketConnection();
    });
  }

  dataHandler(data) {
    if (data.containsKey('received')) {
      print(data);
      _updateChatStatus(data['received'], data['name']);
    } else if (data.containsKey("r_s")) {
      _updateReachedServerStatus(
          id: data['r_s']['id'],
          newId: data['r_s']['n_id'],
          name: data['r_s']['to']);
    } else if (data['type'] == 'chat_message') {
      if ((prefs.containsKey('lastMsgId') &
              (prefs.getInt('lastMsgId') != data['message']['id'])) |
          !prefs.containsKey('lastMsgId')) {
        prefs.setInt("lastMsgId", data['message']['id']);
        if (data['message']['to'] == prefs.getString('username')) {
          print(data['message']['id']);

          _createThread(data);
          sendToChannel(jsonEncode({'received': data['message']['id']}));
        }
      }
    } else if (data['type'] == 'notification') {
      addNotification(data);
    }
  }

  void addNotification(data) async {
    if ((prefs.containsKey('lastNotifId') &
            (prefs.getInt('lastNotifId') != data['id'])) |
        !prefs.containsKey('lastNotifId')) {
      prefs.setInt("lastNotifId", data['id']);
      DateTime curTime = DateTime.now();
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
    String me = prefs.getString('username');
    String threadName = me + '_' + name;
    var threadBox = Hive.box('Threads');
    var existingThread = threadBox.get(threadName);
    existingThread.updateChatId(id: id, newId: newId);
    existingThread.save();
  }

  void _updateChatStatus(int id, String name) {
    String me = prefs.getString('username');
    String threadName = me + '_' + name;
    var threadBox = Hive.box('Threads');
    var existingThread = threadBox.get(threadName);
    existingThread.updateChatStatus(id);
    existingThread.save();
  }

  _chicanery(threadName, thread, data) async {
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
    thread.save();
  }

  Future _createThread(data) async {
    if (data == "None") {
      return null;
    }
    var threadBox = Hive.box('Threads');
    var me = prefs.getString('username');

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
      print("existing thread");
      print(data['message']['id']);
      var existingThread = threadBox.get(threadName);
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
    if (NotificationController.isActive == true) {
      channel.add(data);
    } else {
      return false;
    }
  }

  connectWs() async {
    await getUserName();
    try {
      if (NotificationController.isActive == false) {
        return await WebSocket.connect(wsUrl + this.username + '/');
      }
    } catch (e) {
      NotificationController.isActive = false;
      print("Error! can not connect WS connectWs " + e.toString());
      await Future.delayed(Duration(milliseconds: 10000));
      return await connectWs();
    }
  }

  void _onDisconnected() {
    NotificationController.isActive = false;
    initWebSocketConnection();
  }
}
