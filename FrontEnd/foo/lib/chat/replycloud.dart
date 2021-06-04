import 'package:foo/chat/chatscreen.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter/material.dart';
import 'package:foo/models.dart';
import 'package:swipe_to/swipe_to.dart';

class ReplyCloud extends StatefulWidget {
  final ChatMessage msgObj;
  final Function scroller;
  bool hasSelectedSomething;
  final Function outerSetState;
  Map forwardMap;
  Function forwardRemover;
  bool disableSwipe;
  Function swipingHandler;

  ReplyCloud(
      {Key key,
      this.msgObj,
      this.scroller,
      this.forwardRemover,
      this.disableSwipe = false,
      this.swipingHandler,
      this.hasSelectedSomething,
      this.outerSetState,
      this.forwardMap})
      : super(key: key);

  @override
  _ReplyCloudState createState() => _ReplyCloudState();
}

class _ReplyCloudState extends State<ReplyCloud> {
  String getTime() => intl.DateFormat('hh:mm').format(this.widget.msgObj.time);

  cloudContent(BuildContext context) {
    return Row(
        mainAxisAlignment: (this.widget.msgObj.isMe == true)
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
              margin: EdgeInsets.all(5),
              // alignment: Alignment.topLeft,

              child: Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * .7,
                      minWidth: 70),
                  child: Stack(children: <Widget>[
                    Wrap(
                      crossAxisAlignment: widget.msgObj.isMe
                          ? WrapCrossAlignment.end
                          : WrapCrossAlignment.start,
                      direction: Axis.vertical,
                      children: [
                        GestureDetector(
                          onTap: () => this
                              .widget
                              .scroller(this.widget.msgObj.replyMsgId),
                          child: Container(
                            width: 70,
                            decoration: BoxDecoration(
                              color: widget.msgObj.isMe
                                  ? Colors.white
                                  : Color.fromRGBO(255, 143, 187, 1),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(.05),
                                    blurRadius: 10,
                                    spreadRadius: .5,
                                    offset: Offset(-2, -3))
                              ],
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20)),
                            ),
                            padding: EdgeInsets.all(10),
                            child: (this.widget.msgObj.replyMsgTxt == imageUTF)
                                ? Row(children: [
                                    Icon(Icons.image, size: 15),
                                    Text("Image",
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: widget.msgObj.isMe
                                                ? Colors.black
                                                : Colors.white))
                                  ])
                                : (this.widget.msgObj.replyMsgTxt == audioUTF)
                                    ? Row(children: [
                                        Icon(Icons.headset_rounded, size: 15),
                                        Text("Audio",
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: widget.msgObj.isMe
                                                    ? Colors.black
                                                    : Colors.white))
                                      ])
                                    : Text(
                                        this.widget.msgObj.replyMsgTxt,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: widget.msgObj.isMe
                                                ? Colors.black
                                                : Colors.white),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                          ),
                        ),
                        Container(
                          // padding: EdgeInsets.all(5),
                          constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * .7,
                              minWidth: 90),
                          decoration: BoxDecoration(
                              gradient: (this.widget.msgObj.isMe == true)
                                  ? LinearGradient(
                                      begin: Alignment.topRight,
                                      end: Alignment.bottomLeft,
                                      stops: [
                                          .3,
                                          1
                                        ],
                                      colors: [
                                          Color.fromRGBO(255, 143, 187, 1),
                                          Color.fromRGBO(255, 117, 116, 1)
                                        ])
                                  : LinearGradient(
                                      begin: Alignment.topRight,
                                      end: Alignment.bottomLeft,
                                      stops: [
                                          .3,
                                          1
                                        ],
                                      colors: [
                                          Color.fromRGBO(248, 251, 255, 1),
                                          Color.fromRGBO(240, 247, 255, 1)
                                        ]),
                              borderRadius: BorderRadius.only(
                                topLeft: widget.msgObj.isMe
                                    ? Radius.circular(20)
                                    : Radius.circular(0),
                                topRight: widget.msgObj.isMe
                                    ? Radius.circular(0)
                                    : Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                              boxShadow: [
                                BoxShadow(
                                    blurRadius: 6,
                                    spreadRadius: .5,
                                    offset: Offset(1, 5),
                                    color: (this.widget.msgObj.isMe == true)
                                        ? Color.fromRGBO(248, 198, 220, 1)
                                        : Color.fromRGBO(218, 228, 237, 1))
                              ]),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(5, 5, 5, 15),
                            child: Container(
                              margin: EdgeInsets.only(left: 5, top: 5),
                              child: Text(
                                this.widget.msgObj.message,
                                style: TextStyle(
                                  color: this.widget.msgObj.isMe == true
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                        bottom: 5.0,
                        right: 10.0,
                        child: Row(
                          children: <Widget>[
                            Text(getTime(),
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  color: this.widget.msgObj.isMe == true
                                      ? Colors.white70
                                      : Colors.black,
                                  fontSize: 9.0,
                                )),
                            SizedBox(width: 3.0),
                            (this.widget.msgObj.isMe == true)
                                ? (Icon(
                                    this.widget.msgObj.haveReachedServer
                                        ? (this.widget.msgObj.haveReceived
                                            ? (this.widget.msgObj.hasSeen ==
                                                    true)
                                                ? Icons.done_outline_sharp
                                                : Icons.done_all
                                            : Icons.done)
                                        : Icons.timelapse_outlined,
                                    size: 12.0,
                                    color: Colors.black38,
                                  ))
                                : Container()
                          ],
                        ))
                  ])))
        ]);
  }

  swipeAble(context) => SwipeTo(
        offsetDx: .2,
        iconColor: Colors.black54,
        iconSize: 16,
        child: cloudContent(context),
        onLeftSwipe: widget.msgObj.isMe
            ? () => widget.swipingHandler(this.widget.msgObj)
            : null,
        onRightSwipe: widget.msgObj.isMe
            ? null
            : () => widget.swipingHandler(this.widget.msgObj),
      );

  bool hasSelected = false;

  @override
  Widget build(BuildContext context) {
    return this.widget.disableSwipe
        ? cloudContent(context)
        : GestureDetector(
            onLongPress: (widget.msgObj.haveReachedServer ?? false) ||
                    (widget.msgObj.isMe == false)
                ? () {
                    print("on long press");
                    // widget.outerSetState(() {
                    //   widget.hasSelectedSomething = true;
                    // });
                    widget.outerSetState();
                    setState(() {
                      hasSelected = true;
                    });
                    widget.forwardMap[widget.msgObj.id] = widget.msgObj;
                    print(widget.forwardMap);
                  }
                : null,
            onTap: (((widget.msgObj.haveReachedServer ?? false) ||
                        (widget.msgObj.isMe == false)) &&
                    widget.forwardMap.length >= 1)
                ? (widget.hasSelectedSomething ?? false)
                    ? () {
                        if (hasSelected == true) {
                          if (widget.forwardMap.length == 1) {
                            widget.forwardRemover();
                            widget.outerSetState(false);
                            widget.forwardMap.remove(widget.msgObj.id);
                          } else {
                            widget.forwardMap.remove(widget.msgObj.id);
                          }
                          setState(() {
                            hasSelected = false;
                          });
                        } else if (hasSelected == false) {
                          widget.forwardMap[widget.msgObj.id] = widget.msgObj;
                          setState(() {
                            hasSelected = true;
                          });
                        }
                        print(widget.forwardMap);
                      }
                    : null
                : null,
            child: Container(
                color: //(widget.hasSelectedSomething &&
                    (widget.forwardMap.containsKey(widget.msgObj.id) &&
                            hasSelected)
                        ? Colors.blue.withOpacity(.3)
                        : Colors.transparent,
                child: swipeAble(context)));
    // return Row(mainAxisAlignment: MainAxisAlignment.start,
    //     // msgObj.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
    //     children: [cloudContent(context)]);
  }
}

singleDot() => Container(
    height: 5,
    width: 5,
    decoration: BoxDecoration(
      gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.blueGrey[300]]),
      color: Colors.black,
      shape: BoxShape.circle,
    ));
doubleDot() => Row(
      children: [
        singleDot(),
        // SizedBox(width: .5),
        singleDot(),
      ],
    );
