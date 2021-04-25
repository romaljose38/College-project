import 'dart:ui';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:foo/screens/models/post_model.dart';
import 'package:foo/screens/view_post_screen.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import 'feed_icons.dart';
import 'models/post_model.dart';

class FeedScreen extends StatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  Widget _img(int index) {
    return InkWell(
      onDoubleTap: () => print('Like post'),
      onTap: () {
        Navigator.of(context).push(PageRouteBuilder(
            pageBuilder: (context, animation, anotherAnimation) {
              return ViewPostScreen(post: posts[index]);
            },
            transitionDuration: Duration(milliseconds: 100),
            transitionsBuilder: (context, animation, anotherAnimation, child) {
              return SlideTransition(
                position: Tween(begin: Offset(1.0, 0.0), end: Offset(0.0, 0.0))
                    .animate(animation),
                child: child,
              );
            }));
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (_) => ViewPostScreen(
        //       post: posts[index],
        //     ),
        //   ),
        // );
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
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(posts[index].imageUrl),
                        fit: BoxFit.fitHeight,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                height: 300,
                width: double.infinity,
                // margin: EdgeInsets.all(10),
                child: AspectRatio(
                  aspectRatio: 4 / 5,
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
                      image: DecorationImage(
                        image: AssetImage(posts[index].imageUrl),
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                    // child:BackdropFilter(filter: ImageFilter.blur(sigmaX:10,sigmaY:10),)
                  ),
                ),
              ),
            ],
          )),
    );
  }

  Widget _buildPost(int index) {
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
                      child: CircleAvatar(
                        child: ClipOval(
                          child: Image(
                            height: 50.0,
                            width: 50.0,
                            image: AssetImage(posts[index].authorImageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      posts[index].authorName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(posts[index].timeAgo),
                    trailing: IconButton(
                      icon: Icon(Feed.colon),
                      color: Colors.black,
                      onPressed: () => print('More'),
                    ),
                  ),
                  Container(
                    height:300,
                    child: CarouselSlider(
                      items: [_img(0), _img(1), _img(2)],
                      options: CarouselOptions(
                        height: 300,
                        autoPlay: false,
                        enlargeCenterPage: true,
                        viewportFraction: 0.9,
                        aspectRatio:5/4,
                        initialPage: 2,
                      ),
                    ),
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
                                          post: posts[index],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(218, 228, 237, 1),
      //  Color(0xFFEDF0F6),
      body: ListView(
        physics: AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          // Padding(
          //   padding: EdgeInsets.symmetric(horizontal: 20.0),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: <Widget>[
          //       Text(
          //         'Instagram',
          //         style: TextStyle(
          //           fontFamily: 'Billabong',
          //           fontSize: 32.0,
          //         ),
          //       ),
          //       Row(
          //         children: <Widget>[
          //           IconButton(
          //             icon: Icon(Icons.live_tv),
          //             iconSize: 30.0,
          //             onPressed: () => print('IGTV'),
          //           ),
          //           SizedBox(width: 16.0),
          //           Container(
          //             width: 35.0,
          //             child: IconButton(
          //               icon: Icon(Icons.send),
          //               iconSize: 30.0,
          //               onPressed: () => print('Direct Messages'),
          //             ),
          //           )
          //         ],
          //       )
          //     ],
          //   ),
          // ),
          Container(
            width: double.infinity,
            height: 100.0,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: stories.length + 1,
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  return SizedBox(width: 10.0);
                }
                return Container(
                    margin: EdgeInsets.all(10.0),
                    width: 80.0,
                    height: 45.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(35),
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
                          width: 80,
                          height: 40,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              // shape: BoxShape.circle,
                              image: DecorationImage(
                                image: AssetImage(stories[index - 1]),
                                fit: BoxFit.cover,
                              )
                              // child: CircleAvatar(
                              //   child: ClipOval(
                              //     child: Image(
                              //       height: 60.0,
                              //       width: 60.0,
                              //       image: ,
                              //       fit: BoxFit.cover,
                              //     ),
                              //   ),
                              // ),
                              ),
                        )));
              },
            ),
          ),
          _buildPost(0),
          _buildPost(1),
          _buildPost(2),
        ],
      ),
      // bottomNavigationBar: BottomNavigationBar(
      //   showSelectedLabels: false,
      //   showUnselectedLabels: false,
      //   items: [
      //     BottomNavigationBarItem(
      //         label: "",
      //         icon: Icon(Ionicons.home_outline, size: 25, color: Colors.black)),
      //     BottomNavigationBarItem(
      //         label: "",
      //         icon:
      //             Icon(Ionicons.search_outline, size: 25, color: Colors.black)),
      //     BottomNavigationBarItem(
      //         label: "",
      //         icon:
      //             Icon(Ionicons.person_outline, size: 25, color: Colors.black)),
      //     BottomNavigationBarItem(
      //         label: "",
      //         icon: Icon(Ionicons.settings_outline,
      //             size: 25, color: Colors.black)),
      //   ],
      // ),
    );
  }
}
