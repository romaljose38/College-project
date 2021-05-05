import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:foo/profile/profile.dart';
import 'package:foo/screens/view_post_screen.dart';
import 'package:foo/test_cred.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:ionicons/ionicons.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'feed_icons.dart' as icons;
import 'package:foo/models.dart';

class PostTile extends StatefulWidget {
  final Post post;
  final int index;

  PostTile({this.post, this.index});

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
  bool hasTapped = false;

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    _animation = Tween<double>(begin: 0, end: 1).animate(_animController);
    setUserName();
    likeCount = widget.post.likeCount ?? 0;
    hasLiked = widget.post.haveLiked ?? false;
    postId = widget.post.postId ?? 0;
    testReq();
  }

  testReq() async {
    var resp = await http.get(Uri.http(localhost, '/api'));
  }

  Future<void> setUserName() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    userName = _prefs.getString("username");
  }

  likePost() async {
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

  updatePostInHive(int id, bool status) {
    var feedBox = Hive.box("Feed");
    Feed feed = feedBox.get('feed');
    if ((id <= feed.posts.first.postId) & (id >= feed.posts.last.postId)) {
      feed.updatePostStatus(id, status);
      feed.save();
    }
  }

  InkWell _img(BuildContext context) => InkWell(
        onDoubleTap: () => print('Like post'),
        onTap: () {
          Navigator.push(
              context,
              PageRouteBuilder(pageBuilder: (context, animation, secAnimation) {
                return ViewPostScreen(post: widget.post, index: widget.index);
              }, transitionsBuilder: (context, animation, secAnimation, child) {
                return SlideTransition(
                    position: Tween(begin: Offset(1, 0), end: Offset(0, 0))
                        .animate(animation),
                    child: child);
              })
              // MaterialPageRoute(
              //     builder: (_) => ViewPostScreen(post: post, index: index))
              );
        },
        child: Container(
            height: 280,
            width: double.infinity,
            margin: EdgeInsets.fromLTRB(15, 5, 15, 10),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.antiAlias,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      // margin: EdgeInsets.all(10.0),
                      height: 300,
                      // width:250,
                      width: double.infinity,
                      // decoration: BoxDecoration(
                      //   image: DecorationImage(
                      //     image: NetworkImage(post.postUrl),
                      //     fit: BoxFit.cover,
                      //   ),
                      // ),
                      child: CachedNetworkImage(
                          imageUrl: widget.post.postUrl, fit: BoxFit.cover),
                    ),
                  ),
                ),
                Container(
                  height: 300,
                  width: double.infinity,
                  // margin: EdgeInsets.all(10),
                  child: AspectRatio(
                    aspectRatio: 4 / 5,
                    child: Hero(
                      tag: 'profile_${widget.index}',
                      child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black45,
                                offset: Offset(0, 5),
                                blurRadius: 8.0,
                              ),
                            ],
                            // image: DecorationImage(
                            //   image: NetworkImage(post.postUrl),
                            //   fit: BoxFit.contain,
                            // ),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: widget.post.postUrl,
                            fit: BoxFit.contain,
                            progressIndicatorBuilder: (ctx, string, progress) {
                              return Center(
                                  child: CircularProgressIndicator(
                                strokeWidth: 1,
                                value: progress.progress,
                              ));
                            },
                          )
                          // child:BackdropFilter(filter: ImageFilter.blur(sigmaX:10,sigmaY:10),)
                          ),
                    ),
                  ),
                ),
              ],
            )),
      );

  @override
  void dispose() {
    super.dispose();
    _animController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(widget.post.postId);
    print(widget.post.userId);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      child: Container(
        width: double.infinity,
        height: 420.0,
        margin: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25.0),
            boxShadow: [
              BoxShadow(
                  // color: Color.fromRGBO(190, 205, 232, .5),
                  color: Colors.black.withOpacity(.2),
                  blurRadius: 4,
                  spreadRadius: 1,
                  offset: Offset(0, 3)),
            ],
            border: Border.all(
              color: Colors.white60,
              width: 1,
            )),
        child: GestureDetector(
          onTap: () {
            _animController.forward();
            setState(() {
              hasTapped = true;
            });
          },
          child: Stack(
            children: [
              Container(
                height: 420,
                width: double.infinity,
                decoration: BoxDecoration(
                  // boxShadow: [BoxShadow()],
                  borderRadius: BorderRadius.circular(25),
                  image: DecorationImage(
                    image: AssetImage("assets/images/user4.png"),
                    // image: CachedNetworkImageProvider(widget.post.postUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                child: Container(
                  width: MediaQuery.of(context).size.width * .8,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            child: ClipOval(
                              child: Image(
                                height: 50.0,
                                width: 50.0,
                                image: AssetImage(widget.post.userDpUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 10, horizontal: 5),
                            // color: Colors.black.withOpacity(.3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(.3),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Text(
                              "Deepika Charly",
                              style: GoogleFonts.raleway(
                                fontSize: 15,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      Text(
                        "It is good to love god for hope of reward in this or the next world, but it is better to love god for love's sake",
                        overflow: TextOverflow.visible,
                        style: GoogleFonts.raleway(
                            color: Colors.white, fontSize: 13),
                      )
                    ],
                  ),
                ),
              ),
              hasTapped
                  ? FadeTransition(
                      opacity: _animation,
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
                            color: Colors.black.withOpacity(.4),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: <Widget>[
                                    IconButton(
                                      icon: Icon(
                                          hasLiked
                                              ? Ionicons.heart
                                              : Ionicons.heart_outline,
                                          color: Colors.white),
                                      iconSize: 30.0,
                                      onPressed: likePost,
                                    ),
                                    Text(
                                      likeCount.toString(),
                                      style: TextStyle(
                                        fontSize: 13.0,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 20.0),
                                Row(
                                  children: <Widget>[
                                    IconButton(
                                      icon: Icon(Ionicons.chatbox_outline,
                                          color: Colors.white),
                                      iconSize: 30.0,
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
                                      '350',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
      ),
    );
  }
}
