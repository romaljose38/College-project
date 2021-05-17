import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:foo/chat/socket.dart';
import 'package:foo/models.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audiocloud.dart';
import 'chatcloud.dart';
import 'dart:async';

import 'mediacloud.dart';

class ChatCloudList extends StatefulWidget {
  final List chatList;
  final bool needScroll;
  final String curUser;
  final String otherUser;
  final SharedPreferences prefs;

  ChatCloudList(
      {Key key,
      this.chatList,
      this.needScroll,
      this.curUser,
      this.otherUser,
      this.prefs});

  @override
  _ChatCloudListState createState() => _ChatCloudListState();
}

class _ChatCloudListState extends State<ChatCloudList> {
  ScrollController _scrollController = ScrollController();
  SharedPreferences _prefs;
  int day;

  @override
  void initState() {
    super.initState();
    // _setname();
  }

  Future<void> initSharePrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> sendReadTicket() async {
    if (widget.chatList.length != 0) {
      if (widget.chatList.last.isMe == false) {
        var id;
        await initSharePrefs();
        if (_prefs.containsKey("lastSeenId")) {
          id = _prefs.getInt("lastSeenId");
          print("pazhee id");
        } else {
          id = widget.chatList.last.id;
          var data = {
            "type": "seen_ticker",
            "to": widget.otherUser,
            "id": id,
          };
          NotificationController.sendToChannel(jsonEncode(data));
          _prefs.setInt('lastSeenId', id);
        }
        if (id != widget.chatList.last.id) {
          print("ayakkanam");
          var data = {
            "type": "seen_ticker",
            "to": widget.otherUser,
            "id": widget.chatList.last.id,
          };
          NotificationController.sendToChannel(jsonEncode(data));
          _prefs.setInt("lastSeenId", widget.chatList.last.id);
        }
      }
    }
  }

  void _scrollToEnd() async {
    if (_scrollController.position.pixels !=
        _scrollController.position.minScrollExtent) {
      _scrollController.animateTo(_scrollController.position.minScrollExtent,
          duration: Duration(milliseconds: 100), curve: Curves.linear);
    }
  }

  void updateLastChatMsgStatus() {
    if (widget.chatList != null) {
      if (widget.chatList.length > 0) {
        if (widget.chatList.last.isMe != true) {
          var threadBox = Hive.box("Threads");
          var thread = threadBox.get(widget.curUser + '_' + widget.otherUser);
          if (thread.hasUnseen > 0) {
            thread.hasUnseen = 0;
            thread.save();
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.needScroll) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => Timer(Duration(milliseconds: 100), () => {_scrollToEnd()}));
    }

    sendReadTicket();
    updateLastChatMsgStatus();
    return ListView.builder(
        reverse: true,
        controller: _scrollController,
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
            return MediaCloud(msgObj: widget.chatList[reversedIndex]);
          }
        });
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
    print(date.toString());
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
