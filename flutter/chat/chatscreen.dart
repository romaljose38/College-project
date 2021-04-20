import 'dart:async';

import 'package:flutter/material.dart';
import 'package:testproj/chat/chatcloudlist.dart';
import 'package:testproj/chat/socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'chatcloud.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testproj/models.dart';
import 'package:hive_listener/hive_listener.dart';
import 'package:hive/hive.dart';


class ChatScreen extends StatefulWidget {
  // final NotificationController controller;
  final Thread thread;

  ChatScreen({Key key, 
  // this.controller,
   this.thread}) : super(key:key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List _chatList = [];
  String curUser;
  String otherUser;
  String threadName;
  TextEditingController _chatController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  Thread thread;
  // Stream stream;
  // _updateList(data){
  //   print(data);
  //   _chatList.add(ChatCloud("Hello",self:true));
  // }

  @override
  void initState(){
    super.initState();
    otherUser = widget.thread.second.name;
    threadName = widget.thread.first.name + "_" + widget.thread.second.name;
    //Initializing the _chatList as the chatList of the current thread
    _chatList = widget.thread.chatList;
    thread = Hive.box('threads').get(threadName);
    // _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    //Gets the username of the logged in user.
    //We need the current username to distinguish between the sender and receiver. So that the chatclouds can be aligned 
    //on their respective sides.
    _getUserName();
  }

  void _getUserName() async{
    SharedPreferences _prefs = await SharedPreferences.getInstance();
      curUser= _prefs.getString('user');
  }
  
  void _sendMessage() {
    
    // print(widget.channel.protocol);
    var data = jsonEncode({
      'message':_chatController.text,
      'from':curUser,
      'to':otherUser,
    });
    if (_chatController.text.isNotEmpty) {
      if(NotificationController.isActive){
      NotificationController.sendToChannel(data);
      }
      else{
        print("not connected");
      }
      _chatController.text="";
    }
  }
  

  @override
  Widget build(BuildContext context) {

    
    return Scaffold(
      backgroundColor: Color.fromRGBO(240, 247, 255, 1),
        appBar:PreferredSize(
        preferredSize: Size(double.infinity,100),
        child:SafeArea(
                  child: Container(
                      height:100,
                      decoration: BoxDecoration(
                        
                        gradient:LinearGradient(
                          begin:Alignment.topLeft,
                          end:Alignment.bottomRight,
                          stops:[.3,1],
                          colors:[Color.fromRGBO(248, 251, 255, 1), Color.fromRGBO(240, 247, 255, 1)]
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        boxShadow: [
                          BoxShadow(
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset:Offset(0,3),
                            color: Color.fromRGBO(226, 235, 243, 1),
                          )
                        ]

                      ),
                      child:Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children:
                          [ 
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal:20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                      Text("Active", 
                                            style: TextStyle(
                                              fontSize: 15,
                                              color:Color.fromRGBO(180, 190, 255, 1)
                                            ),
                                            ),
                                      SizedBox(height:7),
                                      Text(widget.thread.second.name, 
                                          style:TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color:Color.fromRGBO(59, 79, 108, 1))
                                          )                              
                                    ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: CircleAvatar(
                                  radius:35,
                                  child:Text(widget.thread.second.name),
                                ),
                              ) 
                              
                          ]
                        ),
                      )
                       ),
        )
        ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
            child: Column(
            children:<Widget>[
                Expanded(
                  child: HiveListener(
                                      box:Hive.box("Threads"),
                                      keys:[threadName],
                                      builder: (box){
                                      
                                        var thread = box.get(threadName);
                                        
                                        List __chatList = thread.chatList ?? [];

                                        return ChatCloudList(chatList: __chatList,needScroll: true,);
                                        },
                                       
                  )
                
                  ),
                
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color:Colors.white,
                    borderRadius: BorderRadius.only(topLeft:Radius.circular(10),topRight:Radius.circular(10)),
                    
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child:TextField(
                          controller: _chatController,
                          decoration: InputDecoration.collapsed(
                            hintText: "Send a message",
                            hintStyle: TextStyle(
                              color:Color.fromRGBO(150, 150, 150, 1),
                            )),
                        ),
                      ),
                      IconButton(icon: Icon(Icons.send), 
                      onPressed:_sendMessage,
                      splashColor: Colors.pinkAccent,
                      splashRadius: 16,
                      padding:EdgeInsets.fromLTRB(0, 0, 0, 16),)
                    ],
                ),
                  )),
              
              ]
        ),
          ),
      );
    
  }
}