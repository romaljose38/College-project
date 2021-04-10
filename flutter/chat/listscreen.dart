import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'chattile.dart';
import 'package:testproj/models.dart';
import 'package:hive/hive.dart';

class ChatListScreen extends StatefulWidget {

  final Stream stream;
  List threads = [];

  ChatListScreen({Key key, @required this.stream, this.threads}) : super(key:key);

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text("Conversations",
                style: TextStyle(
                    color: Color.fromRGBO(60, 82, 111, 1),
                    fontWeight: FontWeight.bold))
            // actions: [Icon(Icons.more)],
            ),
        body: Container(
            width:MediaQuery.of(context).size.width ,
            decoration: BoxDecoration(color: Color.fromRGBO(241, 247, 255, 1)),
            child: Padding(padding: EdgeInsets.only(top: 80),
             child: ListView.builder(
               itemCount: widget.threads.length,
               itemBuilder: (context,index){
                return ChatTile(stream:widget.stream,thread:widget.threads[index]);
               },
             ),

            // Column(
              // children: [
              //   SizedBox(height: 30,),
              //   widget.threads.forEach((element) {
              //   ChatTile(stream: widget.stream, userName: element.second.name);
              //   })
              // ],
            // )
            )),
      ),
    );
  }
}
