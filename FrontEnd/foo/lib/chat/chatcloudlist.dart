import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:foo/chat/socket.dart';
import 'audiocloud.dart';
import 'chatcloud.dart';
import 'dart:async';

import 'mediacloud.dart';

class ChatCloudList extends StatefulWidget {
  final List chatList;
  final bool needScroll;
  final String curUser;
  final String otherUser;

  ChatCloudList(
      {Key key, this.chatList, this.needScroll, this.curUser, this.otherUser});

  @override
  _ChatCloudListState createState() => _ChatCloudListState();
}

class _ChatCloudListState extends State<ChatCloudList> {
  ScrollController _scrollController = ScrollController();

  int day;

  @override
  void initState() {
    super.initState();
    // _setname();
  }

  void sendReadTicket() {
    if (widget.chatList.length != 0) {
      if (widget.chatList.last.isMe == false) {
        var data = {
          "type": "seen_ticker",
          "from": widget.curUser,
          "to": widget.otherUser,
          "id": widget.chatList.last.id,
        };
        NotificationController.sendToChannel(jsonEncode(data));
      }
    }
  }

  void _scrollToEnd() async {
    _scrollController.animateTo(_scrollController.position.minScrollExtent,
        duration: Duration(milliseconds: 100), curve: Curves.linear);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.needScroll) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => Timer(Duration(milliseconds: 100), () => {_scrollToEnd()}));
    }

    sendReadTicket();

    return ListView.builder(
        reverse: true,
        controller: _scrollController,
        itemCount: widget.chatList.length ?? 0,
        itemBuilder: (context, index) {
          final reversedIndex = widget.chatList.length - 1 - index;
          bool needDay = false;
          if (day == null) {
            day = widget.chatList[reversedIndex].time.day;
            needDay = true;
          }
          if (reversedIndex >= 1) {
            if (widget.chatList[reversedIndex - 1].time.day !=
                widget.chatList[reversedIndex].time.day) {
              print("yep we need it");
              // day=widget.chatList[reversedIndex].time.day;
              needDay = true;
            }
          } else {
            needDay = false;
          }
          if (widget.chatList[reversedIndex].msgType == "txt") {
            return ChatCloud(
              msgObj: widget.chatList[reversedIndex],
              needDate: needDay,
            );
          } else if (widget.chatList[reversedIndex].msgType == "aud") {
            return AudioCloud(
              msgObj: widget.chatList[reversedIndex],
              needDate: needDay,
            );
          } else {
            return MediaCloud(
                msgObj: widget.chatList[reversedIndex], needDate: needDay);
          }
        });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
