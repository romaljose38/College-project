import 'package:hive/hive.dart';

part 'models.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  String name;

  User({this.name});
}

@HiveType(typeId: 1)
class ChatMessage extends HiveObject {
  @HiveField(0)
  Thread thread;

  @HiveField(1)
  String message;

  @HiveField(2)
  DateTime time;

  @HiveField(3)
  String senderName;

  @HiveField(4)
  bool haveReceived = false;

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

  @HiveField(10)
  bool haveReachedServer = false;

  @HiveField(11)
  String filePath;

  ChatMessage(
      {this.thread,
      this.message,
      this.time,
      this.id,
      this.senderName,
      this.isMe,
      this.msgType,
      this.base64string,
      this.ext,
      this.filePath});
}

@HiveType(typeId: 2)
class Thread extends HiveObject {
  @HiveField(0)
  User first;

  @HiveField(1)
  User second;

  @HiveField(2)
  List<ChatMessage> chatList = <ChatMessage>[];

  @HiveField(3)
  DateTime lastAccessed;

  Thread({this.first, this.second});

  void addChat(chat) {
    this.chatList.add(chat);
    this.lastAccessed = chat.time;
  }

  List<ChatMessage> getChatList() {
    return chatList;
  }

  bool updateChatStatus(id) {
    for (int i = 0; i < chatList.length; i++) {
      if (chatList[chatList.length - 1 - i].id == id) {
        chatList[chatList.length - 1 - i].haveReceived = true;
        return true;
      }
    }
    return false;
  }

  bool updateChatId({id, newId}) {
    for (int i = 0; i < chatList.length; i++) {
      if (chatList[chatList.length - 1 - i].id == id) {
        chatList[chatList.length - 1 - i].id = newId;
        chatList[chatList.length - 1 - i].haveReachedServer = true;
        return true;
      }
    }
  }

  bool needToCheck() {
    if (this.chatList.last.isMe == true) {
      if (this.chatList.last.haveReachedServer == true) {
        return false;
      } else {
        return true;
      }
    }
    return false;
  }

  List getUnsentMessages() {
    List msgs = [];
    for (int i = 0; i < chatList.length; i++) {
      if (chatList[chatList.length - 1 - i].haveReachedServer != true) {
        msgs.add(chatList[chatList.length - 1 - i]);
      } else if (chatList[chatList.length - 1 - i].haveReachedServer == true) {
        return msgs;
      }
    }
  }
}

class Post {
  String username;
  String userDpUrl;
  String postUrl;
  int likeCount;
  int commentCount;
}

class Comment {
  String username;
  String userdpUrl;
  String comment;
}

class Feed {
  List<Post> posts = <Post>[];

  void addPost(Post post) {
    if (this.posts.length == 10) {
      posts.insert(0, post);
      posts.removeLast();
    } else {
      posts.insert(0, post);
    }
  }
}
