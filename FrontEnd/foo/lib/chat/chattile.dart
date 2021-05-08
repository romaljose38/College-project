import 'package:flutter/material.dart';
import 'chatscreen.dart';
import 'package:foo/models.dart';
import 'package:intl/intl.dart';

class ChatTile extends StatelessWidget {
  // final NotificationController controller;
  final Thread thread;

  ChatTile(
      {
      // this.controller,
      this.thread});

  String getDate(DateTime date) => DateFormat("dd/MM/yyyy").format(date);

  @override
  Widget build(BuildContext context) {
    print(thread.second.name);
    print(thread.lastAccessed);
    print(thread.first.name);
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      padding: EdgeInsets.symmetric(vertical: 13),
      width: MediaQuery.of(context).size.width,
      child: ListTile(
          trailing: Padding(
            padding: EdgeInsets.only(top: 10),
            child: Column(
              children: [
                Text(getDate(thread.lastAccessed),
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500))
              ],
              mainAxisAlignment: MainAxisAlignment.start,
            ),
          ),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ChatScreen(
                        // controller:this.controller,
                        thread: this.thread)));
          },
          leading: CircleAvatar(
            radius: 35,
            child: Text(this.thread.second.name.toUpperCase()),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                this.thread.second.name,
                style: TextStyle(
                    color: Color.fromRGBO(60, 82, 111, 1),
                    fontWeight: FontWeight.w400,
                    fontSize: 18),
              ),
              SizedBox(
                height: 8,
              ),
              Text(
                (thread.chatList.length != 0)
                    ? ((thread.chatList.last.msgType == "txt")
                        ? "text"
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
