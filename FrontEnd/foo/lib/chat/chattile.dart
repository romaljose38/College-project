import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chatscreen.dart';
import 'package:foo/models.dart';
import 'package:intl/intl.dart';
import 'package:foo/test_cred.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatTile extends StatelessWidget {
  // final NotificationController controller;
  final Thread thread;

  ChatTile(
      {
      // this.controller,
      this.thread});

  String getDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);
    if (dateToCheck == today) {
      return "Today";
    } else if (dateToCheck == yesterday) {
      return "Yesterday";
    }
    return DateFormat("LLL d").format(date);
  }

  getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    print("has Unseen");
    print(thread.hasUnseen);
    print(thread.second?.f_name);
    print(thread.second?.l_name);
    print(thread.second?.dpUrl);
    return Container(
        //margin: EdgeInsets.symmetric(horizontal: 0, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          // borderRadius: BorderRadius.circular(15),
          border: Border.symmetric(
              horizontal: BorderSide(color: Colors.grey.shade100, width: .6)),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withOpacity(.1),
          //     offset: Offset(0, 0),
          //     blurRadius: 8,
          //   )
          // ],
        ),
        padding: EdgeInsets.symmetric(vertical: 18),
        width: MediaQuery.of(context).size.width,
        //height: 80,
        child: ListTile(
            trailing: Container(
                width: 50,
                child: Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Column(
                    children: [
                      Text(getDate(thread.lastAccessed),
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500)),
                      SizedBox(
                        height: 6,
                      ),
                      SizedBox(
                        height: 20,
                        child: ((thread.hasUnseen ?? -1) > 0)
                            ? Container(
                                width: 20,
                                height: 20,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green.withOpacity(.6),
                                      Colors.green.withOpacity(.2),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(thread.hasUnseen.toString(),
                                    style: TextStyle(
                                        fontSize: 8, color: Colors.white)),
                              )
                            : Container(),
                      ),
                    ],
                    mainAxisAlignment: MainAxisAlignment.start,
                  ),
                )),
            onTap: () async {
              var prefs = await getPrefs();
              Navigator.push(
                  context,
                  PageRouteBuilder(
                      pageBuilder: (context, animation, secAnimation) =>
                          ChatScreen(
                              prefs: prefs,
                              // controller:this.controller,
                              thread: this.thread),
                      transitionsBuilder:
                          (context, animation, secAnimation, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                                  begin: Offset(1, 0), end: Offset(0, 0))
                              .animate(animation),
                          child: child,
                        );
                      }));
            },
            leading: Container(
                height: 56,
                width: 56,
                //child: Text(this.thread.second.name[0].toUpperCase()),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                      fit: BoxFit.cover,
                      image: CachedNetworkImageProvider(
                        thread.second.dpUrl == null
                            ? ''
                            : 'http://$localhost' + thread.second?.dpUrl,
                      )),
                )),
            title:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            ])));
  }
}
