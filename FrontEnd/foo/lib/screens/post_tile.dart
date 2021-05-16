import 'dart:io';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:foo/profile/profile_test.dart';
import 'package:foo/screens/comment_screen.dart';
import 'package:foo/screens/view_post_screen.dart';
import 'package:foo/test_cred.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:ionicons/ionicons.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// import 'feed_icons.dart' as icons;
import 'package:foo/models.dart';
import 'dart:math' as math;

class PostTile extends StatefulWidget {
  final Post post;
  final int index;
  final bool isLast;

  PostTile({this.post, this.index, this.isLast});

  @override
  _PostTileState createState() => _PostTileState();
}

class _PostTileState extends State<PostTile> with TickerProviderStateMixin {
  bool hasLiked = false;
  int likeCount = 0;
  int postId;
  String userName;
  AnimationController _animController;
  Animation _animation;
  AnimationController _overlayanimController;
  Animation _overlayAnimation;
  bool hasTapped = false;
  OverlayEntry overlayEntry;

  @override
  void initState() {
    super.initState();

    //Controller and animation for single tap overlay
    _animController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    _animation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animController, curve: Curves.bounceIn));

    //Controller and animation for double tap overlay
    _overlayanimController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 100),
        reverseDuration: Duration(milliseconds: 100));
    _overlayAnimation =
        Tween<double>(begin: 0, end: 1).animate(_overlayanimController);

    setUserName();
    likeCount = widget.post.likeCount ?? 0;
    hasLiked = widget.post.haveLiked ?? false;
    postId = widget.post.postId ?? 0;
  }

  Future<void> setUserName() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    userName = _prefs.getString("username");
  }

  Future<void> likePost() async {
    print(hasLiked);
    print(likeCount);
    print(postId);
    if (hasLiked) {
      var response = await http.get(Uri.http(localhost, 'api/remove_like', {
        'username': userName,
        'id': postId.toString(),
      }));
      if (response.statusCode == 200) {
        setState(() {
          hasLiked = false;
          likeCount -= 1;
        });
      }
      updatePostInHive(postId, false);
    } else {
      setState(() {
        hasTapped = true;
      });
      _animController.forward().whenComplete(
            () => Future.delayed(Duration(milliseconds: 800), () {
              _animController.reverse().whenComplete(() {
                setState(() {
                  hasTapped = false;
                });
              });
            }),
          );

      var response = await http.get(Uri.http(localhost, '/api/add_like', {
        'username': userName,
        'id': postId.toString(),
      }));
      if (response.statusCode == 200) {
        setState(() {
          hasLiked = true;
          likeCount += 1;
        });
      }
      updatePostInHive(postId, true);
    }
  }

  void updatePostInHive(int id, bool status) {
    var feedBox = Hive.box("Feed");
    Feed feed = feedBox.get('feed');
    if ((id <= feed.posts.first.postId) & (id >= feed.posts.last.postId)) {
      feed.updatePostStatus(id, status);
      feed.save();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _animController.dispose();
    _overlayanimController.dispose();
  }

  void showOverlay(BuildContext context, {String url}) {
    OverlayState overlayState = Overlay.of(context);
    print("in here");
    overlayEntry = OverlayEntry(
        builder: (context) => FadeTransition(
              opacity: _overlayAnimation,
              child: GestureDetector(
                onTap: () {},
                child: Scaffold(
                  backgroundColor: Colors.black.withOpacity(.5),
                  body: Center(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
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
                        ), // ),
                      ),
                    ),
                  ),
                ),
              ),
            ));
    _overlayanimController.forward();
    overlayState.insert(overlayEntry);
  }

  Container postImage(height) => Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          // boxShadow: [BoxShadow()],

          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withOpacity(.5),
          //     spreadRadius: -2,
          //     blurRadius: 7,
          //   )
          // ],
          image: DecorationImage(
            image: CachedNetworkImageProvider(widget.post.postUrl),
            // image: CachedNetworkImageProvider(widget.post.postUrl),
            fit: BoxFit.cover,
          ),
        ),
      );

  Container postAudio(height) => Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          // boxShadow: [BoxShadow()],
          // borderRadius: BorderRadius.circular(25),
          image: DecorationImage(
            image: CachedNetworkImageProvider(widget.post.postUrl),
            // image: CachedNetworkImageProvider(widget.post.postUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(child: Player()),
      );

  Container postVideo() => Container(
        height: 540,
        width: double.infinity,
        decoration: BoxDecoration(
          // boxShadow: [BoxShadow()],
          // borderRadius: BorderRadius.circular(25),
          image: DecorationImage(
            image: CachedNetworkImageProvider(widget.post.postUrl),
            // image: CachedNetworkImageProvider(widget.post.postUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(child: Player()),
      );

  BoxDecoration cardDecorationWithShadow() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30.0),
      // boxShadow: [
      //   BoxShadow(
      //       // color: Color.fromRGBO(190, 205, 232, .5),
      //       color: Colors.black.withOpacity(.2),
      //       blurRadius: 10,
      //       spreadRadius: 1,
      //       offset: Offset(0, -2)),
      // ],
    );
  }

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    var height = math.min(540, MediaQuery.of(context).size.height * .7);
    // var height = 440.0;
    print(widget.post.type);
    return Container(
      width: double.infinity,
      // margin: EdgeInsets.symmetric(horizontal: 5),
      height: height,

      margin: widget.isLast ? EdgeInsets.only(bottom: 60) : EdgeInsets.all(0),
      decoration:
          widget.index == 0 ? cardDecoration() : cardDecorationWithShadow(),
      child: GestureDetector(
        onTap: () async {
          var result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CommentScreen(
                      postUrl: widget.post.postUrl,
                      heroIndex: widget.index,
                      postId: widget.post.postId,
                      height: height)
                  // ViewPostScreen(post: widget.post, index: widget.index),
                  ));
          print("got back something");
          print(result);
        },
        onDoubleTap: likePost,
        onLongPressStart: (details) {
          showOverlay(context, url: widget.post.postUrl);
        },
        onLongPressEnd: (details) {
          _overlayanimController
              .reverse()
              .whenComplete(() => overlayEntry.remove());
        },
        child: Stack(
          children: [
            Hero(
              tag: 'profile_${widget.index}',
              transitionOnUserGestures: true,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: widget.post.type == "img"
                    ? postImage(height)
                    : postAudio(height),
              ),
            ),
            Container(
              height: height,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(.8), Colors.transparent],
                  stops: [.01, .2],
                ),
              ),
            ),
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
                          builder: (_) => Profile(userId: widget.post.userId),
                        ),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        image: DecorationImage(
                          image: AssetImage(widget.post.userDpUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 6),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                    // color: Colors.black.withOpacity(.3),
                    decoration: BoxDecoration(
                        // color: Colors.black.withOpacity(.3),
                        // borderRadius: BorderRadius.circular(20),
                        ),
                    child: Text(
                      widget.post.username,
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
            Positioned(
              bottom: 8,
              left: 0,
              child: Container(
                width: MediaQuery.of(context).size.width - 20,
                padding: EdgeInsets.fromLTRB(20, 0, 0, 25),
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
                    SizedBox(
                      height: 15,
                    ),
                    Row(children: [
                      // ClipRRect(
                      //   borderRadius: BorderRadius.circular(20),
                      //   child: Container(
                      //       // width: 60,
                      //       height: 40,
                      //       decoration: BoxDecoration(
                      //         // color: Colors.black,
                      //         borderRadius: BorderRadius.circular(20),
                      //       ),
                      //       child: BackdropFilter(
                      //         filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      //         child: Row(
                      //           mainAxisAlignment: MainAxisAlignment.start,
                      //           crossAxisAlignment: CrossAxisAlignment.center,
                      //           children: [
                      //             IconButton(
                      //               icon: Icon(
                      //                   hasLiked
                      //                       ? Ionicons.heart
                      //                       : Ionicons.heart_outline,
                      //                   color: Colors.white),
                      //               iconSize: 22.0,
                      //               onPressed: likePost,
                      //             ),
                      //             Text(
                      //               likeCount.toString(),
                      //               style: TextStyle(
                      //                 fontSize: 12.0,
                      //                 color: Colors.white,
                      //                 fontWeight: FontWeight.w600,
                      //               ),
                      //             ),
                      //             SizedBox(width: 10),
                      //           ],
                      //         ),
                      //       )),
                      // ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          constraints: BoxConstraints(maxWidth: 69),
                          color: hasLiked
                              ? Colors.red.shade700
                              : Colors.transparent,
                          height: 37,
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                                sigmaX: hasLiked ? 0 : 25,
                                sigmaY: hasLiked ? 0 : 25),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Ionicons.heart,
                                    color: Colors.white, size: 22),
                                SizedBox(width: 5),
                                // SizedBox(width: 25),
                                Text(
                                  "342",
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
                      Container(
                        width: 75,
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
                              icon: Icon(Ionicons.chatbox, color: Colors.white),
                              iconSize: 25.0,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ViewPostScreen(
                                      post: widget.post,
                                    ),
                                  ),
                                );
                              },
                            ),
                            Text(
                              widget.post.commentCount.toString(),
                              style: TextStyle(
                                fontSize: 13.0,
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
                      child: Padding(
                        padding: const EdgeInsets.only(right: 15),
                        child: ExpandableText(
                          // "It is good to love god for hope of reward in this or the next world, but it is better to love god for love's sake",
                          widget.post.caption,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            hasTapped
                ? ScaleTransition(
                    scale: _animation,
                    child: GestureDetector(
                      onTap: () {
                        _animController
                            .reverse()
                            .whenComplete(() => setState(() {
                                  hasTapped = false;
                                }));
                      },
                      child: Container(
                        height: 420,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          // color: Colors.black.withOpacity(.4),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: IconButton(
                            icon: Icon(Ionicons.heart, color: Colors.white),
                            iconSize: 50.0,
                            onPressed: () {},
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(),
          ],
        ),
      ),
      // child: Column(
      //   children: <Widget>[
      //     Padding(
      //       padding: EdgeInsets.symmetric(vertical: 10.0),
      //       child: Column(
      //         children: <Widget>[
      //           ListTile(
      //             leading: Container(
      //               width: 50.0,
      //               height: 50.0,
      //               decoration: BoxDecoration(
      //                 borderRadius: BorderRadius.circular(30),
      //                 boxShadow: [
      //                   BoxShadow(
      //                     color: Colors.black45,
      //                     offset: Offset(0, 2),
      //                     blurRadius: 6.0,
      //                   ),
      //                 ],
      //               ),
      //               child: InkWell(
      //                 onTap: () {
      //                   Navigator.push(
      //                     context,
      //                     MaterialPageRoute(
      //                       builder: (_) => Profile(post: this.widget.post),
      //                     ),
      //                   );
      //                 },
      //                 child: CircleAvatar(
      //                   child: ClipOval(
      //                     child: Image(
      //                       height: 50.0,
      //                       width: 50.0,
      //                       image: AssetImage(widget.post.userDpUrl),
      //                       fit: BoxFit.cover,
      //                     ),
      //                   ),
      //                 ),
      //               ),
      //             ),
      //             title: Text(
      //               this.widget.post.username,
      //               style: TextStyle(
      //                 fontWeight: FontWeight.bold,
      //               ),
      //             ),
      //             trailing: IconButton(
      //               icon: Icon(icons.Feed.colon),
      //               color: Colors.black,
      //               onPressed: () => print('More'),
      //             ),
      //           ),
      //           Container(
      //             height: 300,
      //             child: _img(context),
      //             // child: CarouselSlider(
      //             //   items: [_img(0), _img(1), _img(2)],
      //             //   options: CarouselOptions(
      //             //     height: 300,
      //             //     autoPlay: false,
      //             //     enlargeCenterPage: true,
      //             //     viewportFraction: 0.9,
      //             //     aspectRatio: 5 / 4,
      //             //     initialPage: 2,
      //             //   ),
      //             // ),
      //           ),
      //           Padding(
      //             padding: EdgeInsets.symmetric(horizontal: 20.0),
      //             child: Row(
      //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //               children: <Widget>[
      //                 Row(
      //                   children: <Widget>[
      //                     Row(
      //                       children: <Widget>[
      //                         IconButton(
      //                           icon: Icon(hasLiked
      //                               ? Ionicons.heart
      //                               : Ionicons.heart_outline),
      //                           iconSize: 25.0,
      //                           onPressed: likePost,
      //                         ),
      //                         Text(
      //                           likeCount.toString(),
      //                           style: TextStyle(
      //                             fontSize: 12.0,
      //                             fontWeight: FontWeight.w600,
      //                           ),
      //                         ),
      //                       ],
      //                     ),
      //                     SizedBox(width: 20.0),
      //                     Row(
      //                       children: <Widget>[
      //                         IconButton(
      //                           icon: Icon(Ionicons.chatbox_outline),
      //                           iconSize: 25.0,
      //                           onPressed: () {
      //                             Navigator.push(
      //                               context,
      //                               MaterialPageRoute(
      //                                 builder: (_) => ViewPostScreen(
      //                                   post: widget.post,
      //                                 ),
      //                               ),
      //                             );
      //                           },
      //                         ),
      //                         Text(
      //                           '350',
      //                           style: TextStyle(
      //                             fontSize: 12.0,
      //                             fontWeight: FontWeight.w600,
      //                           ),
      //                         ),
      //                       ],
      //                     ),
      //                   ],
      //                 ),
      //                 IconButton(
      //                   icon: Icon(Ionicons.bookmarks_outline),
      //                   iconSize: 25.0,
      //                   onPressed: () => print('Save post'),
      //                 ),
      //               ],
      //             ),
      //           ),
      //         ],
      //       ),
      //     ),
      //   ],
      // ),
    );
  }
}

class ExpandableText extends StatefulWidget {
  ExpandableText(this.text);

  final String text;
  bool isExpanded = false;

  @override
  _ExpandableTextState createState() => new _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText>
    with TickerProviderStateMixin<ExpandableText> {
  @override
  Widget build(BuildContext context) {
    return new Stack(children: <Widget>[
      new AnimatedSize(
          vsync: this,
          duration: const Duration(milliseconds: 100),
          child: GestureDetector(
            onTap: () => setState(() => widget.isExpanded = !widget.isExpanded),
            child: new Container(
                constraints: widget.isExpanded
                    ? new BoxConstraints()
                    : new BoxConstraints(maxHeight: 20.0),
                child: new Text(
                  widget.text,
                  softWrap: true,
                  style: TextStyle(color: Colors.white),
                  overflow: widget.isExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                )),
          )),
    ]);
  }
}

class Player extends StatefulWidget {
  final File file;

  Player({Key key, this.file}) : super(key: key);

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  AudioPlayer player;
  bool isPlaying = false;
  int totalDuration;
  double valState = 0;
  bool hasInitialized = false;

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
    addListeners();
  }

  @override
  void dispose() {
    super.dispose();
    player.dispose();
  }

  //adds listeners to the player to update the slider and all..
  void addListeners() {
    player.onDurationChanged.listen((Duration d) {
      print('Max duration: $d');
    });

    player.onAudioPositionChanged.listen((e) {
      if (e.inMilliseconds == totalDuration) {
        setState(() {
          isPlaying = false;
        });
      }
      var percent = e.inMilliseconds / totalDuration;
      print(percent);
      setState(() {
        valState = percent * 100;
      });
      print(e.inMilliseconds);
    });

    player.onPlayerCompletion.listen((event) {
      setState(() {
        isPlaying = false;
      });
    });
  }

  //activates the player and responsible for changing the pause/play icon
  Future<void> playerStateChange() async {
    print("button click");
    if (!hasInitialized) {
      await player.setUrl(
          "https://www2.cs.uic.edu/~i101/SoundFiles/BabyElephantWalk60.wav");
      var duration = await player.getDuration();
      print(duration);
      print("this is the duration");
      setState(() {
        totalDuration = duration;
      });
      await player.resume();
      setState(() {
        valState = null;
        hasInitialized = true;
      });
    }
    // if ((widget.file != null) & (!hasInitialized)) {
    //   print("initializing");
    //
    // }
    if (isPlaying) {
      await player.pause();
      setState(() {
        isPlaying = false;
      });
    } else {
      await player.resume();
      setState(() {
        isPlaying = true;
      });
    }
  }

  //manages slider seeking
  Future<void> seekAudio(double val) async {
    print(val);

    Duration position = Duration(milliseconds: (val * totalDuration).toInt());
    await player.seek(position);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          child: CircularProgressIndicator(
            value: valState,
            strokeWidth: 1,
            backgroundColor: Colors.white,
          ),
        ),
        Positioned(
            top: 22,
            left: 20,
            child: IconButton(
              icon: Icon(
                  this.isPlaying ? Ionicons.pause_circle : Ionicons.play_circle,
                  size: 45,
                  color: Colors.white),
              onPressed: playerStateChange,
            )),
      ],
    );
  }
}
