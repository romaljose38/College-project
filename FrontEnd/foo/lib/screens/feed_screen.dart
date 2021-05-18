import 'dart:convert';
import 'dart:ui';
import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:foo/colour_palette.dart';
import 'package:foo/models.dart';
import 'package:foo/screens/post_tile.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_cred.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

import 'models/post_model.dart' as pst;

import 'package:foo/stories/story_builder.dart';
import 'package:foo/stories/video_trimmer/trimmer.dart';

class FeedScreen extends StatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with TickerProviderStateMixin {
  // ScrollController _scrollController = ScrollController();
  // ScrollController _nestedScrollController = ScrollController();
  TrackingScrollController _scrollController = TrackingScrollController();
  SharedPreferences prefs;
  String curUser;
  int itemCount = 0;
  bool isConnected = false;
  GlobalKey<SliverAnimatedListState> listKey;
  ScrollController _controller;
  double currentPos = 0;
  var myStoryList = [];
  //

  @override
  initState() {
    listKey = GlobalKey<SliverAnimatedListState>();
    setInitialData();
    //_fetchStory();
    super.initState();
    // _getNewPosts();
    _controller = ScrollController();
    _controller.addListener(() {
      setState(() {
        currentPos = _controller.offset;
      });
      // print(currentPos);
    });
    _scrollController
      ..addListener(() {
        // if (_scrollController.position.pixels ==
        //     _scrollController.position.maxScrollExtent) {
        //   print("max max max");
        //   postsList.add(Post(
        //     username: 'Sam Martin',
        //     userDpUrl: 'assets/images/user0.png',
        //     postUrl: 'assets/images/post0.jpg',
        //   ));
        //   setState(() {
        //     itemCount += 1;
        //   });
        // }
      });
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    // _nestedScrollController.dispose();
  }

  Future<void> _checkConnectionStatus() async {
    bool result = await DataConnectionChecker().hasConnection;

    if (result == true) {
      setState(() {
        isConnected = true;
      });
    } else {
      setState(() {
        isConnected = false;
      });
    }
  }

  Future<void> setInitialData() async {
    await _checkConnectionStatus();
    prefs = await SharedPreferences.getInstance();
    curUser = prefs.getString("username");
    var feedBox = Hive.box("Feed");
    Feed feed;
    if (feedBox.containsKey("feed")) {
      feed = feedBox.get("feed");

      for (int i = feed.posts.length - 1; i >= 0; i--) {
        listKey.currentState
            .insertItem(0, duration: Duration(milliseconds: 200));
        postsList.insert(0, feed.posts[i]);
      }
      setState(() {
        itemCount += postsList.length;
      });
    } else {
      feed = Feed();

      await feedBox.put('feed', feed);
    }

    if (isConnected) {
      var response = await http.get(Uri.http(localhost, '/api/$curUser/posts'));
      var respJson = jsonDecode(response.body);

      if (response.statusCode == 200) {
        respJson.forEach((e) {
          Post post = Post(
              username: e['user']['username'],
              postUrl: 'http://' + localhost + e['file'],
              userDpUrl: 'assets/images/user0.png',
              postId: e['id'],
              commentCount: e['comment_count'],
              caption: e['caption'],
              userId: e['user']['id'],
              likeCount: e['likeCount'],
              haveLiked: e['hasLiked'],
              type: e['post_type']);
          if (feed.isNew(e['id'])) {
            listKey.currentState.insertItem(0);
            postsList.insert(0, post);
            feed.addPost(post);
            setState(() {
              itemCount += 1;
              // postsList = postsList;
            });
            feed.save();
          } else {
            feed.addPost(post);
            feed.save();
          }
        });
      }
    }
  }

  List postsList = [];

  // Future<void> _fetchStory() async {
  //   await _checkConnectionStatus();
  //   var response = await http.get(Uri.http(localhost, '/api/get_stories'));
  //   setState(() {
  //     myStoryList = jsonDecode(response.body);
  //     myItemCounter = myStoryList.length + 1;
  //   });
  //   // print(myStoryList);
  // }

  //int myItemCounter = 1;

  //The widget to display the stories which fetches data using the websocket

