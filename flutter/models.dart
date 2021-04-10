import 'package:hive/hive.dart';



part 'models.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject{

  @HiveField(0)
  String name;
  
  User({this.name});
}

@HiveType(typeId: 1)
class ChatMessage extends HiveObject{

  @HiveField(0)
  Thread thread;

  @HiveField(1)
  String message;

  @HiveField(2)
  DateTime time;

  @HiveField(3)
  String senderName;

  ChatMessage({this.thread,this.message,this.time,this.senderName});
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

}

