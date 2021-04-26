import 'package:hive/hive.dart';



part 'models.g.dart';

@HiveType(typeId:0)
class User extends HiveObject{

  @HiveField(0)
  String name;
  
  User({this.name});
}

@HiveType(typeId:1)
class ChatMessage extends HiveObject{

  @HiveField(0)
  Thread thread;

  @HiveField(1)
  String message;

  @HiveField(2)
  DateTime time;

  @HiveField(3)
  String senderName;

  @HiveField(4)
  bool haveReceived=false;

  @HiveField(5)
  int id;

  @HiveField(6)
  bool isMe = false;

  @HiveField(7)
  String msgType;

  @HiveField(8)
  String base64string;

  @HiveField(9)
  String ext;

  ChatMessage({this.thread, this.message, this.time, this.id, this.senderName, this.isMe, this.msgType, this.base64string, this.ext});
}


@HiveType(typeId: 2)
class Thread extends HiveObject{

  @HiveField(0)
  User first;

  @HiveField(1)
  User second;

  @HiveField(2)
  List<ChatMessage> chatList = <ChatMessage>[];

  @HiveField(3)
  DateTime lastAccessed;

  Thread({this.first,this.second});

  void addChat(chat){
    this.chatList.add(chat);
    this.lastAccessed=chat.time;
  }

  List<ChatMessage> getChatList(){
    return chatList;
  }

bool updateChatStatus(id){
    for(int i=0;i<chatList.length;i++){
      if(chatList[chatList.length-1-i].id==id){
        chatList[chatList.length-1-i].haveReceived = true;
        return true;
      }
  
  }
  return false;
  }

}

