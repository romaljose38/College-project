import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'chattile.dart';
import 'package:testproj/models.dart';
import 'package:hive/hive.dart';
import 'socket.dart';

class ChatListScreen extends StatefulWidget {

  // final NotificationController controller;
  List threads = [];

  ChatListScreen({Key key,
  //  @required this.controller, 
   this.threads}) : super(key:key);

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {

  @override
  void initState(){
    super.initState();
  }

  

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child:Scaffold(
              backgroundColor: Color.fromRGBO(226, 235, 243, 1),
              body: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomScrollView(
                  
          slivers: [SliverAppBar(brightness:Brightness.dark,
            expandedHeight:150,
            floating: true,
            backgroundColor: Colors.transparent,
            leading: Icon(Icons.arrow_back,color: Colors.black,),
            flexibleSpace: FlexibleSpaceBar(background: Align(
                alignment:Alignment.centerLeft,child:Padding(
                  padding: const EdgeInsets.only(left:30),
                  child: Text("Conversation",style: TextStyle(
                      color: Color.fromRGBO(60, 82, 111, 1),
                      fontWeight: FontWeight.w700,
                      fontSize: 25)),
                ),)
          )),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              
                (context,index){
                return ChatTile(
                  // controller:widget.controller,
                  thread:widget.threads[index]);
               },
               childCount:widget.threads==null?0:widget.threads.length,
            ),
          )
          ],

        ),
              ),
      )
      // child: Scaffold(
      //   backgroundColor: Colors.transparent,
      //   extendBodyBehindAppBar: true,
      //   appBar: AppBar(
      //     leading: Icon(Icons.arrow_back,color: Colors.black,),
      //       backgroundColor: Colors.transparent,
      //       elevation: 0,
      //       title: Text("Conversations",
      //           style: TextStyle(
      //               color: Color.fromRGBO(60, 82, 111, 1),
      //               fontWeight: FontWeight.bold)),
      //        actions: [Icon(Icons.more_vert,color:Colors.black)],
      //       ),
      //   body: Container(
      //       width:MediaQuery.of(context).size.width ,
      //       decoration: BoxDecoration(color: Color.fromRGBO(241, 247, 255, 1)),
      //       child: Padding(padding: EdgeInsets.only(top: 80),
      //        child: ListView.builder(
      //          itemCount: widget.threads==null?0:widget.threads.length,
      //          itemBuilder: (context,index){
      //           return ChatTile(channel:widget.channel,thread:widget.threads[index]);
      //          },
      //        ),

      //       // Column(
      //         // children: [
      //         //   SizedBox(height: 30,),
      //         //   widget.threads.forEach((element) {
      //         //   ChatTile(stream: widget.stream, userName: element.second.name);
      //         //   })
      //         // ],
      //       // )
      //       )),
      // ),
    );
  }
}
