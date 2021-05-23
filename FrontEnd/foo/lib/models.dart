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

  @HiveField(12)
  bool hasSeen;

  ChatMessage({
    this.thread,
    this.message,
    this.time,
    this.id,
    this.senderName,
    this.isMe = false,
    this.msgType,
    this.base64string,
    this.ext,
    this.filePath,
  });
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

  @HiveField(4)
  bool isTyping;

  @HiveField(5)
  int hasUnseen;

  @HiveField(6)
  bool isOnline;

  @HiveField(7)
  DateTime lastSeen;

  Thread({this.first, this.second});

  void addChat(chat) {
    final now = DateTime.now();
    if (this.chatList.length > 0) {
      final lastDay = DateTime(this.chatList.last.time.year,
          this.chatList.last.time.month, this.chatList.last.time.day);
      final dateToCheck =
          DateTime(chat.time.year, chat.time.month, chat.time.day);
      if (dateToCheck != lastDay) {
        this.chatList.add(ChatMessage(msgType: "date", time: chat.time));
      }
    }
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

  bool updateChatSeenStatus(id) {
    for (int i = 0; i < chatList.length; i++) {
      var index = chatList.length - 1 - i;
      if (chatList[index].id <= id) {
        if (chatList[index].hasSeen != true) {
          chatList[index].hasSeen = true;
        }
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
    if (this.chatList.length > 0) {
      if (this.chatList.last.isMe == true) {
        if (this.chatList.last.haveReachedServer == true) {
          return false;
        } else {
          return true;
        }
      }
      return false;
    }
    return false;
  }

  List getUnsentMessages() {
    List msgs = [];
    if (chatList.length > 0) {
      for (int i = 0; i < chatList.length; i++) {
        if (chatList[chatList.length - 1 - i].haveReachedServer != true) {
          msgs.add(chatList[chatList.length - 1 - i]);
        } else if (chatList[chatList.length - 1 - i].haveReachedServer ==
            true) {
          return msgs;
        }
      }
      return msgs;
    }
  }
}

@HiveType(typeId: 3)
class Post {
  @HiveField(0)
  String username;

  @HiveField(1)
  String userDpUrl;

  @HiveField(2)
  String postUrl;

  @HiveField(3)
  int likeCount = 0;

  @HiveField(4)
  int commentCount;

  @HiveField(5)
  int postId;

  @HiveField(6)
  bool haveLiked;

  @HiveField(7)
  int userId;

  @HiveField(8)
  String type;

  @HiveField(9)
  String caption;

  Post(
      {this.username,
      this.userDpUrl,
      this.postUrl,
      this.likeCount,
      this.commentCount,
      this.postId,
      this.haveLiked,
      this.userId,
      this.type,
      this.caption});
}

class Comment {
  String username;
  String userdpUrl;
  Map comment;

  Comment({this.username, this.userdpUrl, this.comment});
}

@HiveType(typeId: 4)
class Feed extends HiveObject {
  @HiveField(0)
  List<Post> posts = <Post>[];

  void addPost(Post post) {
    if (this.posts.length == 10) {
      for (int i = 0; i < this.posts.length; i++) {
        if (this.posts[i].postId == post.postId) {
          this.posts.removeAt(i);
          this.posts.insert(i, post);
          return;
        }
      }
      posts.insert(0, post);
      posts.removeLast();
    } else {
      for (int i = 0; i < this.posts.length; i++) {
        if (this.posts[i].postId == post.postId) {
          this.posts.removeAt(i);
          this.posts.insert(i, post);
          return;
        }
      }
      posts.insert(0, post);
    }
  }

  bool isNew(int id) {
    if (this.posts != null) {
      if (this.posts.length > 0) {
        if (this.posts.first.postId < id) {
          return true;
        }
        return false;
      }
      return true;
    }
    return true;
  }

  updatePostStatus(int id, bool status) {
    this.posts.forEach((element) {
      if (element.postId == id) {
        if ((status == true) & (element.haveLiked == true)) {
          return;
        }
        if ((status == false) & (element.haveLiked == false)) {
          return;
        }
        element.haveLiked = status;
        if (status == true) {
          if (element.likeCount == null) {
            element.likeCount = 1;
          } else {
            element.likeCount += 1;
          }
        } else {
          element.likeCount -= 1;
        }
      }
    });
  }
}

@HiveType(typeId: 5)
enum NotificationType {
  @HiveField(0)
  mention,

  @HiveField(1)
  friendRequest
}

@HiveType(typeId: 6)
class Notifications extends HiveObject {
  @HiveField(0)
  NotificationType type;

  @HiveField(1)
  String userName;

  @HiveField(2)
  int userId;

  @HiveField(3)
  DateTime timeCreated;

  @HiveField(4)
  bool hasAccepted;

  @HiveField(5)
  int notifId;

  Notifications(
      {this.type, this.userName, this.userId, this.timeCreated, this.notifId});
}

// Story models ahead

@HiveType(typeId: 7)
class Story extends HiveObject {
  @HiveField(0)
  String file;

  @HiveField(1)
  int views;

  @HiveField(2)
  DateTime time;

  @HiveField(3)
  bool viewed;

  @HiveField(4)
  int storyId;

  @HiveField(5)
  int notificationId;

  Story(
      {this.file,
      this.views,
      this.time,
      this.viewed,
      this.storyId,
      this.notificationId});

  String display() {
    return 'file: $file - seen: $viewed - time: $time';
  }
}

@HiveType(typeId: 8)
class UserStoryModel extends HiveObject {
  @HiveField(0)
  String username;

  @HiveField(1)
  int userId;

  @HiveField(2)
  List<Story> stories = <Story>[];

  @HiveField(3)
  DateTime timeOfLastStory;

  @HiveField(4)
  List<StoryUser> viewedUsers = <StoryUser>[];

  UserStoryModel({this.username, this.userId, this.stories});

  int hasUnSeen() {
    //If the userstorymodel has a story that is unseen it returns the index of that story or otherwise return -1
    for (int index = 0; index < stories.length; index++) {
      if (stories[index].viewed == null) return index;
    }
    return -1;
  }

  void addStory(Story story) {
    if (stories.where((x) => x.storyId == story.storyId).length >
        0) //ie, if element already exists
      return;
    else {
      stories.add(story);
      timeOfLastStory = story.time;
    }
  }

  bool isEmpty() {
    if (stories != null) {
      if (stories.length == 0) {
        return true; //returns true if length is 0
      }
      return false; //returns false if length > 0 as length is non-negative
    }
    return true; //return true if stories is null
  }
}

@HiveType(typeId: 9)
class StoryUser extends HiveObject {
  @HiveField(0)
  String fName;

  @HiveField(1)
  String lName;

  @HiveField(2)
  String username;

  @HiveField(3)
  String profilePicture;
}
