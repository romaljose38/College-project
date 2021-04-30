import 'dart:ui';
import 'package:foo/screens/models/post_model.dart';
import 'package:foo/screens/post_tile.dart';
import 'package:flutter/material.dart';
import 'models/post_model.dart';

class FeedScreen extends StatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  ScrollController _scrollController = ScrollController();
  int itemCount = 3;
  @override
  initState() {
    super.initState();
    _scrollController
      ..addListener(() {
        if (_scrollController.position.pixels ==
            (_scrollController.position.minScrollExtent + 200)) {
          postsList.insert(
              0,
              Post(
                authorName: 'Sam Martin',
                authorImageUrl: 'assets/images/user0.png',
                timeAgo: '5 min',
                imageUrl: 'assets/images/post0.jpg',
              ));
          setState(() {
            itemCount += 1;
          });
          print("min min min");
        } else if (_scrollController.position.pixels ==
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

  final List postsList = [
    Post(
      authorName: 'Sam Martin',
      authorImageUrl: 'assets/images/user0.png',
      timeAgo: '5 min',
      imageUrl: 'assets/images/post0.jpg',
    ),
    Post(
      authorName: 'Sam Martin',
      authorImageUrl: 'assets/images/user0.png',
      timeAgo: '10 min',
      imageUrl: 'assets/images/post1.jpg',
    ),
    Post(
      authorName: 'Sam Martin',
      authorImageUrl: 'assets/images/user0.png',
      timeAgo: '10 min',
      imageUrl: 'assets/images/post5.jpg',
    ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(218, 228, 237, 1),
      body: ListView.builder(
          cacheExtent: 200,
          controller: _scrollController,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _horiz();
            }
            return PostTile(post: postsList[index - 1], index: index - 1);
          }),
    );
  }
}
