import 'package:intl/intl.dart' as intl;
import 'package:flutter/material.dart';
import 'package:foo/models.dart';
import 'package:swipe_to/swipe_to.dart';

class ChatCloud extends StatelessWidget {
  final ChatMessage msgObj;
  final Function swipingHandler;
  final bool disableSwipe;

  ChatCloud({this.msgObj, this.swipingHandler, this.disableSwipe = false});

  String getTime() => intl.DateFormat('hh:mm').format(this.msgObj.time);

  Row cloudContent(BuildContext context) {
    return Row(
        mainAxisAlignment: (this.msgObj.isMe == true)
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
              margin: EdgeInsets.all(5),
              // alignment: Alignment.topLeft,
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                  gradient: (this.msgObj.isMe == true)
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
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                  boxShadow: [
                    BoxShadow(
                        blurRadius: 6,
                        spreadRadius: .5,
                        offset: Offset(1, 5),
                        color: (this.msgObj.isMe == true)
                            ? Color.fromRGBO(248, 198, 220, 1)
                            : Color.fromRGBO(218, 228, 237, 1))
                  ]),
              child: Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * .7,
                    minWidth: 70),
                child: Stack(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.fromLTRB(5, 5, 5, 15),
                      child: Text(
                        this.msgObj.message,
                        style: TextStyle(
                          color: this.msgObj.isMe == true
                              ? Colors.white
                              : Colors.black,
                        ),
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Positioned(
                      bottom: 0.0,
                      right: 10.0,
                      child: Row(
                        children: <Widget>[
                          Text(getTime(),
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                color: this.msgObj.isMe == true
                                    ? Colors.white70
                                    : Colors.black,
                                fontSize: 9.0,
                              )),
                          SizedBox(width: 3.0),
                          (this.msgObj.isMe == true)
                              ? (Icon(
                                  this.msgObj.haveReachedServer
                                      ? (this.msgObj.haveReceived
                                          ? (this.msgObj.hasSeen == true)
                                              ? Icons.done_outline_sharp
                                              : Icons.done_all
                                          : Icons.done)
                                      : Icons.timelapse_outlined,
                                  size: 12.0,
                                  color: Colors.black38,
                                ))
                              : Container()
                        ],
                      ),
                    )
                  ],
                ),
              ))
        ]);
  }

  swipeAble(context) => SwipeTo(
        offsetDx: .2,
        iconColor: Colors.black54,
        iconSize: 16,
        child: cloudContent(context),
        onLeftSwipe: msgObj.isMe ? () => swipingHandler(this.msgObj) : null,
        onRightSwipe: msgObj.isMe ? null : () => swipingHandler(this.msgObj),
      );

  @override
  Widget build(BuildContext context) {
    return this.disableSwipe ? cloudContent(context) : swipeAble(context);
  }
}
