import 'dart:convert';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:foo/chat/chatscreen.dart';
import 'package:foo/custom_overlay.dart';
import 'package:foo/media_players.dart';
import 'package:foo/profile/friends_list.dart';
import 'package:foo/screens/comment_screen.dart';
import 'package:foo/settings/settings_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:ionicons/ionicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:foo/screens/feed_icons.dart' as icons;
import '../models.dart';
import '../test_cred.dart';
import 'dart:math' as math;

class Profile extends StatefulWidget {
  final int userId;
  final bool myProfile;

  Profile({this.userId, this.myProfile = false});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  List<Post> posts = [];

  String profUserName;

  String curUser;

  String requestStatus;

  bool isMe;

  String userDpUrl;

  String fullName;

  int friendsCount;

  int postsCount;

  String about;

  String fName;

  String lName;

  int profileUserId;

  int notifId;

//
  bool hasFetched = false;

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<List> getData() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    curUser = _prefs.getString("username");
    var response;
    try {
      print("hello inside getData");
      if (widget.myProfile) {
        int myId = _prefs.getInt('id');
        response = await http.get(Uri.http(localhost, '/api/$myId/profile',
            {'curUserId': _prefs.getInt('id').toString()}));
      } else {
        response = await http.get(Uri.http(
            localhost,
            '/api/${widget.userId}/profile',
            {'curUserId': _prefs.getInt('id').toString()}));
      }
      var respJson = jsonDecode(utf8.decode(response.bodyBytes));
      print(respJson);
      requestStatus = respJson['requestStatus'];
      notifId = respJson['requestStatus'] == 'pending_acceptance'
          ? respJson['notif_id']
          : -2;
      profUserName = respJson['username'];
      isMe = respJson['isMe'];
      friendsCount = respJson['friends_count'];
      postsCount = respJson['post_count'];
      about = respJson['about'];
      profileUserId = respJson['id'];

      userDpUrl = respJson['dp'];
      print(widget.userId);
      print(respJson);
      print(respJson.runtimeType);
      fName = respJson['f_name'];
      lName = respJson['l_name'];
      var _posts = respJson['posts'];

      _posts.forEach((e) {
        posts.insert(
            0,
            Post(
                type: e['type'],
                username: respJson['username'],
                postUrl: 'http://' + localhost + e['url'],
                commentCount: e['comments'],
                likeCount: e['likes'],
                thumbNailPath: e['thumbnail'] != ""
                    ? 'http://' + localhost + e['thumbnail']
                    : "",
                postId: e['id']));
      });

      setState(() {
        hasFetched = true;
      });
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Something went wrong.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: hasFetched
            ? ProfileTest(
                key: ValueKey(this.notifId),
                posts: posts,
                userName: this.profUserName,
                userId: this.widget.userId,
                fName: this.fName,
                lName: this.lName,
                userDpUrl: this.userDpUrl,
                requestStatus: this.requestStatus,
                curUser: this.curUser,
                about: this.about,
                profileId: this.profileUserId,
                friendsCount: this.friendsCount,
                postsCount: this.postsCount,
                myProfile: this.widget.myProfile,
                notifId: this.notifId,
                isMe: this.isMe)
            : Center(
                child: CircularProgressIndicator(
                    strokeWidth: 1, backgroundColor: Colors.purple)));
  }
}

class ProfileTest extends StatefulWidget {
  List posts;
  String userName;
  int userId;
  String userDpUrl;
  String requestStatus;
  String curUser;
  String fName;
  String lName;
  String about;
  bool isMe;
  int profileId;
  int friendsCount;
  int postsCount;
  bool myProfile;
  int notifId;

  ProfileTest(
      {Key key,
      this.posts,
      this.userName,
      this.userId,
      this.myProfile,
      this.userDpUrl,
      this.about,
      this.notifId,
      this.profileId,
      this.friendsCount,
      this.postsCount,
      this.requestStatus,
      this.fName,
      this.lName,
      this.curUser,
      this.isMe})
      : super(key: key);

  @override
  _ProfileTestState createState() => _ProfileTestState();
}

