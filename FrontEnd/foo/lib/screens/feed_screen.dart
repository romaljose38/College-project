import 'dart:convert';
import 'dart:ui';
import 'package:foo/screens/models/post_model.dart';
import 'package:foo/screens/post_tile.dart';
import 'package:flutter/material.dart';
import '../test_cred.dart';
import 'models/post_model.dart';
import 'package:http/http.dart' as http;

class FeedScreen extends StatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  ScrollController _scrollController = ScrollController();

  int itemCount = 0;
  @override
  initState() {
    super.initState();
    _scrollController
      ..addListener(() {
        if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent) {
          print("max max max");
          postsList.add(Post(
            authorName: 'Sam Martin',
            authorImageUrl: 'assets/images/user0.png',
            timeAgo: '5 min',
            imageUrl: 'assets/images/post0.jpg',
          ));
          setState(() {
            itemCount += 1;
          });
        }
      });
  }

  List postsList = [
    // Post(
    //   authorName: 'Sam Martin',
    //   authorImageUrl: 'assets/images/user0.png',
    //   timeAgo: '5 min',
    //   imageUrl: 'assets/images/post0.jpg',
    // ),
    // Post(
    //   authorName: 'Sam Martin',
    //   authorImageUrl: 'assets/images/user0.png',
    //   timeAgo: '10 min',
    //   imageUrl: 'assets/images/post1.jpg',
    // ),
    // Post(
    //   authorName: 'Sam Martin',
    //   authorImageUrl: 'assets/images/user0.png',
    //   timeAgo: '10 min',
    //   imageUrl: 'assets/images/post5.jpg',
    // ),
  ];

  Container _horiz() {
    return Container(
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
                    )),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<List> _getNewPosts() async {
    var response = await http.get(Uri.http('10.0.2.2:8000', '/api/posts'));
    var respJson = jsonDecode(response.body);
    print(respJson.runtimeType);
    respJson.forEach((e) {
      print(e);
      postsList.insert(
          0,
          Post(
              authorName: e['user']['username'],
              imageUrl: 'http://' + localhost + e['file'],
              authorImageUrl: 'assets/images/user0.png',
              timeAgo: '5 min ago'));
    });
    setState(() {
      itemCount = respJson.length + 1;
      // postsList = postsList;
    });
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(218, 228, 237, 1),
      body: RefreshIndicator(
        onRefresh: _getNewPosts,
        child: ListView.builder(
            cacheExtent: 200,
            controller: _scrollController,
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _horiz();
              }
              return PostTile(post: postsList[index - 1], index: index - 1);
            }),
      ),
    );
  }
}
