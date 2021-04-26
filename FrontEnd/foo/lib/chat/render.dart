import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'socket.dart';
import 'package:hive/hive.dart';
import 'package:foo/models.dart';
import 'dart:async';
import 'dart:convert';
import 'listscreen.dart';

class ChatRenderer extends StatefulWidget {
  ChatRenderer({Key key}) : super(key: key);

  @override
  _ChatRendererState createState() => _ChatRendererState();
}

class _ChatRendererState extends State<ChatRenderer> {
  SharedPreferences prefs;

  //Creating a list of the existing threads in the hive 'Threads' box
  List threadList = Hive.box('Threads').values.toList();
  Stream stream;

  @override
  void initState() {
    super.initState();
    _setPrefs();
  }

  //Initializing shared_preference instance and setting the user name for current user.
  //To access the username throughout the project.
  void _setPrefs() async {
    prefs = await SharedPreferences.getInstance();
    print(prefs.getString('username'));
  }

  _chicanery(threadName,thread,data) async {
    var box = Hive.box("Threads");
    await box.put(threadName, thread);
    if(data['type']=='txt'){
    thread.addChat(ChatMessage(
      message: data['message']['message'],
      senderName: data['message']['from'],
      time: DateTime.now(),
      isMe: false,
      msgType: 'txt',
      id: data['message']['id'],
    ));
    }
    else if(data['type']=='img'){
    thread.addChat(ChatMessage(
      base64string: data['message']['img'],
      senderName: data['message']['from'],
      msgType: 'img',
      time: DateTime.now(),
      isMe: false,
      id: data['message']['id'],
    ));
    } 
    else if(data['type']=='aud'){
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
    var me = prefs.getString('user');

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
      if (data['type'] == 'txt') {

        existingThread.addChat(ChatMessage(
          message: data['message']['message'],
          senderName: data['message']['from'],

          time: DateTime.now(),
          isMe: false,
          msgType:"txt",
          id: data['message']['id'],
        ));

      }
      else if(data['type'] == 'aud'){
        existingThread.addChat(ChatMessage(
          base64string: data['message']['aud'],
          senderName: data['message']['from'],
          time: DateTime.now(),
          ext:data['message']['ext'],
          msgType:"aud",
          isMe: false,
          id: data['message']['id'],
        ));
      }
      else if(data['type'] == 'img'){
        existingThread.addChat(ChatMessage(
          base64string: data['message']['img'],
          senderName: data['message']['from'],
          time: DateTime.now(),
          ext:data['message']['ext'],
          msgType:"img",
          isMe: false,
          id: data['message']['id'],
        ));
      }
      existingThread.save();
    }

    List list = threadBox.values.toList();
    return list;
  }

  _chicaneryForMe(
    threadName,
    thread,
    data,
  ) async {
    var me = prefs.getString('user');
    var box = Hive.box("Threads");
    await box.put(threadName, thread);
    thread.addChat(ChatMessage(
        message: data['message']['message'],
        senderName: me,
        id: data['message']['id'],
        isMe: true,
        time: DateTime.now()));
    thread.save();
  }

  Future _createThreadForMe(data) async {
    if (data == "None") {
      return null;
    }
    var threadBox = Hive.box('Threads');
    var me = prefs.getString('user');

    //Creating thread with the given data
    var thread = Thread(
        first: User(name: me), second: User(name: data['message']['from']));

    //Thread is named in the format "self_sender" eg:anna_deepika
    var threadName = me + '_' + data['message']['to'];

    //Checking if thread already exists in box, if exists, the new chat messaeg if added; else new thread is created and saved to box.
    if (!threadBox.containsKey(threadName)) {
      print("new_thread");
      await _chicaneryForMe(threadName, thread, data);
    } else {
      print("existing thread");
      var existingThread = threadBox.get(threadName);
      existingThread.addChat(ChatMessage(
          message: data['message']['message'],
          senderName: me,
          id: data['message']['id'],
          isMe: true,
          time: DateTime.now()));
      existingThread.save();
    }

    List list = threadBox.values.toList();
    return list;
  }

  void _updateChatStatus(int id, String name) {
    String me = prefs.getString('user');
    String threadName = me + '_' + name;
    var threadBox = Hive.box('Threads');
    var existingThread = threadBox.get(threadName);
    existingThread.updateChatStatus(id);
    existingThread.save();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: NotificationController.streamController.stream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            print(snapshot.data);
            if (snapshot.connectionState == ConnectionState.active) {
              var data = jsonDecode(snapshot.data);
              FutureOr threads;
              if (data.containsKey('received')) {
                print(data);
                _updateChatStatus(data['received'], data['name']);
                return ChatListScreen(threads: threadList);
              } else if (data['message']['to'] == prefs.getString('user')) {
                print(data['message']['id']);
                threads = _createThread(data);
                NotificationController.sendToChannel(jsonEncode({
                  'message': {'received': data['message']['id']}
                }));
              } else if (data['message']['from'] == prefs.getString('user')) {
                threads = _createThreadForMe(data);
              }
              return FutureBuilder(
                  future: threads,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      List threadList = snapshot.data;
                      print(threadList);
                      threadList.sort((a, b) {
                        return b.lastAccessed.compareTo(a.lastAccessed);
                      });
                      return ChatListScreen(
                          // controller: widget.controller,
                          threads: threadList);
                    }
                    return ChatListScreen(
                        //  controller: widget.controller,
                        threads: threadList);
                  });
            }
          }
          if (threadList.length > 0) {
            threadList.sort((a, b) {
              return b.lastAccessed.compareTo(a.lastAccessed);
            });
          }
          return ChatListScreen(
              // controller: widget.controller,
              threads: threadList);
        });
  }
}
