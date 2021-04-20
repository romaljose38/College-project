import 'package:flutter/material.dart';
import 'package:testproj/models.dart';


class ChatCloud extends StatelessWidget {
  final ChatMessage msgObj;
  final bool self;

  ChatCloud({this.msgObj,
  this.self
  });


  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:(this.msgObj.isMe==true)?MainAxisAlignment.end:MainAxisAlignment.start,
      children: [
        Container(
          margin:EdgeInsets.all(5),
          alignment:Alignment.topLeft,
          
          padding:EdgeInsets.all(5),
          decoration: BoxDecoration(
            gradient:(this.msgObj.isMe==true)?
            LinearGradient(
                          begin:Alignment.topRight,
                          end:Alignment.bottomLeft,
                          stops:[.3,1],
                          colors:[Color.fromRGBO(255,143,187,1), Color.fromRGBO(255,117,116,1)]
                        )
            :
            LinearGradient(
                          begin:Alignment.topRight,
                          end:Alignment.bottomLeft,
                          stops:[.3,1],
                          colors:[Color.fromRGBO(248, 251, 255, 1), Color.fromRGBO(240, 247, 255, 1)]
                        ),
            borderRadius: BorderRadius.all(Radius.circular(50)),
            boxShadow: [
              BoxShadow(
                blurRadius: 6,
                spreadRadius: .5,
                offset:Offset(1,5),
                color:(this.msgObj.isMe==true)?Color.fromRGBO(248, 198, 220, 1):Color.fromRGBO(218, 228, 237, 1)
              )
            ]
          ),
          child:Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .7,minWidth: 70),
            child: Stack(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.fromLTRB(5, 5, 5, 15),
                  child: Text(this.msgObj.message
                                ,style:TextStyle(color: this.msgObj.isMe==true?Colors.white:Colors.black,),
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.left,),
                ),
                Positioned(
                  bottom: 0.0,
                  right: 10.0,
                  child: Row(
                    children: <Widget>[
                      Text('01:30PM',
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            color:this.msgObj.isMe==true?Colors.white:Colors.black,
                            fontSize: 10.0,
                          )),
                      SizedBox(width: 3.0),
                      Icon(
                        this.msgObj.haveReceived?Icons.done_all:Icons.done,
                        size: 12.0,
                        color: Colors.black38,
                      )
                    ],
                  ),
                )
      ],
    ),
          ))]);
  }
}