class _ProfileTestState extends State<ProfileTest>
    with TickerProviderStateMixin {
  AnimationController animationController;
  AnimationController _progressAnimationController;
  AnimationController _customOverlayController;
  Animation _progress;
  Animation animation;
  OverlayEntry overlayEntry;
  bool hasSentRequest = false;
  String requestStatus;
  bool isAbsorbing = false;
  OverlayEntry progressOverlay;

  @override
  void initState() {
    super.initState();
    // getData();
    requestStatus = widget.requestStatus;
    _customOverlayController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 100));
    _progressAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 100));
    _progress =
        Tween<double>(begin: 0, end: 1).animate(_progressAnimationController);
    animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 100));
    animation = Tween<double>(begin: 0, end: 1).animate(animationController);
  }

  String getUrl(String url) => "http://" + localhost + url;
  void showProgressOverlay() {
    OverlayState _state = Overlay.of(context);
    progressOverlay = OverlayEntry(
        builder: (context) => FadeTransition(
            opacity: _progress,
            child: Scaffold(
                backgroundColor: Colors.black.withOpacity(.3),
                body: Center(
                    child: SizedBox(
                        height: 70,
                        width: 70,
                        child: CircularProgressIndicator(
                          strokeWidth: 1,
                          backgroundColor: Colors.white,
                        ))))));

    _progressAnimationController
        .forward()
        .whenComplete(() => _state.insert(progressOverlay));
  }

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
    CustomOverlay overlay = CustomOverlay(
        context: context, animationController: _customOverlayController);
    showProgressOverlay();
    setState(() {
      isAbsorbing = true;
    });
    try {
      var resp = await http.get(Uri.http(localhost, '/api/add_friend',
          {'username': widget.curUser, 'id': widget.userId.toString()}));

      if (resp.statusCode == 200) {
        setState(() {
          requestStatus = "pending";
          isAbsorbing = false;
        });
        _progressAnimationController
            .reverse()
            .whenComplete(() => progressOverlay.remove());
      } else {
        setState(() {
          isAbsorbing = false;
        });
        _progressAnimationController
            .reverse()
            .whenComplete(() => progressOverlay.remove());
      }
    } catch (e) {
      setState(() {
        isAbsorbing = false;
      });
      overlay.show('Something went wrong please try again later');
      _progressAnimationController
          .reverse()
          .whenComplete(() => progressOverlay.remove());
    }
  }

  acceptRequest() async {
    CustomOverlay overlay = CustomOverlay(
        context: context, animationController: _customOverlayController);
    showProgressOverlay();
    setState(() {
      isAbsorbing = true;
    });
    try {
      var resp = await http.get(Uri.http(localhost, '/api/handle_request',
          {'id': widget.notifId.toString(), 'action': "accept"}));
      if (resp.statusCode == 200) {
        Box notifsBox = Hive.box("Notifications");
        Notifications currentNotification = notifsBox.get(widget.notifId);
        currentNotification.hasAccepted = true;
        currentNotification.save();
        widget.requestStatus = "accepted";
        setState(() {
          requestStatus = "accepted";
          isAbsorbing = false;
        });

        _progressAnimationController
            .reverse()
            .whenComplete(() => progressOverlay.remove());
        overlay.show("You are now friends with ${widget.userName}");
      } else {
        setState(() {
          isAbsorbing = false;
        });
        _progressAnimationController
            .reverse()
            .whenComplete(() => progressOverlay.remove());
        overlay.show("Something went wrong please try again later.");
      }
    } catch (e) {
      setState(() {
        isAbsorbing = false;
      });
      _progressAnimationController
          .reverse()
          .whenComplete(() => progressOverlay.remove());
      overlay.show("Something went wrong please try again later.");
    }
  }

  rejectRequest() async {
    showProgressOverlay();
    setState(() {
      isAbsorbing = true;
    });
    CustomOverlay overlay = CustomOverlay(
        context: context, animationController: _customOverlayController);
    try {
      var resp = await http.get(Uri.http(localhost, '/api/handle_request',
          {'id': widget.notifId.toString(), 'action': "reject"}));
      if (resp.statusCode == 200) {
        Box notifsBox = Hive.box("Notifications");
        Notifications currentNotification = notifsBox.get(widget.notifId);
        widget.requestStatus = "rejected";
        setState(() {
          requestStatus = "open";
          isAbsorbing = false;
        });
        currentNotification.hasAccepted = false;
        currentNotification.save();
        _progressAnimationController
            .reverse()
            .whenComplete(() => progressOverlay.remove());
      } else {
        setState(() {
          isAbsorbing = false;
        });
        _progressAnimationController
            .reverse()
            .whenComplete(() => progressOverlay.remove());
        overlay.show("Something went wrong please try again later.");
      }
    } catch (e) {
      setState(() {
        isAbsorbing = false;
      });
      _progressAnimationController
          .reverse()
          .whenComplete(() => progressOverlay.remove());
      overlay.show("Something went wrong please try again later.");
    }
  }

  //renders the relationship button with the appropriate icon
  List<Widget> properStatusButton() {
    switch (requestStatus) {
      case "pending":
        {
          return [
            IconButton(icon: Icon(Icons.more_horiz_outlined), onPressed: () {})
          ];
        }
      case "accepted":
        {
          return [
            IconButton(icon: Icon(Ionicons.person_outline), onPressed: () {})
          ];
        }
      case "pending_acceptance":
        {
          return [
            IconButton(icon: Icon(Icons.clear), onPressed: rejectRequest),
            IconButton(icon: Icon(Icons.check), onPressed: acceptRequest)
          ];
        }
      case "rejected":
        {
          return [
            IconButton(
                icon: Icon(Ionicons.person_add_outline),
                onPressed: () {
                  print("rejected");
                })
          ];
        }
      case "open":
        {
          return [
            IconButton(
                icon: Icon(Ionicons.person_add_outline),
                onPressed: sendFriendRequest)
          ];
        }
    }
  }

  IconButton chatIcon() =>
      IconButton(icon: Icon(Ionicons.chatbox_outline), onPressed: handleChat);

  Row properRow() {
    List widgetList;
    if (!widget.isMe) {
      widgetList = [
        ...properStatusButton(),
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
        widget.fName + " " + widget.lName,
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
    String threadName = "${widget.curUser}-${widget.userName}";
    var threadBox = Hive.box("Threads");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Thread thread;
    if (threadBox.containsKey(threadName)) {
      thread = threadBox.get(threadName);
    } else {
      thread = Thread(
        first: User(name: widget.curUser),
        second: User(
            name: widget.userName,
            dpUrl: widget.userDpUrl,
            f_name: widget.fName,
            l_name: widget.lName,
            userId: widget.profileId),
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
    Post post0 = widget.posts[0];
    Post post1 = widget.posts[1];
    Post post2 = widget.posts[2];
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
              onLongPressStart: post0.type == "img"
                  ? (press) {
                      return showOverlay(context, post0.postUrl);
                    }
                  : null,
              onLongPressEnd: post0.type == "img"
                  ? (details) {
                      animationController
                          .reverse()
                          .whenComplete(() => overlayEntry.remove());
                    }
                  : null,
              onTap: () async {
                var hasDelete = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CommentScreen(
                              isMe: widget.isMe,

                              heroIndex: 0,
                              postId: post0.postId,

                              // ViewPostScreen(post: widget.post, index: widget.index),
                            )));
                if (hasDelete.runtimeType == bool) {
                  if (hasDelete) {
                    widget.posts.removeAt(0);
                  }
                }
              },
              child: post0.type == "img"
                  ? postImg(post0, isFirst: true)
                  : (post0.type == "aud")
                      ? postAudio(post0, isFirst: true)
                      : (post0.type == "aud_blurred")
                          ? postAudioBlurred(post0, isFirst: true)
                          : postVideo(post0, isFirst: true),
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

                                  heroIndex: 1,
                                  postId: post1.postId,

                                  // ViewPostScreen(post: widget.post, index: widget.index),
                                )));

                    if (hasDelete.runtimeType == bool) {
                      if (hasDelete) {
                        widget.posts.removeAt(1);
                      }
                    }
                  },
                  onLongPressStart: post1.type == "img"
                      ? (press) {
                          return showOverlay(context, post1.postUrl);
                        }
                      : null,
                  onLongPressEnd: post1.type == "img"
                      ? (details) {
                          animationController
                              .reverse()
                              .whenComplete(() => overlayEntry.remove());
                        }
                      : null,
                  child: Container(
                      height: 100,
                      child: post1.type == "img"
                          ? postImg(post1, isMinor: true)
                          : (post1.type == "aud")
                              ? postAudio(post1, isMinor: true)
                              : (post1.type == "aud_blurred")
                                  ? postAudioBlurred(post1, isMinor: true)
                                  : postVideo(post1, isMinor: true)),
                ),
                GestureDetector(
                  onTap: () async {
                    var hasDelete = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CommentScreen(
                                  isMe: widget.isMe,

                                  heroIndex: 2,
                                  postId: post2.postId,

                                  // ViewPostScreen(post: widget.post, index: widget.index),
                                )));
                    if (hasDelete.runtimeType == bool) {
                      if (hasDelete) {
                        widget.posts.removeAt(2);
                      }
                    }
                  },
                  onLongPressStart: post2.type == "img"
                      ? (press) {
                          return showOverlay(context, post2.postUrl);
                        }
                      : null,
                  onLongPressEnd: post2.type == "img"
                      ? (details) {
                          animationController
                              .reverse()
                              .whenComplete(() => overlayEntry.remove());
                        }
                      : null,
                  child: Container(
                    child: SizedBox(
                        height: 100,
                        child: post2.type == "img"
                            ? postImg(post2, isMinor: true)
                            : (post2.type == "aud")
                                ? postAudio(post2, isMinor: true)
                                : (post2.type == "aud_blurred")
                                    ? postAudioBlurred(post2, isMinor: true)
                                    : postVideo(post2, isMinor: true)),
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
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back,
                  color: widget.myProfile ? Colors.white : Colors.black,
                  size: 20),
              onPressed: widget.myProfile
                  ? null
                  : () {
                      Navigator.pop(context, requestStatus);
                    },
            ),
            Text(
              "Profile",
              style: GoogleFonts.raleway(
                  fontWeight: FontWeight.w700, fontSize: 18),
            ),
            IconButton(
              icon: Icon(icons.Feed.colon, color: Colors.black, size: 20),
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                      pageBuilder: (contxt, animation, secAnimation) {
                    return Settings();
                  }, transitionsBuilder: (ctx, animation, secAnimation, child) {
                    return SlideTransition(
                      position:
                          Tween<Offset>(begin: Offset(1, 0), end: Offset(0, 0))
                              .animate(animation),
                      child: child,
                    );
                  }),
                );
              },
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                print(widget.profileId);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => FriendsListScreen(
                          userId: widget.profileId,
                        )));
              },
              child: Column(
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
            ),
            Container(
              margin: EdgeInsets.all(10.0),
              width: 70.0,
              height: 70.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.pink.shade400, width: 1),
                // boxShadow: [
                //   BoxShadow(
                //     color: Colors.black45.withOpacity(.2),
                //     offset: Offset(0, 2),
                //     spreadRadius: 1,
                //     blurRadius: 6.0,
                //   ),
                // ],
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
                        image: CachedNetworkImageProvider(
                            getUrl(widget.userDpUrl)),
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
          child: Text(widget.about,
              textAlign: TextAlign.center,
              style: GoogleFonts.raleway(
                  fontSize: 13, color: Colors.black.withOpacity(.7))),
        ),
        SizedBox(height: 20),
      ]),
    );
  }

  settingsWidget() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(Icons.exit_to_app_rounded,
                  color: Colors.black, size: 20),
              onPressed: () {},
            ),
          ],
        ),
        SizedBox(height: 40),
        TextButton(child: Text("Settings"), onPressed: () {})
      ]);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () {
        Navigator.pop(context, requestStatus);
        return Future.value(false);
      },
      child: AbsorbPointer(
        absorbing: isAbsorbing,
        child: Container(
          height: size.height,
          width: size.width,
          decoration: BoxDecoration(color: Colors.white, boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.2),
              spreadRadius: .5,
              blurRadius: 20,
              offset: Offset(-3, 0),
            )
          ]),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: topPortion(),
              ),
              ...(widget.posts.length >= 3
                  ? [SliverToBoxAdapter(child: tripleTier()), grid(true)]
                  : [grid(false)]),
            ],
          ),
        ),
      ),
    );
  }

  Container postImg(post, {bool isFirst = false, bool isMinor = false}) =>
      Container(
        margin: isFirst
            ? EdgeInsets.fromLTRB(8, 0, 5, 0)
            : isMinor
                ? EdgeInsets.fromLTRB(3, 0, 8, 5)
                : EdgeInsets.zero,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          image: DecorationImage(
              image: CachedNetworkImageProvider(
                post.postUrl,
              ),
              fit: BoxFit.cover),
        ),
      );

  Widget postVideo(Post post, {bool isFirst = false, bool isMinor = false}) {
    Widget child = Center(
      child: Icon(Ionicons.play_circle, size: 45, color: Colors.white),
    );
    Widget container(child) => Container(
        margin: isFirst
            ? EdgeInsets.fromLTRB(8, 0, 5, 0)
            : isMinor
                ? EdgeInsets.fromLTRB(3, 0, 8, 5)
                : EdgeInsets.zero,
        decoration: BoxDecoration(
          // boxShadow: [BoxShadow()],
          borderRadius: BorderRadius.circular(15),
          image: DecorationImage(
            image: CachedNetworkImageProvider(post.thumbNailPath),
            // image: CachedNetworkImageProvider(widget.post.postUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: child);

    if (isFirst) {
      return container(child);
    } else {
      child = Container();
      return Stack(children: [
        container(child),
        Positioned.fill(
            child: Container(
                margin:
                    isMinor ? EdgeInsets.fromLTRB(3, 0, 8, 5) : EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.4),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                    child: Icon(Ionicons.videocam,
                        color: Colors.white, size: 16))))
      ]);
    }
  }

  Widget postAudio(Post post, {bool isFirst = false, bool isMinor = false}) {
    Widget child = Center(
      child: Player(url: post.postUrl),
    );
    Widget container(child) => Container(
        margin: isFirst
            ? EdgeInsets.fromLTRB(8, 0, 5, 0)
            : isMinor
                ? EdgeInsets.fromLTRB(3, 0, 8, 5)
                : EdgeInsets.zero,
        decoration: (post.thumbNailPath != "")
            ? BoxDecoration(
                // boxShadow: [BoxShadow()],
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(post.thumbNailPath),
                  // image: CachedNetworkImageProvider(widget.post.postUrl),
                  fit: BoxFit.cover,
                ),
              )
            : BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(15),
              ),
        child: child);

    if (isFirst) {
      return container(child);
    } else {
      child = Container();
      return Stack(children: [
        container(child),
        Positioned.fill(
            child: Container(
                margin:
                    isMinor ? EdgeInsets.fromLTRB(3, 0, 8, 5) : EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.4),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                    child: Icon(Ionicons.headset_outline,
                        color: Colors.white, size: 16))))
      ]);
    }
  }

  Widget postAudioBlurred(Post post,
      {bool isFirst = false, bool isMinor = false}) {
    Widget child = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Center(child: Player(url: post.postUrl)));
    Widget container(child) => Container(
          margin: isFirst
              ? EdgeInsets.fromLTRB(8, 0, 5, 0)
              : isMinor
                  ? EdgeInsets.fromLTRB(3, 0, 8, 5)
                  : EdgeInsets.zero,
          decoration: BoxDecoration(
            // boxShadow: [BoxShadow()],
            borderRadius: BorderRadius.circular(15),
            image: DecorationImage(
              image: CachedNetworkImageProvider(post.thumbNailPath),
              // image: CachedNetworkImageProvider(widget.post.postUrl),
              fit: BoxFit.cover,
            ),
          ),
          child:
              ClipRRect(borderRadius: BorderRadius.circular(15), child: child),
        );

    if (isFirst) {
      return container(child);
    } else {
      child = Container();
      return Stack(children: [
        container(child),
        Positioned.fill(
            child: Container(
                margin:
                    isMinor ? EdgeInsets.fromLTRB(3, 0, 8, 5) : EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.4),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: Center(
                        child: Icon(Ionicons.headset_outline,
                            color: Colors.white, size: 16)),
                  ),
                )))
      ]);
    }
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
              var post = widget.posts[curIndex];
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
                                  heroIndex: curIndex,
                                  postId: post.postId,

                                  // ViewPostScreen(post: widget.post, index: widget.index),
                                )));
                    if (hasDelete.runtimeType == bool) {
                      if (hasDelete) {
                        widget.posts.removeAt(curIndex);
                      }
                    }
                  },
                  onLongPressStart: post.type == "img"
                      ? (press) {
                          return showOverlay(context, post.postUrl);
                        }
                      : null,
                  onLongPressEnd: post.type == "img"
                      ? (details) {
                          animationController
                              .reverse()
                              .whenComplete(() => overlayEntry.remove());
                        }
                      : null,
                  child: AspectRatio(
                    aspectRatio: 4 / 5,
                    child: post.type == "img"
                        ? postImg(post)
                        : (post.type == "aud")
                            ? postAudio(post)
                            : (post.type == "aud_blurred")
                                ? postAudioBlurred(post)
                                : postVideo(post),
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
