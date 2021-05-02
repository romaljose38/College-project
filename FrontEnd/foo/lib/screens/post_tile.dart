import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:foo/profile/profile.dart';
import 'package:foo/screens/view_post_screen.dart';
import 'package:ionicons/ionicons.dart';

import 'feed_icons.dart' as icons;
import 'package:foo/models.dart';

class PostTile extends StatelessWidget {
  final Post post;
  final int index;

  PostTile({this.post, this.index});

  InkWell _img(BuildContext context) => InkWell(
        onDoubleTap: () => print('Like post'),
        onTap: () {
          Navigator.push(
              context,
              PageRouteBuilder(pageBuilder: (context, animation, secAnimation) {
                return ViewPostScreen(post: post, index: index);
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
                          imageUrl: post.postUrl, fit: BoxFit.cover),
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
                      tag: 'profile_$index',
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
                            imageUrl: post.postUrl,
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
  Widget build(BuildContext context) {
    print(post.postId);
    print(post.userId);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      child: Container(
        width: double.infinity,
        height: 442.0,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25.0),
            boxShadow: [
              BoxShadow(
                  color: Color.fromRGBO(190, 205, 232, .5),
                  blurRadius: 4,
                  spreadRadius: 1,
                  offset: Offset(0, 3)),
            ],
            border: Border.all(
              color: Colors.white60,
              width: 1,
            )),
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: Container(
                      width: 50.0,
                      height: 50.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black45,
                            offset: Offset(0, 2),
                            blurRadius: 6.0,
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Profile(post: this.post),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          child: ClipOval(
                            child: Image(
                              height: 50.0,
                              width: 50.0,
                              image: AssetImage(post.userDpUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      this.post.username,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(icons.Feed.colon),
                      color: Colors.black,
                      onPressed: () => print('More'),
                    ),
                  ),
                  Container(
                    height: 300,
                    child: _img(context),
                    // child: CarouselSlider(
                    //   items: [_img(0), _img(1), _img(2)],
                    //   options: CarouselOptions(
                    //     height: 300,
                    //     autoPlay: false,
                    //     enlargeCenterPage: true,
                    //     viewportFraction: 0.9,
                    //     aspectRatio: 5 / 4,
                    //     initialPage: 2,
                    //   ),
                    // ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                IconButton(
                                  icon: Icon(Ionicons.heart_outline),
                                  iconSize: 25.0,
                                  onPressed: () => print('Like post'),
                                ),
                                Text(
                                  '2,515',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 20.0),
                            Row(
                              children: <Widget>[
                                IconButton(
                                  icon: Icon(Ionicons.chatbox_outline),
                                  iconSize: 25.0,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ViewPostScreen(
                                          post: post,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                Text(
                                  '350',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Ionicons.bookmarks_outline),
                          iconSize: 25.0,
                          onPressed: () => print('Save post'),
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
    );
  }
}
