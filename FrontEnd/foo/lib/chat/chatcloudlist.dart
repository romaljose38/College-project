import 'package:flutter/material.dart';
import 'chatcloud.dart';
import 'dart:async';


class ChatCloudList extends StatefulWidget {

  List chatList;
  bool needScroll;
  String curUser;

  ChatCloudList({Key key,this.chatList,this.needScroll,this.curUser});

  @override
  _ChatCloudListState createState() => _ChatCloudListState();
}

class _ChatCloudListState extends State<ChatCloudList> {
ScrollController _scrollController = ScrollController();
  String curUser;

  @override
  void initState(){
    super.initState();
    // _setname();
  }

  void _setname() {
    curUser = widget.curUser;
  }

  


  void _scrollToEnd() async {
  _scrollController.animateTo(
    _scrollController.position.minScrollExtent,
    duration: Duration(milliseconds: 100),
    curve:Curves.linear
    );
}
 
  @override
  Widget build(BuildContext context) {
    
    if (widget.needScroll) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Timer(Duration(milliseconds: 100),()=>{_scrollToEnd()}));
  }

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _setname());

    return ListView.builder(
        reverse: true,                       
        controller: _scrollController,
        itemCount: widget.chatList.length??0,
        itemBuilder: (context,index){
          final reversedIndex = widget.chatList.length -1-index;
          // print(widget.chatList[reversedIndex].senderName);
          print(widget.chatList[reversedIndex].isMe);
            return ChatCloud(msgObj: widget.chatList[reversedIndex]);
          // print(curUser);
          // if(widget.chatList[reversedIndex].senderName == curUser){
          //   // print('me');
          //   return ChatCloud(msgObj:widget.chatList[reversedIndex],self:true);
          // }
          // else{
            
          //   return ChatCloud(msgObj:widget.chatList[reversedIndex],self:false);
          // }
        }
        );
  }
}