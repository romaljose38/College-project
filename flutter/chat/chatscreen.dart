import 'package:flutter/material.dart';
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
  final Stream stream;
  final Thread thread;

  ChatScreen({Key key, this.stream, this.thread}) : super(key:key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List _chatList = [];
  String curuser;
  String threadName;
  // Stream stream;
  // _updateList(data){
  //   print(data);
  //   _chatList.add(ChatCloud("Hello",self:true));
  // }

  @override
  void initState(){
    super.initState();
    threadName = widget.thread.first.name + "_" + widget.thread.second.name;
    //Initializing the _chatList as the chatList of the current thread
    _chatList = widget.thread.chatList;

    //Gets the username of the logged in user.
    //We need the current username to distinguish between the sender and receiver. So that the chatclouds can be aligned 
    //on their respective sides.
    _getUserName();
  }

  void _getUserName() async{
    SharedPreferences _prefs = await SharedPreferences.getInstance();
      curuser= _prefs.getString('user');
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
                                        
                                        List __chatList = thread.chatList;

                                        return ListView.builder(
                                         itemCount: __chatList.length,
                                         itemBuilder: (context,index){
                                            if(__chatList[index].senderName == curuser){
                                              return ChatCloud(text:__chatList[index].message,self:true);
                                            }
                                            else{
                                              return ChatCloud(text:__chatList[index].message,self:false);
                                            }
                                         }
                                         );},
                                       
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
                          decoration: InputDecoration.collapsed(
                            hintText: "Send a message",
                            hintStyle: TextStyle(
                              color:Color.fromRGBO(150, 150, 150, 1),
                            )),
                        ),
                      ),
                      IconButton(icon: Icon(Icons.send), 
                      onPressed:(){},
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