import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter/material.dart';
import 'package:foo/models.dart';

class ChatCloud extends StatelessWidget {
  final ChatMessage msgObj;
  final bool needDate;
  ChatCloud({this.msgObj, this.needDate});

  String getTime() => intl.DateFormat('hh:mm').format(this.msgObj.time);

  Row cloudContent(BuildContext context) {
    return Row(
        mainAxisAlignment: (this.msgObj.isMe == true)
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
              margin: EdgeInsets.all(5),
              alignment: Alignment.topLeft,
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
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 10.0,
                              )),
                          SizedBox(width: 3.0),
                          (this.msgObj.isMe == true)
                              ? (Icon(
                                  this.msgObj.haveReachedServer
                                      ? (this.msgObj.haveReceived
                                          ? Icons.done_all
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

  Row dateCloud() {
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
          child: Text(intl.DateFormat("d MMMM y").format(this.msgObj.time),
              style: GoogleFonts.openSans(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        (needDate == true) ? dateCloud() : Container(),
        cloudContent(context)
      ],
    );
  }
}
