import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'chatscreen.dart';
import 'package:testproj/models.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:hive_listener/hive_listener.dart';


class ChatTile extends StatelessWidget {
  
  final WebSocketChannel channel;
  final Thread thread;
  
  ChatTile({this.channel,this.thread});


 String getDate(DateTime date) =>DateFormat("dd-MM-yyyy").format(date);


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:Colors.transparent,
      ),
      width:MediaQuery.of(context).size.width,
      child:ListTile(
        trailing: Text(getDate(thread.lastAccessed)),
        onTap:(){
        Navigator.push(context, MaterialPageRoute(
          builder : (context) => ChatScreen(
            channel:this.channel,
            thread:this.thread
            )));
              },
        leading:CircleAvatar(
                child:Text(this.thread.second.name),
              ),
        title:Text(thread.chatList.last.message)),
    );
  }
}