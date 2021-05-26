import 'package:flutter/material.dart';
import 'package:foo/chat/replyaudiocloud.dart';
import 'package:foo/chat/replycloud.dart';
import 'package:foo/chat/replyimagecloud.dart';
// import 'package:foo/chat/socket.dart';
import 'package:foo/models.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audiocloud.dart';
import 'chatcloud.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'mediacloud.dart';

class ChatCloudList extends StatefulWidget {
  final List chatList;
  final ItemScrollController scrollController;
  final String curUser;
  final String otherUser;
  final SharedPreferences prefs;
  final Function swipingHandler;
  final ItemPositionsListener positionsListener;

  ChatCloudList({
    Key key,
    this.chatList,
    this.scrollController,
    this.curUser,
    this.otherUser,
    this.prefs,
    this.swipingHandler,
    this.positionsListener,
  });

  @override
  _ChatCloudListState createState() => _ChatCloudListState();
}

class _ChatCloudListState extends State<ChatCloudList>
    with SingleTickerProviderStateMixin {
  int day;
  AnimationController _controller;

  Map<int, int> checkingList = <int, int>{};

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    // _setname();
  }

  // void _scrollToEnd() async {
  //   if (_scrollController.position.pixels !=
  //       _scrollController.position.minScrollExtent) {
  //     _scrollController.animateTo(_scrollController.position.minScrollExtent,
  //         duration: Duration(milliseconds: 100), curve: Curves.linear);
  //   }
  // }

  scroller(id) async {
    print(checkingList);
    print("scroll to index");
    if (checkingList.containsKey(id)) {
      await widget.scrollController.scrollTo(
          index: checkingList[id],
          duration: Duration(milliseconds: 300),
          alignment: .33);
    }

    // await widget.scrollController
  }

  @override
  Widget build(BuildContext context) {
    // return ListView.builder(
    //     cacheExtent: 300,
    //     reverse: true,
    //     physics: BouncingScrollPhysics(),
    //     controller: widget.scrollController,
    //     itemCount: widget.chatList.length ?? 0,
    return ScrollablePositionedList.builder(
        itemPositionsListener: widget.positionsListener,
        reverse: true,
        itemCount: widget.chatList.length ?? 0,
        physics: BouncingScrollPhysics(),
        itemScrollController: widget.scrollController,
        itemBuilder: (context, index) {
          final reversedIndex = widget.chatList.length - 1 - index;
          checkingList[widget.chatList[reversedIndex].id] = index;
          if (widget.chatList[reversedIndex].msgType == "txt") {
            return ChatCloud(
              msgObj: widget.chatList[reversedIndex],
              swipingHandler: widget.swipingHandler,
            );
          } else if (widget.chatList[reversedIndex].msgType == "aud") {
            return AudioCloud(
              msgObj: widget.chatList[reversedIndex],
              controller: _controller,
              swipingHandler: widget.swipingHandler,
              otherUser: widget.otherUser,
            );
          } else if (widget.chatList[reversedIndex].msgType == "date") {
            return DateCloud(
              msgObj: widget.chatList[reversedIndex],
            );
          } else if (widget.chatList[reversedIndex].msgType == "reply_txt") {
            return ReplyCloud(
              msgObj: widget.chatList[reversedIndex],
              scroller: scroller,
            );
          } else if (widget.chatList[reversedIndex].msgType == "reply_aud") {
            return AudioReplyCloud(
              msgObj: widget.chatList[reversedIndex],
              controller: _controller,
              swipingHandler: widget.swipingHandler,
              otherUser: widget.otherUser,
              scroller: scroller,
            );
          } else if (widget.chatList[reversedIndex].msgType == "reply_img") {
            return ImageReplyCloud(
              msgObj: widget.chatList[reversedIndex],
              swipingHandler: widget.swipingHandler,
              otherUser: widget.otherUser,
              scroller: scroller,
            );
          } else if (widget.chatList[reversedIndex].msgType == "img") {
            return MediaCloud(
              msgObj: widget.chatList[reversedIndex],
              otherUser: widget.otherUser,
              swipingHandler: widget.swipingHandler,
            );
          }
          return Container();
        });
  }

  @override
  void dispose() {
    // _scrollController.dispose();
    super.dispose();
    _controller?.dispose();
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
