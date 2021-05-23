import 'package:flutter/material.dart';
// import 'package:foo/chat/socket.dart';
import 'package:foo/models.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audiocloud.dart';
import 'chatcloud.dart';

import 'mediacloud.dart';

class ChatCloudList extends StatefulWidget {
  final List chatList;
  final ScrollController scrollController;
  final String curUser;
  final String otherUser;
  final SharedPreferences prefs;

  ChatCloudList(
      {Key key,
      this.chatList,
      this.scrollController,
      this.curUser,
      this.otherUser,
      this.prefs});

  @override
  _ChatCloudListState createState() => _ChatCloudListState();
}

class _ChatCloudListState extends State<ChatCloudList> {
  int day;

  @override
  void initState() {
    super.initState();
    // _setname();
  }

  // void _scrollToEnd() async {
  //   if (_scrollController.position.pixels !=
  //       _scrollController.position.minScrollExtent) {
  //     _scrollController.animateTo(_scrollController.position.minScrollExtent,
  //         duration: Duration(milliseconds: 100), curve: Curves.linear);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        cacheExtent: 300,
        reverse: true,
        physics: BouncingScrollPhysics(),
        controller: widget.scrollController,
        itemCount: widget.chatList.length ?? 0,
        itemBuilder: (context, index) {
          final reversedIndex = widget.chatList.length - 1 - index;

          if (widget.chatList[reversedIndex].msgType == "txt") {
            return ChatCloud(
              msgObj: widget.chatList[reversedIndex],
            );
          } else if (widget.chatList[reversedIndex].msgType == "aud") {
            return AudioCloud(
              msgObj: widget.chatList[reversedIndex],
            );
          } else if (widget.chatList[reversedIndex].msgType == "date") {
            return DateCloud(
              msgObj: widget.chatList[reversedIndex],
            );
          } else {
            return MediaCloud(
              msgObj: widget.chatList[reversedIndex],
              otherUser: widget.otherUser,
            );
          }
        });
  }

  @override
  void dispose() {
    // _scrollController.dispose();
    super.dispose();
  }
}

class DateCloud extends StatelessWidget {
  ChatMessage msgObj;
  DateCloud({this.msgObj});

  String getDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);
    // print(date.toString());
    if (dateToCheck == today) {
      return "Today";
    } else if (dateToCheck == yesterday) {
      return "Yesterday";
    }
    return DateFormat("LLL d").format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 9),
          margin: EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(getDate(this.msgObj.time),
              style: GoogleFonts.openSans(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        )
      ],
    );
  }
}
