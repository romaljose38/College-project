import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:foo/chat/chatscreen.dart';
import 'package:foo/chat/chattile.dart';
import 'package:foo/models.dart';
import 'package:foo/socket.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ForwardScreen extends StatelessWidget {
  Map msgs;

  ForwardScreen({this.msgs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder(
          valueListenable: Hive.box("Threads").listenable(),
          builder: (context, box, widget) {
            print(box.values.toList());

            List threads = box.values.toList() ?? [];

            if (threads.length >= 1) {
              threads.sort((a, b) {
                return b.lastAccessed.compareTo(a.lastAccessed);
              });
            }
            print(threads);
            return ListView.builder(
                itemCount: threads.length,
                itemBuilder: (context, index) {
                  print(index);
                  print(threads[index]);
                  return ForwardTile(
                    thread: threads[index],
                    msgs: this.msgs,
                  );
                });
          }),
    );
  }
}

class ForwardTile extends StatelessWidget {
  final Thread thread;
  final Map msgs;

  ForwardTile({this.thread, this.msgs});

  getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  sendMsgs() async {
    var prefs = await getPrefs();
    this.msgs.forEach((key, value) {
      var obj = ChatMessage.fromObj(value);
      if (value.msgType == "reply_txt" || value.msgType == "txt") {
        var data = jsonEncode({
          'message': value.message,
          'id': value.id,
          'time': value.time.toString(),
          'to': thread.second.name,
          'type': 'msg',
        });
        SocketChannel.sendToChannel(data);
        obj.msgType = "txt";
      } else if (value.msgType == "reply_img") {
        obj.msgType = "img";
      } else if (value.msgType == "reply_aud") {
        obj.msgType = "aud";
      }
      obj.senderName = prefs.getString("username");
      obj.isMe = true;
      thread.addChat(obj);
    });
    thread.save();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.1),
              offset: Offset(0, 0),
              blurRadius: 8,
            )
          ]),
      padding: EdgeInsets.symmetric(vertical: 13),
      width: MediaQuery.of(context).size.width,
      child: ListTile(
          onTap: () async {
            sendMsgs();
            var prefs = await getPrefs();
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => ChatScreen(
                        prefs: prefs,
                        // controller:this.controller,
                        thread: this.thread)));
          },
          leading: CircleAvatar(
            radius: 35,
            child: Text(this.thread.second.name[0].toUpperCase()),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                this.thread.second.name,
                style: TextStyle(
                    color: Color.fromRGBO(60, 82, 111, 1),
                    fontWeight: FontWeight.w700,
                    fontSize: 18),
              ),
              SizedBox(
                height: 8,
              ),
              Text(
                (thread.chatList.length != 0)
                    ? ((thread.chatList.last.msgType == "txt")
                        ? (thread.chatList.last.message ?? "") //"text"
                        : "media")
                    : "",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color.fromRGBO(100, 115, 142, 1),
                  fontWeight: FontWeight.w200,
                  fontSize: 15,
                ),
              ),
            ],
          )),
    );
  }
}
