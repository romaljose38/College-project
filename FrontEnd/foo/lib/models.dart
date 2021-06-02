import 'dart:io';

import 'package:hive/hive.dart';

part 'models.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String dpUrl;

  @HiveField(2)
  String f_name;

  @HiveField(3)
  String l_name;

  @HiveField(4)
  int userId;

  User({this.name, this.dpUrl, this.f_name, this.l_name, this.userId});
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
  String replyMsgTxt;

  @HiveField(9)
  int replyMsgId;

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
    this.replyMsgTxt,
    this.replyMsgId,
    this.filePath,
  });

  factory ChatMessage.fromObj(obj) {
    return ChatMessage(
        message: obj.message,
        id: obj.id,
        senderName: obj.senderName,
        isMe: obj.isMe,
        msgType: obj.msgType,
        filePath: obj.filePath,
        time: obj.time);
  }
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
      var index = chatList.length - 1 - i;

      if (chatList[index].msgType == "date") {
        continue;
      }
      if (chatList[index].id == id) {
        chatList[index].haveReceived = true;
        return true;
      }
    }
    return false;
  }

  void deleteChat(id) async {
    for (int i = 0; i < chatList.length; i++) {
      var index = chatList.length - 1 - i;
      if (chatList[index].msgType == "date") {
        continue;
      }
      if (chatList[index].id == id) {
        if (chatList[index + 1].msgType == "date" &&
            chatList[index - 1].msgType == "date") {
          chatList.removeAt(index - 1);
        }
        if (chatList[index].msgType == "aud" ||
            chatList[index].msgType == "img") {
          if (File(chatList[index].filePath).existsSync()) {
            File(chatList[index].filePath).deleteSync(recursive: true);
          }
        }
        chatList.removeAt(index);
      }
    }
  }

  bool updateChatSeenStatus(id) {
    for (int i = 0; i < chatList.length; i++) {
      var index = chatList.length - 1 - i;
      if (chatList[index].msgType == "date") {
        continue;
      }
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
      if (chatList[chatList.length - 1 - i].msgType == "date") {
        continue;
      }
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

  @HiveField(10)
  String thumbNailPath;

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
      this.thumbNailPath,
      this.caption});
}

class Comment {
  String username;
  String userdpUrl;
  Map comment;
  bool isMe;

  Comment({this.username, this.userdpUrl, this.comment, this.isMe = false});
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

  deletePost(id) {
    posts.removeWhere((element) => (element.postId == id));
  }

  updatePostStatus(int id, bool status, int commentCount) {
    this.posts.forEach((element) {
      if (element.postId == id) {
        element.commentCount = commentCount;
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

  @HiveField(6)
  int postId;

  @HiveField(7)
  String userDpUrl;

  Notifications(
      {this.type,
      this.userName,
      this.userId,
      this.timeCreated,
      this.notifId,
      this.userDpUrl,
      this.postId});
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

  @HiveField(6)
  List<StoryUser> viewedUsers = <StoryUser>[];

  @HiveField(7)
  List<StoryComment> comments = <StoryComment>[];

  @HiveField(8)
  String caption;

  Story(
      {this.file,
      this.views,
      this.time,
      this.viewed,
      this.storyId,
      this.caption,
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
  String dpUrl;

  UserStoryModel({this.username, this.userId, this.stories, this.dpUrl});

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

  void addView(StoryUser user, int storyId) {
    for (int i = 0; i < stories.length; i++) {
      if (stories[i].storyId == storyId) {
        if (stories[i].viewedUsers == null) {
          stories[i].viewedUsers = [];
        }
        if (!stories[i].viewedUsers.contains(user)) {
          stories[i].viewedUsers.add(user);
          break;
        }
      }
    }
  }

  void addComment(StoryComment comment, int storyId) {
    bool doesNotExist = true;

    for (int i = 0; i < stories.length; i++) {
      if (stories[i].storyId == storyId) {
        if (stories[i].comments == null) {
          stories[i].comments = [];
        }
        for (int j = stories[i].comments.length - 1; j >= 0; j--) {
          if (stories[i].comments[j].commentId == comment.commentId) {
            doesNotExist = false;
            break;
          }
        }
        if (doesNotExist) {
          stories[i].comments.add(comment);
          break;
        }
      }
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

  void deleteOldStory({int id}) {
    for (int i = 0; i < stories.length; i++) {
      if (stories[i].storyId == id) {
        stories.removeAt(i);
      }
    }
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

  @HiveField(4)
  DateTime viewedTime;

  StoryUser({this.username, this.profilePicture, this.viewedTime});
}

@HiveType(typeId: 10)
class StoryComment extends HiveObject {
  @HiveField(0)
  String username;

  @HiveField(1)
  String profilePicture;

  @HiveField(2)
  DateTime viewedTime;

  @HiveField(3)
  String comment;

  @HiveField(4)
  int commentId;

  StoryComment(
      {this.username,
      this.profilePicture,
      this.viewedTime,
      this.comment,
      this.commentId});
}
