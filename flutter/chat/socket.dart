import 'dart:io';
import 'dart:async';

class NotificationController {

  static final NotificationController _singleton = new NotificationController._internal();

  static StreamController streamController = new StreamController.broadcast(sync: true);

  String wsUrl = 'ws://10.0.2.2:8000/ws/chat_room/romal/';

  static WebSocket channel;
  static bool isActive = false;

  factory NotificationController() {
    return _singleton;
  }

  NotificationController._internal() {
    initWebSocketConnection();
  }

  initWebSocketConnection() async {
    print("conecting...");
    if(NotificationController.isActive==false){
    channel = await connectWs();
    NotificationController.isActive= true;
    print("socket connection initializied");
    channel.done.then((dynamic _) => _onDisconnected());
    broadcastNotifications();
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
     NotificationController.isActive=false;
      print('Server error: $e');
      initWebSocketConnection();
    });
  }

  static sendToChannel(data){
    if(NotificationController.isActive==true){
    channel.add(data);
    }
    else{
      return false;
    }
  }

  connectWs() async{
    try {
      return await WebSocket.connect(wsUrl);
    } catch  (e) {
      NotificationController.isActive=false;
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