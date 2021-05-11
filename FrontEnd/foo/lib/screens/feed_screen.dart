import 'dart:convert';
import 'dart:ui';
import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:foo/models.dart';
import 'package:foo/screens/post_tile.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_cred.dart';

import 'package:http/http.dart' as http;

import 'models/post_model.dart' as pst;

import 'package:foo/stories/story_builder.dart';

class FeedScreen extends StatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  ScrollController _scrollController = ScrollController();
  SharedPreferences prefs;
  String curUser;
  int itemCount = 0;
  bool isConnected = false;
  GlobalKey<AnimatedListState> listKey;

  //
  var myStoryList = [];
  //

  @override
  initState() {
    listKey = GlobalKey<AnimatedListState>();
    setInitialData();
    _fetchStory();
    super.initState();
    // _getNewPosts();
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

      for (int i = 0; i < feed.posts.length; i++) {
        listKey.currentState
            .insertItem(0, duration: Duration(milliseconds: 200));
        postsList.add(feed.posts[i]);
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
          if (feed.isNew(e['id'])) {
            Post post = Post(
                username: e['user']['username'],
                postUrl: 'http://' + localhost + e['file'],
                userDpUrl: 'assets/images/user0.png',
                postId: e['id'],
                userId: e['user']['id'],
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
    }
  }

  List postsList = [];

  Future<void> _fetchStory() async {
    await _checkConnectionStatus();
    var response = await http.get(Uri.http(localhost, '/api/get_stories'));
    setState(() {
      myStoryList = jsonDecode(response.body);
    });
    print(myStoryList);
  }

  Container _horiz() {
    return Container(
      width: double.infinity,
      height: 100.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        //itemCount: pst.stories.length + 1,
        itemCount: myStoryList.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return SizedBox(width: 10.0);
          }
          return GestureDetector(
            onTap: () {
              print(
                  "You tickled ${myStoryList[index - 1]['username']} $index times");
              print("${myStoryList[index - 1]['stories'][0]['file']}");
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => StoryBuilder(
                          myStoryList: myStoryList,
                          initialPage: index - 1,
                        )),
              );
            },
            child: Container(
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
                        //image: AssetImage(pst.stories[index - 1]),
                        image: NetworkImage(
                            'https://img.republicworld.com/republic-prod/stories/promolarge/xxhdpi/32qfhrhvfuzpdiev_1597135847.jpeg?tr=w-758,h-433'),
                        fit: BoxFit.cover,
                      )),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

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
    return Scaffold(
      // backgroundColor: Color.fromRGBO(218, 228, 237, 1),
      backgroundColor: Colors.white,
      body: RefreshIndicator(
          triggerMode: RefreshIndicatorTriggerMode.anywhere,
          onRefresh: _getNewPosts,
          child: AnimatedList(
            initialItemCount: 1,
            key: listKey,
            controller: _scrollController,
            itemBuilder: (context, index, animation) {
              return FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(animation),
                child: (index == 0)
                    ? _horiz()
                    : PostTile(post: postsList[index - 1], index: index - 1),
              );
            },
          )
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
    );
  }
}
