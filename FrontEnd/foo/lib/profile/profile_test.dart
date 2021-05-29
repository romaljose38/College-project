import 'dart:convert';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:foo/chat/chatscreen.dart';
import 'package:foo/screens/comment_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:ionicons/ionicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models.dart';
import '../test_cred.dart';
import 'dart:math' as math;

class Profile extends StatelessWidget {
  final int userId;
  final bool myProfile;
  List<Post> posts = [];
  String profUserName;
  String curUser;
  String requestStatus;
  bool isMe;
  String userDpUrl;
  String fullName;
  int friendsCount;
  int postsCount;

  Profile({this.userId, this.myProfile = false});

  //Gets the data corresponding to the profile
  Future<List> getData() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    curUser = _prefs.getString("username");
    var response;
    if (myProfile) {
      int myId = _prefs.getInt('id');
      response = await http.get(
          Uri.http(localhost, '/api/$myId/profile', {'username': curUser}));
    } else {
      response = await http.get(
          Uri.http(localhost, '/api/$userId/profile', {'username': curUser}));
    }
    var respJson = jsonDecode(response.body);
    requestStatus = respJson['requestStatus'];
    profUserName = respJson['username'];
    isMe = respJson['isMe'];
    friendsCount = respJson['friends_count'];
    postsCount = respJson['post_count'];
    // userDpUrl = respJson['dp']
    print(userId);
    print(respJson);
    print(respJson.runtimeType);
    var fullName = respJson['f_name'] + " " + respJson['l_name'];
    this.fullName = fullName;
    var posts = respJson['posts'];
    List<Post> postList = [];
    print(posts.runtimeType);
    posts.forEach((e) {
      postList.insert(
          0,
          Post(
              username: respJson['username'],
              postUrl: 'http://' + localhost + e['url'],
              commentCount: e['comments'],
              likeCount: e['likes'],
              postId: e['id']));
    });

    return postList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder(
          future: getData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              List posts = snapshot.data;
              if (snapshot.data != null) {
                return ProfileTest(
                    posts: posts,
                    userName: this.profUserName,
                    userId: this.userId,
                    fullName: this.fullName,
                    userDpUrl: "assets/images/user4.png",
                    requestStatus: this.requestStatus,
                    curUser: this.curUser,
                    friendsCount: this.friendsCount,
                    postsCount: this.postsCount,
                    isMe: this.isMe);
              }
              return Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 1, backgroundColor: Colors.purple));
            }
            return Center(
                child: CircularProgressIndicator(
                    strokeWidth: 1, backgroundColor: Colors.purple));
          }),
    );
  }
}

class ProfileTest extends StatefulWidget {
  List posts;
  String userName;
  int userId;
  String userDpUrl;
  String requestStatus;
  String curUser;
  String fullName;
  bool isMe;
  int friendsCount;
  int postsCount;

  ProfileTest(
      {Key key,
      this.posts,
      this.userName,
      this.userId,
      this.userDpUrl,
      this.friendsCount,
      this.postsCount,
      this.requestStatus,
      this.fullName,
      this.curUser,
      this.isMe})
      : super(key: key);

  @override
  _ProfileTestState createState() => _ProfileTestState();
}

