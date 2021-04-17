import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chatcloud.dart';
import 'dart:async';
class ChatCloudList extends StatefulWidget {

  List chatList;
  bool needScroll;

  ChatCloudList({Key key,this.chatList,this.needScroll});

  @override
  _ChatCloudListState createState() => _ChatCloudListState();
}

class _ChatCloudListState extends State<ChatCloudList> {

  String curUser;

  @override
  void initState(){
    super.initState();
    _setname();
  }

  void _setname() async{
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    curUser= _prefs.getString('user');
  }

  ScrollController _scrollController = ScrollController();


  void _scrollToEnd() async {
  _scrollController.animateTo(
    _scrollController.position.maxScrollExtent,
    duration: Duration(milliseconds: 100),
    curve:Curves.linear
    );
}

  @override
  Widget build(BuildContext context) {

    if (widget.needScroll) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Timer(Duration(milliseconds: 100),()=>_scrollToEnd()));
  }
  
    

    return ListView.builder(
                                          
                                          controller: _scrollController,
                                         itemCount: widget.chatList.length??0,
                                         itemBuilder: (context,index){
                                            if(widget.chatList[index].senderName == curUser){
                                              
                                              return ChatCloud(text:widget.chatList[index].message,self:true);
                                            }
                                            else{
                                              
                                              return ChatCloud(text:widget.chatList[index].message,self:false);
                                            }
                                         }
                                         );
  }
}