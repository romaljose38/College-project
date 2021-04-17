import 'package:flutter/material.dart';


class ChatCloud extends StatelessWidget {
  final String text;
  final bool self;

  ChatCloud({this.text,this.self});


  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:(self==true)?MainAxisAlignment.end:MainAxisAlignment.start,
      children: [
        Container(
          margin:EdgeInsets.all(5),
          alignment:Alignment.topLeft,
          
          padding:EdgeInsets.all(5),
          decoration: BoxDecoration(
            gradient:(this.self==true)?
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
                color:(this.self==true)?Color.fromRGBO(248, 198, 220, 1):Color.fromRGBO(218, 228, 237, 1)
              )
            ]
          ),
          child:Stack(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Text(this.text),
              ),
              Positioned(
                bottom: 0.0,
                right: 0.0,
                child: Row(
                  children: <Widget>[
                    Text('01:30PM',
                        style: TextStyle(
                          color: Colors.black38,
                          fontSize: 10.0,
                        )),
                    SizedBox(width: 3.0),
                    Icon(
                      Icons.done,
                      size: 12.0,
                      color: Colors.black38,
                    )
                  ],
                ),
              )
      ],
    ))]);
  }
}