class _ProfileTestState extends State<ProfileTest>
    with SingleTickerProviderStateMixin {
  AnimationController animationController;
  Animation animation;
  OverlayEntry overlayEntry;
  bool hasSentRequest = false;
  String requestStatus;

  @override
  void initState() {
    super.initState();
    // getData();
    requestStatus = widget.requestStatus;
    animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 100));
    animation = Tween<double>(begin: 0, end: 1).animate(animationController);
  }

  String getUrl(String url) => "http://" + localhost + url;

  void showOverlay(BuildContext context, String url) {
    OverlayState overlayState = Overlay.of(context);
    overlayEntry = OverlayEntry(
        builder: (context) => FadeTransition(
              opacity: animation,
              child: Scaffold(
                  backgroundColor: Colors.black.withOpacity(.5),
                  body: Center(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                          alignment: Alignment.center,
                          width: MediaQuery.of(context).size.width * .8,
                          height: MediaQuery.of(context).size.height * .8,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.contain,
                              progressIndicatorBuilder:
                                  (context, string, progress) {
                                return CircularProgressIndicator(
                                  value: progress.progress,
                                  strokeWidth: 1,
                                  backgroundColor: Colors.purple,
                                );
                              },
                            ),
                          )),
                    ),
                  )),
            ));
    animationController.forward();
    overlayState.insert(overlayEntry);
  }

  Future<void> sendFriendRequest() async {
    var resp = await http.get(Uri.http(localhost, '/api/add_friend',
        {'username': widget.curUser, 'id': widget.userId.toString()}));

    if (resp.statusCode == 200) {
      setState(() {
        requestStatus = "pending";
      });
    }
  }

  //renders the relationship button with the appropriate icon
  IconButton properStatusButton() {
    switch (requestStatus) {
      case "pending":
        {
          return IconButton(
              icon: Icon(Icons.more_horiz_outlined), onPressed: () {});
        }
      case "accepted":
        {
          return IconButton(
              icon: Icon(Ionicons.person_outline), onPressed: () {});
        }
      case "rejected":
        {
          return IconButton(
              icon: Icon(Ionicons.person_add_outline),
              onPressed: () {
                print("rejected");
              });
        }
      case "open":
        {
          return IconButton(
              icon: Icon(Ionicons.person_add_outline),
              onPressed: sendFriendRequest);
        }
    }
  }

  IconButton chatIcon() =>
      IconButton(icon: Icon(Ionicons.chatbox_outline), onPressed: handleChat);

  Row properRow() {
    List widgetList;
    if (!widget.isMe) {
      widgetList = [
        properStatusButton(),
        Spacer(),
      ];
      if (requestStatus == "accepted") {
        widgetList.insert(1, chatIcon());
      }
    } else {
      widgetList = [];
    }
    return Row(children: [
      Spacer(),
      Text(
        widget.fullName,
        style: GoogleFonts.raleway(
          fontSize: 23,
          fontWeight: FontWeight.w600,
        ),
      ),
      Spacer(),
      ...widgetList,
    ]);
  }

  Future<void> handleChat() async {
    String threadName = "${widget.curUser}_${widget.userName}";
    var threadBox = Hive.box("Threads");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Thread thread;
    if (threadBox.containsKey(threadName)) {
      thread = threadBox.get(threadName);
    } else {
      thread = Thread(
        first: User(name: widget.curUser),
        second: User(name: widget.userName),
      );
      thread.lastAccessed = DateTime.now();
      await threadBox.put(threadName, thread);
      thread.save();
    }
    Navigator.push(
      context,
      PageRouteBuilder(pageBuilder: (context, animation, secAnimation) {
        return ChatScreen(
          thread: thread,
          prefs: prefs,
        );
      }, transitionsBuilder: (context, animation, secAnimation, child) {
        return SlideTransition(
            position: Tween(begin: Offset(1, 0), end: Offset(0, 0))
                .animate(animation),
            child: child);
      }),
    );
  }

  List<BoxShadow> shadow = [
    BoxShadow(
      blurRadius: 5,
      offset: Offset(0, 4),
      color: Color.fromRGBO(190, 205, 232, 1),
      spreadRadius: 1,
    )
  ];

  SizedBox tripleTier() {
    var height = math.min(540.0, MediaQuery.of(context).size.height * .7);

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
              onLongPressStart: (press) {
                return showOverlay(context, widget.posts[0].postUrl);
              },
              onLongPressEnd: (details) {
                animationController
                    .reverse()
                    .whenComplete(() => overlayEntry.remove());
              },
              onTap: () async {
                var hasDelete = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CommentScreen(
                              isMe: widget.isMe,

                              postUrl: widget.posts[0].postUrl,
                              heroIndex: 0,
                              postId: widget.posts[0].postId,
                              height: height,
                              likeCount: widget.posts[0].likeCount,
                              commentCount: widget.posts[0].commentCount,
                              // ViewPostScreen(post: widget.post, index: widget.index),
                            )));
                if (hasDelete.runtimeType == bool) {
                  if (hasDelete) {
                    widget.posts.removeAt(0);
                  }
                }
              },
              child: Container(
                margin: EdgeInsets.fromLTRB(8, 0, 5, 0),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(15),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(widget.posts[0].postUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    var hasDelete = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CommentScreen(
                                  isMe: widget.isMe,
                                  postUrl: widget.posts[1].postUrl,
                                  heroIndex: 1,
                                  postId: widget.posts[1].postId,
                                  height: height,
                                  likeCount: widget.posts[1].likeCount,
                                  commentCount: widget.posts[1].commentCount,
                                  // ViewPostScreen(post: widget.post, index: widget.index),
                                )));

                    if (hasDelete.runtimeType == bool) {
                      if (hasDelete) {
                        widget.posts.removeAt(1);
                      }
                    }
                  },
                  onLongPressStart: (press) {
                    return showOverlay(context, widget.posts[1].postUrl);
                  },
                  onLongPressEnd: (details) {
                    animationController
                        .reverse()
                        .whenComplete(() => overlayEntry.remove());
                  },
                  child: Container(
                    height: 95,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(15),
                      image: DecorationImage(
                        image:
                            CachedNetworkImageProvider(widget.posts[1].postUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                    margin: EdgeInsets.fromLTRB(3, 0, 8, 5),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    var hasDelete = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CommentScreen(
                                  isMe: widget.isMe,
                                  postUrl: widget.posts[2].postUrl,
                                  heroIndex: 2,
                                  postId: widget.posts[2].postId,
                                  height: height,
                                  likeCount: widget.posts[2].likeCount,
                                  commentCount: widget.posts[2].commentCount,
                                  // ViewPostScreen(post: widget.post, index: widget.index),
                                )));
                    if (hasDelete.runtimeType == bool) {
                      if (hasDelete) {
                        widget.posts.removeAt(2);
                      }
                    }
                  },
                  onLongPressStart: (press) {
                    return showOverlay(context, widget.posts[2].postUrl);
                  },
                  onLongPressEnd: (details) {
                    animationController
                        .reverse()
                        .whenComplete(() => overlayEntry.remove());
                  },
                  child: Container(
                    height: 95,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(15),
                      image: DecorationImage(
                        image:
                            CachedNetworkImageProvider(widget.posts[2].postUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                    margin: EdgeInsets.fromLTRB(3, 5, 8, 0),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  topPortion() {
    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black, size: 20),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          Text(
            "Profile",
            style:
                GoogleFonts.raleway(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Colors.black, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(widget.friendsCount.toString(),
                  style: GoogleFonts.lato(
                      fontSize: 16, fontWeight: FontWeight.w500)),
              Text("Friends",
                  style: GoogleFonts.raleway(
                    fontSize: 14,
                    letterSpacing: 1.2,
                    color: Colors.grey.shade600,
                  )),
            ],
          ),
          Container(
            margin: EdgeInsets.all(10.0),
            width: 70.0,
            height: 70.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.pink.shade400, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black45.withOpacity(.2),
                  offset: Offset(0, 2),
                  spreadRadius: 1,
                  blurRadius: 6.0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(3.0),
              child: Container(
                width: 75,
                height: 70,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    // shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage('assets/images/user4.png'),
                      fit: BoxFit.cover,
                    )),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.postsCount.toString(),
                  style: GoogleFonts.lato(
                      fontSize: 16, fontWeight: FontWeight.w500)),
              Text("Posts",
                  style: GoogleFonts.raleway(
                    fontSize: 14,
                    letterSpacing: 1.2,
                    color: Colors.grey.shade600,
                  )),
            ],
          ),
        ],
      ),
      properRow(),
      SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text(
            "Lord i do not want wealth nor children nor learning. If it be thy will, i shall go from birth to birth; but grant me this, that i may love thee without the hope of reward love unselfishly for love's sake.",
            textAlign: TextAlign.center,
            style: GoogleFonts.raleway(
                fontSize: 13, color: Colors.black.withOpacity(.7))),
      ),
      SizedBox(height: 20),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: topPortion(),
        ),
        ...(widget.posts.length >= 3
            ? [SliverToBoxAdapter(child: tripleTier()), grid(true)]
            : [grid(false)]),
      ],
    );
  }

  Column threeOrMore() => Column(
        children: [
          tripleTier(),
          Expanded(
            child: grid(true),
          ),
        ],
      );
  SliverPadding grid(bool needExtention) {
    var height = math.min(540.0, MediaQuery.of(context).size.height * .7);

    int postCount;
    if (needExtention) {
      postCount = widget.posts.length - 3;
    } else {
      postCount = widget.posts.length;
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              int curIndex;
              if (needExtention) {
                curIndex = index + 3;
              } else {
                curIndex = index;
              }
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 3, vertical: 5),
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.white,
                ),
                child: GestureDetector(
                  onTap: () async {
                    var hasDelete = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CommentScreen(
                                  isMe: widget.isMe,
                                  postUrl: widget.posts[curIndex].postUrl,
                                  heroIndex: curIndex,
                                  postId: widget.posts[curIndex].postId,
                                  height: height,
                                  likeCount: widget.posts[curIndex].likeCount,
                                  commentCount:
                                      widget.posts[curIndex].commentCount,
                                  // ViewPostScreen(post: widget.post, index: widget.index),
                                )));
                    if (hasDelete.runtimeType == bool) {
                      if (hasDelete) {
                        widget.posts.removeAt(1);
                      }
                    }
                  },
                  onLongPressStart: (press) {
                    return showOverlay(context, widget.posts[curIndex].postUrl);
                  },
                  onLongPressEnd: (details) {
                    animationController
                        .reverse()
                        .whenComplete(() => overlayEntry.remove());
                  },
                  child: AspectRatio(
                    aspectRatio: 4 / 5,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        image: DecorationImage(
                            image: CachedNetworkImageProvider(
                              widget.posts[curIndex].postUrl,
                            ),
                            fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              );
            },
            childCount: postCount,
          ),
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3)),
    );
  }
}
