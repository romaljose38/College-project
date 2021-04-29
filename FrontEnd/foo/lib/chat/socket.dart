import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationController {
  static final NotificationController _singleton =
      new NotificationController._internal();

  static StreamController streamController =
      new StreamController.broadcast(sync: true);

  String wsUrl = 'ws://10.0.2.2:8000/ws/chat_room/';

  String username;

  static WebSocket channel;
  static bool isActive = false;

  factory NotificationController() {
    return _singleton;
  }

  NotificationController._internal() {
    getUserName();
    initWebSocketConnection();
  }

  getUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
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

  static sendToChannel(data) {
    if (NotificationController.isActive == true) {
      channel.add(data);
    } else {
      return false;
    }
  }

  connectWs() async {
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
