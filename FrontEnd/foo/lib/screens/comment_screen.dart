import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:foo/custom_overlay.dart';
import 'package:foo/models.dart';
import 'package:foo/profile/profile_test.dart';
import 'package:foo/screens/feed_icons.dart' as icons;
import 'package:foo/media_players.dart';
import 'package:foo/screens/search_screen.dart';
import 'package:foo/search_bar/flappy_search_bar.dart';
import 'package:foo/search_bar/search_bar_style.dart';
import 'package:foo/test_cred.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:ionicons/ionicons.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../colour_palette.dart';
import 'dart:math' as math;

class CommentScreen extends StatefulWidget {
  final int postId;
  final int heroIndex;
  final bool isMe;

  CommentScreen({
    this.postId,
    this.heroIndex,
    this.isMe = false,
  });

  @override
  _CommentScreenState createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen>
    with TickerProviderStateMixin {
  TextEditingController _commentController = TextEditingController();
  bool hasCommentExpanded = false;
  bool hasTextExpanded = false;
  bool hasFetched = false;
  List<CommentTile> commentsList = <CommentTile>[];
  FocusNode textFocus = FocusNode();

  //
  SharedPreferences prefs;
  //

  //
  List mentionList = [];
  bool overlayVisible = false;
  FocusNode mentionFocus = FocusNode();
  Animation animation;
  OverlayEntry overlayEntry;
  AnimationController animationController;
  int start = 0, end = 0;

  //
  String caption;
  int commentCount;
  int likeCount;
  bool hasLiked;
  String postUrl;
  String postType;
  String thumbnailPath;
  String userName;
  String userDp;
  int userId;
  String myDpPath;

  //

  @override
  void initState() {
    super.initState();
    _getComments();

    //
    _loveAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    _loveAnimation =
        Tween<double>(begin: 0, end: 1).animate(_loveAnimationController);

    //
    animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 100));
    animation = Tween<double>(begin: 0, end: 1).animate(animationController);

