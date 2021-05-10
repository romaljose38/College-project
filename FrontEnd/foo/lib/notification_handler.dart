import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> showNotification(String content, String user) async {
  SharedPreferences _prefs = await SharedPreferences.getInstance();
  int notifIndex;
  if (_prefs.containsKey("notif_key")) {
    notifIndex = _prefs.getInt("notif_key");
  } else {
    _prefs.setInt("notif_key", 0);
    notifIndex = 0;
  }
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'your channel id',
    'your channel name',
    'your channel description',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
  );
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.show(notifIndex,
      'You have a new message from $user', content, platformChannelSpecifics,
      payload: 'item x');

  _prefs.setInt("notif_key", notifIndex + 1);
}

class LocalNotificationHandler {
  static final LocalNotificationHandler _handler =
      LocalNotificationHandler.init();
  SharedPreferences _prefs;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'your channel id',
    'your channel name',
    'your channel description',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
  );

  factory LocalNotificationHandler() {
    return _handler;
  }

  LocalNotificationHandler.init() {
    setPrefs();
  }

  Future<void> setPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  int _getIndex() {
    int notifIndex;
    if (_prefs.containsKey("notif_key")) {
      notifIndex = _prefs.getInt("notif_key");
    } else {
      _prefs.setInt("notif_key", 0);
      notifIndex = 0;
    }
    return notifIndex;
  }

  void _incrementIndex(index) {
    _prefs.setInt("notif_key", index + 1);
  }

  Future<void> chatNotif(String user, String content) async {
    int index = this._getIndex();
    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(index,
        'You have a new message from $user', content, platformChannelSpecifics,
        payload: 'item x');
    this._incrementIndex(index);
  }

  Future<void> friendRequestNotif(String user) async {
    int index = this._getIndex();
    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(index,
        'You have a friend request from $user', "", platformChannelSpecifics,
        payload: 'item x');
    this._incrementIndex(index);
  }
}