  Widget _newHoriz() {
    return ValueListenableBuilder(
        valueListenable: Hive.box('MyStories').listenable(),
        builder: (context, box, widget) {
          myStoryList = box.values.toList();
          myStoryList
              .sort((a, b) => b.timeOfLastStory.compareTo(a.timeOfLastStory));
          return Container(
            width: double.infinity,
            height: 100.0,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              //itemCount: pst.stories.length + 1,
              itemCount: myStoryList.length + 1, //myStoryList.length + 1,
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  return StoryUploadPick();
                }
                return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => StoryBuilder(
                                  myStoryList: myStoryList,
                                  initialPage: index - 1,
                                  profilePic: pst.stories,
                                )),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                      height: 50,
                      width: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromRGBO(250, 87, 142, 1),
                            Color.fromRGBO(202, 136, 18, 1),
                            Color.fromRGBO(253, 167, 142, 1),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(3),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(2),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(23),
                                  image: DecorationImage(
                                    image: AssetImage(pst.stories[index - 1]),
                                    // image: NetworkImage(
                                    //     'https://img.republicworld.com/republic-prod/stories/promolarge/xxhdpi/32qfhrhvfuzpdiev_1597135847.jpeg?tr=w-758,h-433'),
                                    fit: BoxFit.cover,
                                  )),
                            ),
                          ),
                        ),
                      ),
                    ));
              },
            ),
          );
        });
  }

  //

  // Container _horiz() {
  //   return Container(
  //     width: double.infinity,
  //     height: 100.0,
  //     child: ListView.builder(
  //       scrollDirection: Axis.horizontal,
  //       //itemCount: pst.stories.length + 1,
  //       itemCount: myItemCounter, //myStoryList.length + 1,
  //       itemBuilder: (BuildContext context, int index) {
  //         if (index == 0) {
  //           return StoryUploadPick();
  //         }
  //         return GestureDetector(
  //             onTap: () {
  //               print(
  //                   "You tickled ${myStoryList[index - 1]['username']} $index times");
  //               print("${myStoryList[index - 1]['stories'][0]['file']}");
  //               print("$myStoryList");
  //               print("${myStoryList.length}");
  //               Navigator.of(context).push(
  //                 MaterialPageRoute(
  //                     builder: (context) => StoryBuilder(
  //                           myStoryList: myStoryList,
  //                           initialPage: index - 1,
  //                           profilePic: pst.stories,
  //                         )),
  //               );
  //             },
  //             child: Container(
  //               margin: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
  //               height: 50,
  //               width: 80,
  //               decoration: BoxDecoration(
  //                 borderRadius: BorderRadius.circular(30),
  //                 gradient: LinearGradient(
  //                   begin: Alignment.topLeft,
  //                   end: Alignment.bottomRight,
  //                   colors: [
  //                     Color.fromRGBO(250, 87, 142, 1),
  //                     Color.fromRGBO(202, 136, 18, 1),
  //                     Color.fromRGBO(253, 167, 142, 1),
  //                   ],
  //                 ),
  //               ),
  //               child: Padding(
  //                 padding: EdgeInsets.all(3),
  //                 child: Container(
  //                   decoration: BoxDecoration(
  //                     color: Colors.white,
  //                     borderRadius: BorderRadius.circular(26),
  //                   ),
  //                   child: Padding(
  //                     padding: EdgeInsets.all(2),
  //                     child: Container(
  //                       decoration: BoxDecoration(
  //                           color: Colors.black,
  //                           borderRadius: BorderRadius.circular(23),
  //                           image: DecorationImage(
  //                             image: AssetImage(pst.stories[index - 1]),
  //                             // image: NetworkImage(
  //                             //     'https://img.republicworld.com/republic-prod/stories/promolarge/xxhdpi/32qfhrhvfuzpdiev_1597135847.jpeg?tr=w-758,h-433'),
  //                             fit: BoxFit.cover,
  //                           )),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             )
  //             // child: Container(
  //             //   margin: EdgeInsets.all(10.0),
  //             //   // width: 80.0,
  //             //   // height: 45.0,
  //             //   decoration: BoxDecoration(
  //             //       borderRadius: BorderRadius.circular(35),
  //             //       gradient: LinearGradient(
  //             //           begin: Alignment.topLeft,
  //             //           end: Alignment.bottomRight,
  //             //           colors: [
  //             //             Color.fromRGBO(250, 87, 142, 1),
  //             //             Palette.lightSalmon,
  //             //           ])
  //             //       // boxShadow: [
  //             //       //   BoxShadow(
  //             //       //     color: Colors.black45.withOpacity(.2),
  //             //       //     offset: Offset(0, 2),
  //             //       //     spreadRadius: 1,
  //             //       //     blurRadius: 6.0,
  //             //       //   ),
  //             //       // ],
  //             //       ),
  //             //   child: Padding(
  //             //     padding: const EdgeInsets.all(2.0),
  //             //     child: Container(
  //             //       decoration: BoxDecoration(
  //             //         color: Colors.white,
  //             //         borderRadius: BorderRadius.circular(30),
  //             //       ),
  //             //       child: Padding(
  //             //         padding: EdgeInsets.all(1),
  //             //         child: Container(
  //             //           width: 70,
  //             //           height: 40,
  //             //           decoration: BoxDecoration(
  //             //               borderRadius: BorderRadius.circular(30),
  //             //               // shape: BoxShape.circle,
  //             //               image: DecorationImage(
  //             //                 //image: AssetImage(pst.stories[index - 1]),
  //             //                 image: NetworkImage(
  //             //                     'https://img.republicworld.com/republic-prod/stories/promolarge/xxhdpi/32qfhrhvfuzpdiev_1597135847.jpeg?tr=w-758,h-433'),
  //             //                 fit: BoxFit.cover,
  //             //               )),
  //             //         ),
  //             //       ),
  //             //     ),
  //             //   ),
  //             // ),
  //             );
  //       },
  //     ),
  //   );
  // }

  Future<void> _getNewPosts() async {
    var response = await http.get(Uri.http(localhost, '/api/$curUser/posts'));
    var respJson = jsonDecode(response.body);

    var feedBox = Hive.box("Feed");
    var feed;
    if (feedBox.containsKey("feed")) {
      feed = feedBox.get('feed');
    } else {
      feed = Feed();
      await feedBox.put("feed", feed);
    }

    respJson.forEach((e) {
      if (feed.isNew(e['id'])) {
        Post post = Post(
            username: e['user']['username'],
            postUrl: 'http://' + localhost + e['file'],
            userDpUrl: 'assets/images/user0.png',
            postId: e['id'],
            userId: e['user']['id'],
            commentCount: e['comment_count'],
            caption: e['caption'],
            likeCount: e['likeCount'],
            haveLiked: e['hasLiked'],
            type: e['post_type']);
        listKey.currentState.insertItem(0);
        postsList.insert(0, post);
        feed.addPost(post);
        setState(() {
          itemCount += 1;
          // postsList = postsList;
        });
        feed.save();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        // backgroundColor: Color.fromRGBO(24, 4, 29, 1),
        // backgroundColor: Color.fromRGBO(218, 228, 237, 1),
        floatingActionButton: TextButton(
          child: Text(
            "A",
            style: TextStyle(color: Colors.black),
          ),
          onPressed: () {
            listKey.currentState.insertItem(0);
            var feedBox = Hive.box("Feed");
            var feed = feedBox.get('feed');
            postsList.insert(0, feed.posts[0]);
          },
        ),
        backgroundColor: Colors.white,
        body: Container(
          // margin: EdgeInsets.only(bottom: 40),
          // padding: const EdgeInsets.only(bottom: 40),
          child: RefreshIndicator(
            triggerMode: RefreshIndicatorTriggerMode.anywhere,
            onRefresh: () {
              _getNewPosts();
              //_fetchStory();
              return Future.value('nothing');
            },
            child: CustomScrollView(
              controller: _controller,
              slivers: [
                //SliverToBoxAdapter(child: _horiz()),
                SliverToBoxAdapter(child: _newHoriz()),
                SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverAnimatedList(
                  initialItemCount: itemCount,
                  key: listKey,
                  // controller: _scrollController,
                  itemBuilder: (context, index, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                              begin: Offset(0, -.4), end: Offset(0, 0))
                          .animate(CurvedAnimation(
                              parent: animation, curve: Curves.easeInOut)),
                      child: FadeTransition(
                        opacity:
                            Tween<double>(begin: 0, end: 1).animate(animation),
                        child: PostTile(
                            post: postsList[index],
                            index: index,
                            isLast:
                                index == (postsList.length - 1) ? true : false),
                      ),
                    );
                  },
                ),
              ],
            ),
            // child: NestedScrollView(
            //   floatHeaderSlivers: true,
            //   controller: _scrollController,
            //   headerSliverBuilder: (ctx, val) {
            //     print(val);
            //     return [];
            //   },
            //   body: AnimatedList(
            //     initialItemCount: itemCount,
            //     key: listKey,
            //     controller: _scrollController,
            //     itemBuilder: (context, index, animation) {
            //       return SlideTransition(
            //         position: Tween<Offset>(begin: Offset(0, -1), end: Offset(0, 0))
            //             .animate(animation),
            //         child: PostTile(post: postsList[index], index: index),
            //       );
            //     },
            //   ),
            // ),
            // child: AnimatedList(
            //   initialItemCount: 1,
            //   key: listKey,
            //   controller: _scrollController,
            //   itemBuilder: (context, index, animation) {
            //     return SlideTransition(
            //       position: Tween<Offset>(begin: Offset(0, -1), end: Offset(0, 0))
            //           .animate(animation),
            //       child: (index == 0)
            //           ?
            //           : PostTile(post: postsList[index - 1], index: index - 1),
            //     );
            //   },
            // )
            // child: ListView.builder(
            //     cacheExtent: 200,
            //     controller: _scrollController,
            //     itemCount: itemCount + 1,
            //     itemBuilder: (context, index) {
            //       if (index == 0) {
            //         return _horiz();
            //       }
            //       return PostTile(post: postsList[index - 1], index: index - 1);
            //     }),
          ),
        ),
      ),
    );
  }
}
