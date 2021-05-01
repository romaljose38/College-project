import 'dart:convert';
import 'dart:ui';
import 'package:foo/chat/socket.dart';
import 'package:foo/models.dart';
import 'package:foo/screens/post_tile.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_cred.dart';

import 'package:http/http.dart' as http;

import 'models/post_model.dart' as pst;

class FeedScreen extends StatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  ScrollController _scrollController = ScrollController();
  SharedPreferences prefs;
  String curUser;
  int itemCount = 0;
  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();

  @override
  initState() {
    setInitialData();
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

  setInitialData() async {
    prefs = await SharedPreferences.getInstance();
    curUser = prefs.getString("username");
    if (NotificationController.isActive) {
      var response = await http.get(Uri.http(localhost, '/api/$curUser/posts'));
      var respJson = jsonDecode(response.body);
      print(respJson);
      print(respJson.runtimeType);
    }

    var feedBox = Hive.box("Feed");
    Feed feed;
    if (feedBox.containsKey("feed")) {
      feed = feedBox.get("feed");

      for (int i = 0; i < feed.posts.length; i++) {
        listKey.currentState.insertItem(1, duration: Duration(seconds: 3));
        postsList.insert(0, feed.posts[i]);
      }
      setState(() {
        itemCount += postsList.length;
      });
      print(feed.posts);
    } else {
      feed = Feed();
      await feedBox.put('feed', feed);
    }
  }

  List postsList = [];

  Container _horiz() {
    return Container(
      width: double.infinity,
      height: 100.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: pst.stories.length + 1,
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
                      image: AssetImage(pst.stories[index - 1]),
                      fit: BoxFit.cover,
                    )),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<List> _getNewPosts() async {
    var response = await http.get(Uri.http(localhost, '/api/$curUser/posts'));
    var respJson = jsonDecode(response.body);
    print(respJson);
    print(respJson.runtimeType);

    var feedBox = Hive.box("Feed");
    var feed = feedBox.get('feed');

    respJson.forEach((e) {
      if (feed.isNew(e['id'])) {
        print(e);
        Post post = Post(
            username: e['user']['username'],
            postUrl: 'http://' + localhost + e['file'],
            userDpUrl: 'assets/images/user0.png',
            postId: e['id']);
        listKey.currentState.insertItem(0);
        postsList.insert(0, post);
        feed.addPost(post);
        setState(() {
          itemCount += respJson.length;
          // postsList = postsList;
        });
        feed.save();
      }
    });

    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(218, 228, 237, 1),
      body: RefreshIndicator(
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
