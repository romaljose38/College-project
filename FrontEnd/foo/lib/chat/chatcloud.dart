import 'package:intl/intl.dart' as intl;
import 'package:flutter/material.dart';
import 'package:foo/models.dart';
import 'package:swipe_to/swipe_to.dart';

class ChatCloud extends StatefulWidget {
  final ChatMessage msgObj;
  final Function swipingHandler;
  final bool disableSwipe;
  final Function outerSetState;
  bool hasSelectedSomething;
  Map forwardMap;
  Function forwardRemover;

  ChatCloud(
      {Key key,
      this.msgObj,
      this.swipingHandler,
      this.forwardRemover,
      this.disableSwipe = false,
      this.outerSetState,
      this.forwardMap,
      this.hasSelectedSomething})
      : super(key: key);

  @override
  _ChatCloudState createState() => _ChatCloudState();
}

class _ChatCloudState extends State<ChatCloud> {
  String getTime() => intl.DateFormat('hh:mm').format(this.widget.msgObj.time);

  Row cloudContent(BuildContext context) {
    return Row(
        mainAxisAlignment: (this.widget.msgObj.isMe == true)
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
              margin: EdgeInsets.all(5),
              // alignment: Alignment.topLeft,
              padding: EdgeInsets.all(5),
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
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                        blurRadius: 6,
                        spreadRadius: .5,
                        offset: Offset(1, 5),
                        color: (this.widget.msgObj.isMe == true)
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
                    Positioned(
                      bottom: 0.0,
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
                                  (this.widget.msgObj.haveReachedServer ??
                                          false)
                                      ? (this.widget.msgObj.haveReceived
                                          ? (this.widget.msgObj.hasSeen == true)
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
    print("isMe");
    print(widget.msgObj.isMe);
    return this.widget.disableSwipe
        ? cloudContent(context)
        : GestureDetector(
            onLongPress: (widget.msgObj.haveReachedServer ?? false)
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
            onTap: (widget.msgObj.haveReachedServer ?? false)
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
                color: ((widget.hasSelectedSomething ?? false) &&
                        widget.forwardMap.containsKey(widget.msgObj.id) &&
                        hasSelected)
                    ? Colors.blue.withOpacity(.3)
                    : Colors.transparent,
                child: swipeAble(context)));
  }
}
