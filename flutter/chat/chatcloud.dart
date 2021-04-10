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
          child:Container(
            padding:EdgeInsets.all(14),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .7),
            child: Text(this.text,
                        textAlign:TextAlign.start,
                        
                        style:TextStyle(
                          fontSize: 14,
                          color:(this.self==true)?Colors.white:Colors.black.withOpacity(.7),
                          letterSpacing: 1.1,
                        
                        )),
          )
          
        ),
      ],
    );
  }
}