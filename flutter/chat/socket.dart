import 'dart:io';
import 'dart:async';

class NotificationController {

  static final NotificationController _singleton = new NotificationController._internal();

  StreamController streamController = new StreamController.broadcast(sync: true);

  String wsUrl = 'ws://10.0.2.2:8000/ws/test_room/';

  WebSocket channel;
  bool isActive;

  factory NotificationController() {
    return _singleton;
  }

  NotificationController._internal() {
    initWebSocketConnection();
  }

  initWebSocketConnection() async {
    print("conecting...");
    this.channel = await connectWs();
    this.isActive= true;
    print("socket connection initializied");
    this.channel.done.then((dynamic _) => _onDisconnected());
    broadcastNotifications();
  }

  broadcastNotifications() {
    this.channel.listen((streamData) {
      streamController.add(streamData);
    }, onDone: () {
      this.isActive = false;
      print("conecting aborted");
       initWebSocketConnection();
    }, onError: (e) {
      this.isActive=false;
      print('Server error: $e');
      initWebSocketConnection();
    });
  }

  sendToChannel(data){
    if(this.isActive){
    this.channel.add(data);
    }
    else{
      return false;
    }
  }

  connectWs() async{
    try {
      return await WebSocket.connect(wsUrl);
    } catch  (e) {
      this.isActive=false;
      print("Error! can not connect WS connectWs " + e.toString());
      await Future.delayed(Duration(milliseconds: 10000));
      return await connectWs();
    }

  }

  void _onDisconnected() {
    this.isActive = false;
    initWebSocketConnection();
  }
}