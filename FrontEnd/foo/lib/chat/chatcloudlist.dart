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
  final Function forwardMsgHandler;
  final Map msgMap;

  ChatCloudList({
    Key key,
    this.chatList,
    this.scrollController,
    this.curUser,
    this.otherUser,
    this.prefs,
    this.msgMap,
    this.swipingHandler,
    this.forwardMsgHandler,
    this.positionsListener,
  });

  @override
  _ChatCloudListState createState() => _ChatCloudListState();
}

class _ChatCloudListState extends State<ChatCloudList>
    with SingleTickerProviderStateMixin {
  int day;
  AnimationController _controller;
  bool hasSelectedSomething = false;
  Map<int, ChatMessage> forwardedMsgs = <int, ChatMessage>{};
  Map<int, int> checkingList = <int, int>{};
  ValueNotifier notifer;
  @override
  void initState() {
    super.initState();
    notifer = ValueNotifier(hasSelectedSomething);
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

  removeForward() {
    widget.forwardMsgHandler();
    print("function works");
  }

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
    return WillPopScope(
      onWillPop: () async {
        if (hasSelectedSomething) {
          setState(() {
            hasSelectedSomething = false;
          });
          widget.forwardMsgHandler();
          return Future.value(false);
        }
        return Future.value(true);
      },
      child: ScrollablePositionedList.builder(
          itemPositionsListener: widget.positionsListener,
          reverse: true,
          itemCount: widget.chatList.length ?? 0,
          physics: BouncingScrollPhysics(),
          itemScrollController: widget.scrollController,
          itemBuilder: (context, index) {
            final reversedIndex = widget.chatList.length - 1 - index;
            checkingList[widget.chatList[reversedIndex].id] = index;

            var chat = ChatCloud(
              msgObj: widget.chatList[reversedIndex],
              swipingHandler: widget.swipingHandler,
              outerSetState: outersetState,
              hasSelectedSomething: hasSelectedSomething,
              forwardMap: widget.msgMap,
              forwardRemover: removeForward,
            );
            var audio = AudioCloud(
              msgObj: widget.chatList[reversedIndex],
              controller: _controller,
              swipingHandler: widget.swipingHandler,
              otherUser: widget.otherUser,
              hasSelectedSomething: hasSelectedSomething,
              outerSetState: outersetState,
              forwardMap: widget.msgMap,
              forwardRemover: removeForward,
            );
            var date = DateCloud(
              msgObj: widget.chatList[reversedIndex],
            );
            var txtReply = ReplyCloud(
              msgObj: widget.chatList[reversedIndex],
              hasSelectedSomething: hasSelectedSomething,
              outerSetState: outersetState,
              forwardMap: widget.msgMap,
              swipingHandler: widget.swipingHandler,
              scroller: scroller,
              forwardRemover: removeForward,
            );
            var audReply = AudioReplyCloud(
              msgObj: widget.chatList[reversedIndex],
              controller: _controller,
              swipingHandler: widget.swipingHandler,
              otherUser: widget.otherUser,
              scroller: scroller,
              hasSelectedSomething: hasSelectedSomething,
              outerSetState: outersetState,
              forwardMap: widget.msgMap,
              forwardRemover: removeForward,
            );

            var imgReply = ImageReplyCloud(
              msgObj: widget.chatList[reversedIndex],
              swipingHandler: widget.swipingHandler,
              otherUser: widget.otherUser,
              hasSelectedSomething: hasSelectedSomething,
              outerSetState: outersetState,
              forwardMap: widget.msgMap,
              scroller: scroller,
              forwardRemover: removeForward,
            );
            var image = MediaCloud(
              msgObj: widget.chatList[reversedIndex],
              otherUser: widget.otherUser,
              swipingHandler: widget.swipingHandler,
              hasSelectedSomething: hasSelectedSomething,
              outerSetState: outersetState,
              forwardMap: widget.msgMap,
              forwardRemover: removeForward,
            );
            return Container(child: (() {
              if (widget.chatList[reversedIndex].msgType == "txt") {
                return chat;
              } else if (widget.chatList[reversedIndex].msgType == "aud") {
                return audio;
              } else if (widget.chatList[reversedIndex].msgType == "date") {
                return date;
              } else if (widget.chatList[reversedIndex].msgType ==
                  "reply_txt") {
                return txtReply;
              } else if (widget.chatList[reversedIndex].msgType ==
                  "reply_aud") {
                return audReply;
              } else if (widget.chatList[reversedIndex].msgType ==
                  "reply_img") {
                return imgReply;
              } else if (widget.chatList[reversedIndex].msgType == "img") {
                return image;
              } else {
                return Container();
              }
            })());
          }),
    );
  }

  outersetState() {
    widget.forwardMsgHandler();
    setState(() {
      hasSelectedSomething = true;
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
