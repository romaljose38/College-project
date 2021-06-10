import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:foo/models.dart';
import 'package:foo/test_cred.dart';
import 'package:http/http.dart' as http;
import 'package:foo/notification_handler.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundpool/soundpool.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;

class SocketChannel {
  static final SocketChannel socket = SocketChannel._internal();

  static WebSocket channel;
  LocalNotificationHandler _handler = LocalNotificationHandler();
  String username;
  Timer _timer;
  SharedPreferences _prefs;
  Timer _localTimer;
  // AudioCache cache = AudioCache(respectSilence: true);
  static bool isConnected = false;
  Soundpool _pool = Soundpool.fromOptions(
      options: SoundpoolOptions(streamType: StreamType.notification));
  int soundId;

  factory SocketChannel() {
    return socket;
  }

  // playAudio() async {
  //   await cache.play('sounds/notification.wav',
  //       isNotification: true, mode: PlayerMode.LOW_LATENCY, duckAudio: true);
  // }

  soundPoolinit() async {
    soundId = await rootBundle
        .load("assets/sounds/notification.wav")
        .then((ByteData soundData) {
      return _pool.load(soundData);
    });
    print("soundpool initialized");
    print(soundId);
  }

  SocketChannel._internal() {
    soundPoolinit();
    setPrefs();
    _localTimer = Timer.periodic(Duration(seconds: 5), (timer) => localCheck());
  }

  ///Timer to run the local checkup
  localCheck() {
    if (!isConnected && !(_timer?.isActive ?? false)) {
      print("sanm poi");
      _timer = Timer.periodic(Duration(seconds: 5), (timer) => handleSocket());
    }
  }
  //

