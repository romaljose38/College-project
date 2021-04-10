import 'package:flutter/material.dart';
import 'chatscreen.dart';
import 'package:testproj/models.dart';


class ChatTile extends StatelessWidget {
  
  final Stream stream;
  final Thread thread;
  
  ChatTile({this.stream,this.thread});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:Colors.transparent,
      ),
      width:MediaQuery.of(context).size.width,
      child:ListTile(onTap:(){
        Navigator.push(context, MaterialPageRoute(
          builder : (context) => ChatScreen(
            stream: this.stream,
            thread:this.thread
            )));
      },
      leading:CircleAvatar(
        child:Text(this.thread.second.name),
      ),
      title:Text('hei')),
    );
  }
}