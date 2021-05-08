import 'dart:convert';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:foo/chat/chatscreen.dart';
import 'package:foo/screens/feed_icons.dart' as icons;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:hive/hive.dart';
import 'package:ionicons/ionicons.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';
import '../test_cred.dart';

class Profile extends StatelessWidget {
  final int userId;
  List<Post> posts = [];
  String profUserName;
  String curUser;
  String requestStatus;
  bool isMe;
  String userDpUrl;

  Profile({this.userId});

  //Gets the data corresponding to the profile
  Future<List> getData() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    curUser = _prefs.getString("username");
    var response = await http.get(
        Uri.http(localhost, '/api/$userId/profile', {'username': curUser}));
    var respJson = jsonDecode(response.body);
    requestStatus = respJson['requestStatus'];
    profUserName = respJson['username'];
    isMe = respJson['isMe'];
    // userDpUrl = respJson['dp']
    print(userId);
    print(respJson);
    List result = [];
    print(respJson.runtimeType);
    var fullName = respJson['f_name'] + " " + respJson['l_name'];

    result.insert(0, fullName);
    var posts = respJson['posts'];
    List<Post> postList = [];
    print(posts.runtimeType);
    posts.forEach((e) {
      postList.insert(
          0,
          Post(
              username: respJson['username'],
              postUrl: e['url'],
              likeCount: e['likes'],
              postId: e['id']));
    });
    result.insert(1, postList);
    return result;
  }

  //Shows the overlay on long press

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Color.fromRGBO(124, 4, 29, 1),
      body: FutureBuilder(
          future: getData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              List details = snapshot.data;
              if (snapshot.data != null) {
                return ProfileBody(
                    details: details,
                    userName: this.profUserName,
                    userId: this.userId,
                    userDpUrl: "assets/images/user4.png",
                    requestStatus: this.requestStatus,
                    curUser: this.curUser,
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

class PostDetailView extends StatelessWidget {
  final String imageUrl;

  PostDetailView({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            )),
        extendBodyBehindAppBar: true,
        body: InteractiveViewer(
          constrained: false,
          maxScale: 1.5,
          child: CachedNetworkImage(imageUrl: this.imageUrl),
        ));
  }
}

class ProfileBody extends StatefulWidget {
  List details;
  String userName;
  int userId;
  String userDpUrl;
  String requestStatus;
  String curUser;
  bool isMe;

  ProfileBody(
      {Key key,
      this.details,
      this.userName,
      this.userId,
      this.userDpUrl,
      this.requestStatus,
      this.curUser,
      this.isMe})
      : super(key: key);

  @override
  _ProfileBodyState createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<ProfileBody>
    with TickerProviderStateMixin {
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

  Future<void> handleChat() async {
    String threadName = "${widget.curUser}_${widget.userName}";
    var threadBox = Hive.box("Threads");
    Thread thread;
    if (threadBox.containsKey('threadName')) {
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
        );
      }, transitionsBuilder: (context, animation, secAnimation, child) {
        return SlideTransition(
            position: Tween(begin: Offset(1, 0), end: Offset(0, 0))
                .animate(animation),
            child: child);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            height: 420,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 5,
                    offset: Offset(0, 5),
                  ),
                ]),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25)),
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Container(
                      height: 420,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(widget.userDpUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 420,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(25),
                        bottomRight: Radius.circular(25)),
                    color: Colors.black.withOpacity(.2),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back),
                            iconSize: 20.0,
                            color: Colors.black,
                            onPressed: () => Navigator.pop(context),
                          ),
                          IconButton(
                            icon: Icon(icons.Feed.colon),
                            iconSize: 20.0,
                            color: Colors.black,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 10, 10),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "My Profile",
                            style: GoogleFonts.raleway(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              margin: EdgeInsets.all(20),
                              width: 90.0,
                              height: 90.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black45,
                                    offset: Offset(0, 2),
                                    blurRadius: 6.0,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                child: ClipOval(
                                  child: Image(
                                    height: 90.0,
                                    width: 90.0,
                                    image: AssetImage(widget.userDpUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            (!widget.isMe)
                                ? SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * .4,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        (requestStatus == "accepted")
                                            ? Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                        color: Colors.black45,
                                                        blurRadius: 5,
                                                        offset: Offset(2, 3))
                                                  ],
                                                ),
                                                child: CircleAvatar(
                                                  backgroundColor: Colors.white,
                                                  child: IconButton(
                                                    icon: Icon(Ionicons
                                                        .chatbubble_outline),
                                                    onPressed: handleChat,
                                                  ),
                                                ),
                                              )
                                            : Container(),
                                        Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                  color: Colors.black45,
                                                  blurRadius: 5,
                                                  offset: Offset(2, 3))
                                            ],
                                          ),
                                          child: CircleAvatar(
                                            backgroundColor: Colors.white,
                                            child: properStatusButton(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Container(),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 10, 10),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.details[0],
                            style: GoogleFonts.raleway(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 5, 10, 10),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Guildhall school of Music and Drama, London, UK",
                            style: GoogleFonts.raleway(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 19, 10, 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(
                              height: 45,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Photos",
                                    style: GoogleFonts.raleway(
                                      color: Color.fromRGBO(211, 224, 240, 1),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  Text(
                                    '515',
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 45,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Followers",
                                    style: GoogleFonts.raleway(
                                      color: Color.fromRGBO(211, 224, 240, 1),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  Text(
                                    '2515',
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 45,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Follows",
                                    style: GoogleFonts.raleway(
                                      color: Color.fromRGBO(211, 224, 240, 1),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  Text(
                                    '2515',
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            child: GridView.builder(
              padding: EdgeInsets.fromLTRB(5, 25, 5, 5),
              shrinkWrap: true,
              physics: BouncingScrollPhysics(),
              itemCount: widget.details[1].length,
              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.all(5),
                  height: 200,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(.4),
                        offset: Offset(1, 3),
                        blurRadius: 3,
                      )
                    ],
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white,
                  ),
                  child: GestureDetector(
                    onLongPressStart: (press) {
                      return showOverlay(
                          context,
                          "http://" +
                              localhost +
                              widget.details[1][index].postUrl);
                    },
                    onLongPressEnd: (details) {
                      animationController
                          .reverse()
                          .whenComplete(() => overlayEntry.remove());
                    },
                    // child: InkWell(
                    //   onTap: () {
                    //     Navigator.push(
                    //         context,
                    //         MaterialPageRoute(
                    //             builder: (_) => PostDetailView(
                    //                 imageUrl: "http://" +
                    //                     localhost +
                    //                     details[1][index].postUrl)));
                    //   },
                    child: AspectRatio(
                        aspectRatio: 4 / 5,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            image: DecorationImage(
                                image: CachedNetworkImageProvider(
                                  "http://" +
                                      localhost +
                                      widget.details[1][index].postUrl,
                                ),
                                fit: BoxFit.cover),
                          ),
                        )),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