  Future<void> setPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> handleSocket() async {
    try {
      var resp = await http.get(Uri.http(localhost, '/api/ping'));
      if (resp.statusCode == 200) {
        if (!isConnected) {
          await setPrefs();
          String wsUrl = 'ws://$localhost:8000/ws/chat_room/' +
              _prefs.getInt("uprn").toString() +
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
    _timer.cancel();
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
          } else if (e.msgType == "reply_txt") {
            var data = jsonEncode({
              'message': e.message,
              'id': e.id,
              'time': e.time.toString(),
              'to': senderName,
              'type': 'reply_txt',
              'reply_id': e.replyMsgId,
              'reply_txt': e.replyMsgTxt,
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
      if (!_timer.isActive) {
        _timer =
            Timer.periodic(Duration(seconds: 10), (timer) => handleSocket());
      }
    }, onError: (e) {
      isConnected = false;
      print('Server error: $e');
      if (!_timer.isActive) {
        _timer =
            Timer.periodic(Duration(seconds: 10), (timer) => handleSocket());
      }
    });
  }

  dataHandler(data) {
    if (data.containsKey('received')) {
      _updateChatStatus(data);
    } else if (data.containsKey("r_s")) {
      _updateReachedServerStatus(data);
    } else if (data['type'] == 'chat_message') {
      if ((_prefs.containsKey('lastMsgId') &&
              (_prefs.getInt('lastMsgId') != data['message']['id'])) ||
          !_prefs.containsKey('lastMsgId')) {
        _prefs.setInt("lastMsgId", data['message']['id']);

        print(data['message']['id']);
        sendToChannel(jsonEncode({'received': data['message']['id']}));
        _createThread(data);
      }
    } else if (data['type'] == 'chat_reply_message') {
      if ((_prefs.containsKey('lastMsgId') &&
              (_prefs.getInt('lastMsgId') != data['message']['id'])) ||
          !_prefs.containsKey('lastMsgId')) {
        _prefs.setInt("lastMsgId", data['message']['id']);

        sendToChannel(jsonEncode({'received': data['message']['id']}));
        _createReplyThread(data);
      }
    } else if (data['type'] == 'notification') {
      addNotification(data);
    } else if (data['type'] == 'seen_ticker') {
      updateMsgSeenStatus(data);
    } else if (data['type'] == 'typing_status') {
      updateTypingStatus(data);
    } else if (data['type'] == 'story_add') {
      addNewStory(data);
    } else if (data['type'] == 'online_status') {
      changeUserStatus(data);
    } else if (data['type'] == 'story_view') {
      addStoryView(data);
    } else if (data['type'] == 'story_comment') {
      addStoryComment(data);
    } else if (data['type'] == 'story_delete') {
      deleteOldStory(data);
    } else if (data['type'] == 'chat_delete') {
      deleteChat(data);
    } else if (data['type'] == 'mention_notif') {
      addMentionNotification(data);
    } else if (data['type'] == 'frnd_req_acpt') {
      addFrndReqAcceptNotification(data);
    } else if (data['type'] == 'dp_update') {
      removeDpFromCache(data);
    } else if (data['type'] == 'like_notif') {
      addLikeNotification(data);
    }
  }

  Future<void> addLikeNotification(data) async {
    _prefs.setBool("hasNotif", true);
    var notif = Notifications(
        type: NotificationType.postLike,
        userId: data['id'],
        userDpUrl: data['dp'],
        userName: data['u'],
        timeCreated: DateTime.parse(data['time']));
    var notifBox = await Hive.openBox('Notifications');
    await notifBox.put(data['notif_id'], notif);
    notif.save();
    sendToChannel(jsonEncode({'m_r': data['notif_id']}));
    _prefs.setBool("hasNotif", true);
  }

  Future<void> addFrndReqAcceptNotification(data) async {
    _prefs.setBool("hasNotif", true);
    var user_id = data['id'];
    var notif = Notifications(
      type: NotificationType.friendRequest,
      userId: user_id,
      userName: data['u'],
      userDpUrl: data['dp'],
      timeCreated: DateTime.parse(data['time']),
    );
    notif.hasAccepted = true;
    var notifBox = await Hive.openBox('Notifications');
    await notifBox.put(data['notif_id'], notif);
    notif.save();
    sendToChannel(jsonEncode({'a_r': data['notif_id']}));
  }

  Future<void> removeDpFromCache(data) async {
    var id = data['id'];
    var url = 'http://' + localhost + '/media/user_$id/profile/dp.jpg';
    await CachedNetworkImage.evictFromCache(url);

    sendToChannel(jsonEncode({'n_r': data['n_id']}));
  }

  Future<void> addMentionNotification(data) async {
    _prefs.setBool("hasNotif", true);
    DateTime time = DateTime.parse(data['time']);
    _handler.mentionNotif(data['u']);
    var notif = Notifications(
        type: NotificationType.mention,
        userName: data['u'],
        timeCreated: time,
        userDpUrl: data['dp'],
        postId: data['id']);
    sendToChannel(jsonEncode({'m_r': data['n_id']}));
    var notifBox = await Hive.openBox('Notifications');
    await notifBox.put(time.toString(), notif);
  }

  void deleteChat(data) async {
    var me = _prefs.getString('username');
    String threadName = me + '-' + data['from'];
    var threadBox = Hive.box('Threads');
    var existingThread = threadBox.get(threadName);
    existingThread.deleteChat(data['id']);
    existingThread.save();
    sendToChannel(jsonEncode({'n_r': data['notif_id']}));
  }

  void _createReplyThread(data) async {
    var threadBox = Hive.box('Threads');
    var me = _prefs.getString('username');

    //Creating thread with the given data
    Thread thread;

    //Thread is named in the format "self_sender" eg:anna_deepika
    var threadName = me + '-' + data['message']['from'];

    //Checking if thread already exists in box, if exists, the new chat messaeg if added else new thread is created and saved to box.

    if (!threadBox.containsKey(threadName)) {
      thread = Thread(
          first: User(name: me), second: User(name: data['message']['from']));
      await threadBox.put(threadName, thread);
    } else {
      thread = threadBox.get(threadName);

      String currentUser = _prefs.getString("curUser");

      if (currentUser != data['message']['from']) {
        _handler.chatNotif(data['message']['from'], data['message']['message']);
        if (thread.hasUnseen != null) {
          thread.hasUnseen += 1;
        } else {
          thread.hasUnseen = 1;
        }
      } else if (currentUser == data['message']['from']) {
        print("here");

        var seenTicker = {
          "type": "seen_ticker",
          "to": data['message']['from'],
          "id": data['message']['id'],
        };
        sendToChannel(jsonEncode(seenTicker));
        _prefs.setInt("lastSeenId", data['message']['id']);
        _prefs.setBool("${data['message']['from']}_hasNew", true);
        // playAudio();
        await _pool.play(soundId);
      }
    }
    ChatMessage obj;
    if (data['msg_type'] == "reply_aud" || data['msg_type'] == "reply_img") {
      obj = ChatMessage(
          filePath: data['message']['file'],
          id: data['message']['id'],
          msgType: data['msg_type'],
          replyMsgId: data['message']['reply_id'],
          replyMsgTxt: data['message']['reply_txt'],
          senderName: data['message']['from'],
          isMe: false,
          time: DateTime.parse(data['message']['time']));
    } else {
      obj = ChatMessage(
          message: data['message']['message'],
          id: data['message']['id'],
          msgType: data['msg_type'],
          replyMsgId: data['message']['reply_id'],
          replyMsgTxt: data['message']['reply_txt'],
          senderName: data['message']['from'],
          isMe: false,
          time: DateTime.parse(data['message']['time']));
    }
    thread.addChat(obj);
    thread.save();
  }

  void changeUserStatus(data) {
    print(data);
    try {
      String me = _prefs.getString('username');
      String threadName = me + '-' + data['u'];
      var threadBox = Hive.box('Threads');
      var existingThread = threadBox.get(threadName);
      if (data['s'] == 'online') {
        existingThread.isOnline = true;
      } else if (data['s'] == 'offline') {
        existingThread.isOnline = false;
        existingThread.lastSeen = DateTime.now();
      }
      existingThread.save();
    } catch (e) {
      print(e);
    }
  }

  void addNewStory(data) async {
    try {
      var storyBox = Hive.box('MyStories');
      print(data);

      if (storyBox.containsKey(data['u_id'])) {
        var userStory = storyBox.get(data['u_id']);
        userStory.addStory(Story(
          file: data['url'],
          time: DateTime.parse(data['time']),
          storyId: data['s_id'],
          caption: data['caption'],
          notificationId: data['n_id'],
        ));
        userStory.save();
      } else {
        UserStoryModel newUser = UserStoryModel()
          ..username = data['u']
          ..dpUrl = 'http://$localhost' + data['dp']
          ..userId = data['u_id']
          ..stories = <Story>[];
        newUser.addStory(Story(
          file: data['url'],
          time: DateTime.parse(data['time']),
          storyId: data['s_id'],
          caption: data['caption'],
          notificationId: data['n_id'],
        ));

        await storyBox.put(data['u_id'], newUser);
        newUser.save();
      }
      sendToChannel(jsonEncode({'s_r': data['n_id']}));
    } catch (e) {
      print(e);
      sendToChannel(jsonEncode({'s_r': data['n_id']}));
    }
  }

  void addStoryView(data) {
    try {
      int me = _prefs.getInt('id');
      var storyBox = Hive.box('MyStories');
      print(data);

      var userStory = storyBox.get(me);
      userStory.addView(
          StoryUser(
            username: data['u'],
            profilePicture: 'http://$localhost' + data['dp'],
            viewedTime: DateTime.parse(data['time']),
          ),
          data['id'].toInt());
      userStory.save();
      sendToChannel(jsonEncode({'s_r': data['n_id']}));
    } catch (e) {
      print(e);
      sendToChannel(jsonEncode({'s_r': data['n_id']}));
    }
  }

  void addStoryComment(data) {
    try {
      int me = _prefs.getInt('id');
      var storyBox = Hive.box('MyStories');
      print(data);

      var userStory = storyBox.get(me);
      userStory.addComment(
          StoryComment(
            username: data['u'],
            profilePicture: 'http://$localhost' + data['dp'],
            viewedTime: DateTime.parse(data['time']),
            commentId: data['c_id'],
            comment: data['comment'],
          ),
          data['s_id'].toInt());
      userStory.save();
      sendToChannel(jsonEncode({'s_n_r': data['c_id']}));
    } catch (e) {
      print(e);
      sendToChannel(jsonEncode({'s_n_r': data['c_id']}));
    }
  }

  void deleteOldStory(data) {
    try {
      var storyBox = Hive.box('MyStories');
      print(data);

      var userStory = storyBox.get(data['u_id']);
      userStory.deleteOldStory(
          id: data['s_id'].toInt(), userId: data['u_id'].toInt());
      userStory.save();
      sendToChannel(jsonEncode({'s_r': data['n_id']}));
    } catch (e) {
      print(e);
      sendToChannel(jsonEncode({'s_r': data['n_id']}));
    }
  }

  void updateTypingStatus(data) {
    try {
      String me = _prefs.getString('username');
      String threadName = me + '-' + data['from'];
      var threadBox = Hive.box('Threads');
      var existingThread = threadBox.get(threadName);
      if (data['status'] == "typing") {
        existingThread.isTyping = true;
      } else {
        existingThread.isTyping = false;
        print("typing finished");
      }

      existingThread.save();
    } catch (e) {
      print(e);
    }
  }

  void updateMsgSeenStatus(data) {
    try {
      String me = _prefs.getString('username');
      String threadName = me + '-' + data['from'];
      var threadBox = Hive.box('Threads');
      var existingThread = threadBox.get(threadName);
      existingThread.chatList.forEach((e) {
        print(e.msgType);
        print(e.id);
        print(e.id.runtimeType);
      });
      existingThread.updateChatSeenStatus(data['id']);
      existingThread.save();
      sendToChannel(jsonEncode({'n_r': data['notif_id']}));
    } catch (e) {
      sendToChannel(jsonEncode({'n_r': data['notif_id']}));
    }
  }

  void addNotification(data) async {
    if ((_prefs.containsKey('lastNotifId') &&
            (_prefs.getInt('lastNotifId') != data['id'])) ||
        !_prefs.containsKey('lastNotifId')) {
      _prefs.setInt("lastNotifId", data['id']);
      _prefs.setBool("hasNotif", true);
      DateTime curTime = DateTime.parse(data['time']);
      _handler.friendRequestNotif(data['username']);
      var notif = Notifications(
          type: NotificationType.friendRequest,
          userName: data['username'],
          timeCreated: curTime,
          userId: data['user_id'],
          userDpUrl: data['dp'],
          notifId: data['id']);
      sendToChannel(jsonEncode({'f_r': data['id']}));
      var notifBox = await Hive.openBox('Notifications');
      await notifBox.put(data['id'], notif);
      notif.save();
    }
  }

  void _updateReachedServerStatus(data) {
    try {
      var id = data['r_s']['id'];
      var newId = data['r_s']['n_id'];
      var name = data['r_s']['to'];

      String me = _prefs.getString('username');
      String threadName = me + '-' + name;
      var threadBox = Hive.box('Threads');
      var existingThread = threadBox.get(threadName);

      existingThread.updateChatId(id: id, newId: newId);
      existingThread.save();
      sendToChannel(jsonEncode({'n_r': data['r_s']['notif_id']}));
    } catch (e) {
      sendToChannel(jsonEncode({'n_r': data['r_s']['notif_id']}));
    }
  }

  void _updateChatStatus(data) {
    try {
      int id = data['received'];
      String name = data['from'];
      String me = _prefs.getString('username');
      String threadName = me + '-' + name;
      var threadBox = Hive.box('Threads');
      var existingThread = threadBox.get(threadName);
      existingThread.updateChatStatus(id);
      existingThread.save();
      sendToChannel(jsonEncode({'n_r': data['notif_id']}));
    } catch (e) {
      sendToChannel(jsonEncode({'n_r': data['notif_id']}));
    }
  }

  getAndSetDetails(thread) async {
    var username = thread.second.name;
    var response = await http
        .get(Uri.http(localhost, '/api/user_details', {'username': username}));

    var decodedResp = jsonDecode(response.body);
    thread.second.f_name = decodedResp['f_name'];
    thread.second.l_name = decodedResp['l_name'];
    thread.second.dpUrl = decodedResp['dp'];
    thread.second.userId = decodedResp['id'];
    thread.save();
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
        filePath: data['message']['img'],
        senderName: data['message']['from'],
        time: DateTime.parse(data['message']['time']),
        msgType: "img",
        isMe: false,
        id: data['message']['id'],
      ));
    } else if (data['msg_type'] == 'aud') {
      thread.addChat(ChatMessage(
        filePath: data['message']['aud'],
        senderName: data['message']['from'],
        msgType: 'aud',
        time: DateTime.parse(data['message']['time']),
        isMe: false,
        id: data['message']['id'],
      ));
    }
    getAndSetDetails(thread);
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
    var threadName = me + '-' + data['message']['from'];

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
        _prefs.setInt("lastSeenId", data['message']['id']);
        _prefs.setBool("${data['message']['from']}_hasNew", true);
        print(soundId);
        await _pool.play(soundId);
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
          filePath: data['message']['aud'],
          senderName: data['message']['from'],
          time: DateTime.parse(data['message']['time']),
          msgType: "aud",
          isMe: false,
          id: data['message']['id'],
        ));
      } else if (data['msg_type'] == 'img') {
        existingThread.addChat(ChatMessage(
          filePath: data['message']['img'],
          senderName: data['message']['from'],
          time: DateTime.parse(data['message']['time']),
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
    if (!_timer.isActive) {
      _timer = Timer.periodic(Duration(seconds: 10), (timer) => handleSocket());
    }
  }
}