    setPrefs();
    // detectHeight();
  }

  setPrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> _getComments() async {
    var prefs = await SharedPreferences.getInstance();
    var curId = prefs.getInt('id');
    var dir = await getApplicationDocumentsDirectory();

    var response = await http.get(Uri.http(localhost,
        '/api/${widget.postId}/post_detail', {'id': curId.toString()}));
    if (response.statusCode == 200) {
      var respJson = jsonDecode(utf8.decode(response.bodyBytes));
      print(respJson);
      setState(() {
        myDpPath = dir.path + '/images/dp/dp.jpg';
        userDp = 'http://' + localhost + respJson['dp'];
        userName = respJson['username'];
        userId = respJson['user_id'];
        commentCount = respJson['comment_set'].length;
        likeCount = respJson['likeCount'];
        caption = respJson['caption'];
        hasLiked = respJson['hasLiked'];
        postType = respJson['post_type'];
        thumbnailPath = (respJson['post_type'] != 'img')
            ? 'http://' + localhost + respJson['thumbnail']
            : '';
        postUrl = 'http://' + localhost + respJson['file'];
      });
      respJson['comment_set'].forEach((e) {
        print("MYE = $e");
        var comment = jsonDecode(e['comment']);

        setState(() {
          commentsList.insert(
              0,
              CommentTile(
                  comment: Comment(
                      comment: comment,
                      userdpUrl: 'http://' + localhost + e['dp'],
                      username: e['user'])));
        });
      });
    }
    setState(() {
      hasFetched = true;
    });
  }

  resizeContainer() {
    print("resizeContainer");
    setState(() {
      hasCommentExpanded = !hasCommentExpanded;
    });
  }

  Future<void> _addComment() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    String username = _prefs.getString("username");
    String comment = _commentController.text;
    List commentSplit = comment.split(' ');
    List finalMentionList = [];
    Map mapToSend = {};
    print(commentSplit);
    commentSplit.forEach((element) {
      if (element != "") {
        if (element[0] == "@") {
          String stringToCheck = element.substring(1, element.length);
          mapToSend[element] = true;
          if (mentionList.contains(stringToCheck)) {
            finalMentionList.add(stringToCheck);
          }
        } else {
          mapToSend[element] = false;
        }
      }
    });
    print(mapToSend);
    print(finalMentionList);
    var response =
        await http.post(Uri.http(localhost, '/api/$username/add_comment'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode({
              'comment': mapToSend,
              'post': widget.postId,
              'mentions': finalMentionList,
            }));

    _commentController.text = "";
    if (response.statusCode == 200) {
      updatePostInHive(widget.postId, hasLiked);
      var dir = await getApplicationDocumentsDirectory();
      setState(() {
        commentsList.insert(
            0,
            CommentTile(
                comment: Comment(
                    comment: mapToSend,
                    isMe: true,
                    userdpUrl: dir.path + '/images/dp/dp.jpg',
                    username: username)));
      });
      commentCount += 1;
    }
  }

  Future<List<UserTest>> search(String search) async {
    print(search);
    var resp =
        await http.get(Uri.http(localhost, '/api/users', {'name': search}));
    var respJson = jsonDecode(resp.body);
    print(respJson);

    List<UserTest> returList = [];
    respJson.forEach((e) {
      print(e);
      returList.add(UserTest(
          name: e["username"],
          id: e['id'],
          dp: 'http://' + localhost + e['dp'],
          fname: e['f_name'],
          lname: e['l_name']));
    });
    return returList;
  }

  showOverlay(BuildContext context) {
    OverlayState overlayState = Overlay.of(context);
    overlayEntry = OverlayEntry(
      builder: (context) => Scaffold(
        backgroundColor: Colors.black.withOpacity(.3),
        body: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * .9,
            height: MediaQuery.of(context).size.height * .7,
            // clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: FadeTransition(
              opacity: animation,
              child: GestureDetector(
                onTap: () {
                  animationController.reverse().whenComplete(() {
                    overlayEntry.remove();
                    mentionFocus.unfocus();
                    textFocus.requestFocus();
                  });
                },
                child: SearchBar<UserTest>(
                  onCancelled: () {},
                  focusNode: mentionFocus,
                  minimumChars: 1,
                  searchBarPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  searchBarStyle:
                      SearchBarStyle(borderRadius: BorderRadius.circular(8)),
                  onSearch: search,
                  onError: (err) {
                    print(err);
                    return Container();
                  },
                  onItemFound: (UserTest user, int index) {
                    return GestureDetector(
                      onTap: () {
                        print("$start, $end");
                        _commentController.text =
                            insertAtChangedPoint('@${user.name}', start, end);
                        print(user.name);
                        mentionList.add(user.name);
                      },
                      child: MentionSearchTile(user: user),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    animationController.forward().whenComplete(() {
      overlayState.insert(overlayEntry);
      overlayVisible = true;
      textFocus.unfocus();
      mentionFocus.requestFocus();
    });
  }

  Future<void> deletePost() async {
    try {
      print("trying");
      var resp = await http.get(Uri.http(
          localhost, "/api/delete_post", {"id": widget.postId.toString()}));
      if (resp.statusCode == 200) {
        var feedBox = Hive.box("Feed");
        var feed = feedBox.get("feed");
        feed.deletePost(widget.postId);
        feed.save();
        Navigator.pop(context, true);
      }
    } catch (e) {
      print(e);
    }
  }

  //

  bool hasTapped = false;
  AnimationController _loveAnimationController;
  Animation _loveAnimation;

//
  Future<void> likePost() async {
    print(hasLiked);
    print(likeCount);

    if (hasLiked) {
      var response = await http.get(Uri.http(localhost, 'api/remove_like', {
        'username': prefs.getString("username"),
        'id': widget.postId.toString(),
      }));
      if (response.statusCode == 200) {
        setState(() {
          hasLiked = false;
          likeCount -= 1;
        });
      }
      updatePostInHive(widget.postId, false);
    } else {
      var response = await http.get(Uri.http(localhost, '/api/add_like', {
        'username': prefs.getString("username"),
        'id': widget.postId.toString(),
      }));
      if (response.statusCode == 200) {
        setState(() {
          hasLiked = true;
          likeCount += 1;
        });
      }

      updatePostInHive(widget.postId, true);
    }
    setState(() {
      hasTapped = true;
    });
    _loveAnimationController.forward().whenComplete(
          () => Future.delayed(Duration(milliseconds: 800), () {
            _loveAnimationController.reverse().whenComplete(() {
              setState(() {
                hasTapped = false;
              });
            });
          }),
        );
  }

  void updatePostInHive(int id, bool status) {
    var feedBox = Hive.box("Feed");
    Feed feed = feedBox.get('feed');
    if ((id <= feed.posts.first.postId) & (id >= feed.posts.last.postId)) {
      feed.updatePostStatus(id, status, commentCount);
      feed.save();
    }
  }

  //
  String insertAtChangedPoint(String word, int start, int end) {
    String text = _commentController.text;
    String newText = text.replaceRange(start, end, word);
    print(newText);
    return newText;
  }

  Container _commentField() => Container(
        width: MediaQuery.of(context).size.width,
        height: 71,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(15, 12, 15, 10),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Color.fromRGBO(226, 235, 243, .7),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  margin: EdgeInsets.only(left: 5),
                  // padding: EdgeInsets.only(left: 10),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      image: DecorationImage(
                        image: FileImage(File(myDpPath ?? "")),
                        fit: BoxFit.cover,
                      )),
                ),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    cursorColor: Colors.black,
                    decoration: InputDecoration(
                      hintText: "Add a comment",
                      hintStyle: GoogleFonts.raleway(fontSize: 12),
                      contentPadding: EdgeInsets.fromLTRB(10, 5, 5, 15),
                      focusedBorder: InputBorder.none,
                      border: InputBorder.none,
                      suffix: InkWell(
                        child: Text("@",
                            style:
                                TextStyle(color: Colors.black, fontSize: 25)),
                        onTap: () {
                          var cursor = _commentController.selection;
                          start = cursor.start;
                          end = cursor.end;
                          showOverlay(context);
                        },
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(5),
                  // decoration: BoxDecoration(
                  //   color: Colors.white,
                  //   shape: BoxShape.circle,
                  // ),
                  child: IconButton(
                      icon: Icon(Ionicons.send, size: 16),
                      onPressed: _addComment),
                ),
              ],
            ),
          ),
        ),
      );

  Future<bool> _onWillPop() async {
    print("nope you r not goin");
    if (overlayVisible ?? false) {
      animationController.reverse().whenComplete(() {
        overlayEntry.remove();
        mentionFocus.unfocus();
        textFocus.requestFocus();
      });
      overlayVisible = false;
      return Future.value(false);
    }
    Navigator.pop(context, {
      "likeCount": likeCount,
      "commentCount": commentCount,
      'hasLiked': hasLiked
    });
    return Future.value(false);
  }

  postImage(height) => Container(
        height: height,
        width: double.infinity,
        // margin: EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: CachedNetworkImageProvider(postUrl),
            fit: BoxFit.cover,
          ),
        ),
      );
  Container postAudio(height) => Container(
      height: height,
      width: double.infinity,
      decoration: (thumbnailPath != '')
          ? BoxDecoration(
              // boxShadow: [BoxShadow()],
              // borderRadius: BorderRadius.circular(25),
              image: DecorationImage(
                image: CachedNetworkImageProvider(thumbnailPath),
                // image: CachedNetworkImageProvider(widget.post.postUrl),
                fit: BoxFit.cover,
              ),
            )
          : BoxDecoration(
              color: Colors.black,
            ),
      child: Center(
        child: Player(url: postUrl),
      ));

  Container postAudioBlurred(height) => Container(
      height: height,
      width: double.infinity,
      decoration: (thumbnailPath != '')
          ? BoxDecoration(
              image: DecorationImage(
                image: CachedNetworkImageProvider(thumbnailPath),
                // image: CachedNetworkImageProvider(widget.post.postUrl),
                fit: BoxFit.cover,
              ),
            )
          : BoxDecoration(color: Colors.black),
      child: Center(
          child: BackdropFilter(
        child: Player(url: postUrl),
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      )));

  Container postVideo(height) => Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        // boxShadow: [BoxShadow()],
        // borderRadius: BorderRadius.circular(25),
        image: DecorationImage(
          image: CachedNetworkImageProvider(thumbnailPath),
          // image: CachedNetworkImageProvider(widget.post.postUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              PageRouteBuilder(
                  pageBuilder: (context, animation, secAnimation) =>
                      VideoPlayerProvider(videoUrl: postUrl),
                  transitionsBuilder:
                      (context, animation, secAnimation, child) {
                    return SlideTransition(
                      position:
                          Tween<Offset>(begin: Offset(1, 0), end: Offset(0, 0))
                              .animate(animation),
                      child: child,
                    );
                  }));
        },
        child: Center(
          child: Icon(Ionicons.play_circle, size: 45, color: Colors.white),
        ),
      ));

  @override
  Widget build(BuildContext context) {
    var height = math.min(540.0, MediaQuery.of(context).size.height * .7);
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
            preferredSize: Size(double.infinity, 50),
            child: Container(
                color: Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_rounded, size: 16),
                      onPressed: () {
                        Navigator.pop(context, 4);
                      },
                    ),
                    widget.isMe
                        ? IconButton(
                            icon: Icon(icons.Feed.colon, size: 20),
                            onPressed: () async {
                              var shouldDelete = false;
                              await showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text(
                                          "Are you sure you want to delete this post?"),
                                      actions: [
                                        TextButton(
                                          child: Text("Yes"),
                                          onPressed: () {
                                            shouldDelete = true;
                                            Navigator.pop(context);
                                          },
                                        ),
                                        TextButton(
                                          child: Text("No"),
                                          onPressed: () {
                                            shouldDelete = false;
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ],
                                    );
                                  });
                              if (shouldDelete) {
                                await deletePost();
                              }
                            },
                          )
                        : Container(),
                  ],
                ))),
        backgroundColor: Colors.white,
        body: Container(
          height: MediaQuery.of(context).size.height - 50,
          width: MediaQuery.of(context).size.width,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Hero(
                  tag: "profile_${widget.heroIndex}",
                  child: GestureDetector(
                    onDoubleTap: likePost,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: postType == "img"
                          ? postImage(height)
                          : (postType == "aud")
                              ? postAudio(height)
                              : (postType == "vid")
                                  ? postVideo(height)
                                  : postAudioBlurred(height),
                    ),
                  )),
              //
              Positioned(
                top: 0,
                child: hasTapped
                    ? ScaleTransition(
                        scale: _loveAnimation,
                        child: Container(
                          height: height,
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            // color: Colors.black.withOpacity(.4),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Icon(Ionicons.heart,
                                size: 60, color: Colors.white),
                          ),
                        ),
                      )
                    : Container(),
              ),

              //

              Positioned(
                top: 10,
                left: 10,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Profile(userId: 5),
                          ),
                        );
                      },
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              PageRouteBuilder(
                                  pageBuilder:
                                      (context, animation, secAnimation) =>
                                          Profile(userId: userId),
                                  transitionsBuilder: (context, animation,
                                      secAnimation, child) {
                                    return SlideTransition(
                                      position: Tween<Offset>(
                                              begin: Offset(1, 0),
                                              end: Offset(0, 0))
                                          .animate(animation),
                                      child: child,
                                    );
                                  }));
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            image: DecorationImage(
                              image: CachedNetworkImageProvider(userDp ?? ""),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                      // color: Colors.black.withOpacity(.3),
                      decoration: BoxDecoration(
                          // color: Colors.black.withOpacity(.3),
                          // borderRadius: BorderRadius.circular(20),
                          ),
                      child: Text(
                        userName ?? "",
                        style: GoogleFonts.raleway(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedPositioned(
                duration: Duration(milliseconds: 100),
                height: 200,
                top: height - (hasTextExpanded ? 120 : 90),
                left: 0,
                child: Container(
                  width: MediaQuery.of(context).size.width - 10,
                  padding: EdgeInsets.fromLTRB(20, 0, 0, 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                    // color: Colors.black.withOpacity(.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        GestureDetector(
                          onTap: likePost,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              constraints: BoxConstraints(maxWidth: 69),
                              color: (hasLiked ?? false)
                                  ? Colors.red.shade700
                                  : Colors.transparent,
                              height: 37,
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                    sigmaX: (hasLiked ?? false) ? 0 : 15,
                                    sigmaY: (hasLiked ?? false) ? 0 : 15),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(Ionicons.heart,
                                        color: Colors.white, size: 22),
                                    SizedBox(width: 5),
                                    // SizedBox(width: 25),
                                    Text(
                                      ((likeCount != null) && (likeCount != 0))
                                          ? likeCount.toString()
                                          : "",
                                      style: TextStyle(
                                        fontSize: 11.0,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          // width: 75,
                          height: 45,
                          decoration: BoxDecoration(
                            // color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              IconButton(
                                icon:
                                    Icon(Ionicons.chatbox, color: Colors.white),
                                iconSize: 22.0,
                                onPressed: () {},
                              ),
                              Text(
                                ((commentCount != null) && (commentCount != 0))
                                    ? commentCount.toString()
                                    : "",
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]),
                      Container(
                        // decoration: BoxDecoration(
                        //   color: Colors.black.withOpacity(.3),
                        //   borderRadius: BorderRadius.circular(15),
                        // ),
                        // height: 30,
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: hasTextExpanded
                                    ? () => setState(() {
                                          hasTextExpanded = false;
                                        })
                                    : () {},
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: new AnimatedContainer(
                                      duration: Duration(milliseconds: 200),
                                      padding: hasTextExpanded
                                          ? EdgeInsets.all(5)
                                          : EdgeInsets.symmetric(horizontal: 5),
                                      constraints: hasTextExpanded
                                          ? new BoxConstraints(maxHeight: 58)
                                          : new BoxConstraints(
                                              maxHeight: 20.0,
                                            ),
                                      decoration: BoxDecoration(
                                        color: hasTextExpanded
                                            ? Colors.black.withOpacity(.2)
                                            : Colors.transparent,
                                      ),
                                      child: BackdropFilter(
                                        filter: hasTextExpanded
                                            ? ImageFilter.blur(
                                                sigmaX: 15, sigmaY: 15)
                                            : ImageFilter.blur(
                                                sigmaX: 0, sigmaY: 0),
                                        child: new Text(
                                          caption ?? "",
                                          softWrap: true,
                                          style: TextStyle(color: Colors.white),
                                          overflow: hasTextExpanded
                                              ? TextOverflow.visible
                                              : TextOverflow.ellipsis,
                                        ),
                                      )),
                                ),
                              ),
                              // child: ExpandableText(
                              //   "It is good to love god for the sake of loving, but it is more important to liv ",
                              // ),
                            ),
                            !hasTextExpanded
                                ? GestureDetector(
                                    onTap: () {
                                      setState(() =>
                                          hasTextExpanded = !hasTextExpanded);
                                    },
                                    child: Container(
                                      height: 30,
                                      width: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text("More",
                                          style: GoogleFonts.lato(
                                            color: Colors.black,
                                            fontSize: 11,
                                          )),
                                    ),
                                  )
                                : Container(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              AnimatedPositioned(
                duration: Duration(milliseconds: 200),
                top: hasCommentExpanded ? 34 : height,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  height: MediaQuery.of(context).size.height * .9,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Color.fromRGBO(226, 235, 243, 1)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius:
                        BorderRadius.circular(hasCommentExpanded ? 30 : 0),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      hasFetched
                          ? GestureDetector(
                              onTap: resizeContainer,
                              child: Container(
                                height: 20,
                                color: Colors.transparent,
                                margin: EdgeInsets.only(bottom: 5),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: Icon(hasCommentExpanded
                                          ? Icons.arrow_drop_down_rounded
                                          : Icons.arrow_drop_up_rounded),
                                      onPressed: resizeContainer,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Container(),
                      Expanded(
                        child: SingleChildScrollView(
                          child: hasFetched
                              ? Column(
                                  children: commentsList,
                                )
                              : Container(
                                  alignment: Alignment.center,
                                  margin: EdgeInsets.only(top: 20),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1,
                                    backgroundColor: Colors.purple,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // }),
              Positioned(bottom: 0, child: _commentField()),
            ],
          ),
        ),
      ),
    );
  }
}

class CommentTile extends StatelessWidget {
  final Comment comment;
  CommentTile({this.comment});

  List<TextSpan> customizeComment(Map comments) {
    List<TextSpan> children = [];
    comments.forEach((key, val) {
      if (val) {
        children.add(TextSpan(
          text: '$key ',
          style: TextStyle(color: Colors.yellow),
        ));
      } else {
        children.add(TextSpan(
          text: '$key ',
          // style: TextStyle(color: Colors.yellow),
        ));
      }
    });
    return children;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: ListTile(
        // tileColor: Colors.green,
        leading: Container(
          width: 41.0,
          height: 41.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            // boxShadow: [
            //   BoxShadow(
            //     color: Colors.black45,
            //     offset: Offset(0, 2),
            //     blurRadius: 6.0,
            //   ),
            // ],
            image: DecorationImage(
              image: comment.isMe
                  ? FileImage(File(comment.userdpUrl))
                  : CachedNetworkImageProvider(comment.userdpUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(
          comment.username,
          style: GoogleFonts.raleway(
              color: Color.fromRGBO(91, 75, 95, .7),
              fontWeight: FontWeight.w600,
              fontSize: 12),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 5),
          child: RichText(
            text: TextSpan(
              children: customizeComment(comment.comment),
              style: GoogleFonts.raleway(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // child: Text(comment.comment,
          //     style: GoogleFonts.raleway(
          //       color: Colors.black,
          //       fontSize: 13,
          //       fontWeight: FontWeight.w600,
          //     )),
        ),

        trailing: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(15)),
          child: IconButton(
            icon: Icon(
              Ionicons.heart_outline,
              size: 23,
            ),
            color: Colors.grey,
            onPressed: () => print('Like comment'),
          ),
        ),
      ),
    );
  }
}

class MentionSearchTile extends StatelessWidget {
  final UserTest user;

  MentionSearchTile({this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          // width: MediaQuery.of(context).size.width * .95,
          // margin: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            // borderRadius: BorderRadius.circular(20),
            // boxShadow: [
            //   BoxShadow(
            //     color: Palette.lavender,
            //     offset: Offset(0, 0),
            //     blurRadius: 7,
            //     spreadRadius: 1,
            //   )
            // ]
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                child: ClipOval(
                  child:
                      CachedNetworkImage(imageUrl: user.dp, fit: BoxFit.cover),
                ),
              ),
              SizedBox(
                width: 15,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(this.user.name ?? "",
                      style: GoogleFonts.raleway(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  SizedBox(height: 6),
                  Text(this.user.fname ?? "", style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        Divider(),
      ],
    );
  }
}
