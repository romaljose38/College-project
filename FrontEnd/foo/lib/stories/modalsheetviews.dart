import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:foo/test_cred.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:foo/models.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foo/landing_page.dart';
import 'package:foo/test_cred.dart';
import 'package:hive/hive.dart';
import 'package:foo/custom_overlay.dart';

import 'dart:convert';

class ModalSheetContent extends StatefulWidget {
  final Story story;

  ModalSheetContent({this.story});

  @override
  _ModalSheetContentState createState() => _ModalSheetContentState();
}

class _ModalSheetContentState extends State<ModalSheetContent>
    with SingleTickerProviderStateMixin {
  bool _seenUsers = true;
  PageController _pageController;
  AnimationController _animationController;

  @override
  initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 100));
    _pageController = PageController();
  }

  @override
  dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.story.viewedUsers.forEach((element) {
      print(element.username);
    });
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(horizontal: 15.0),
      height: 400,
      // color: Colors.red,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 60,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 30.0),
                    child: Text(
                      _seenUsers ? "Views" : "Comments",
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  Spacer(),
                  IconButton(
                      icon: Icon(Icons.message,
                          color: _seenUsers ? Colors.grey : Colors.green),
                      onPressed: () {
                        if (_seenUsers == true) {
                          _pageController.nextPage(
                              duration: Duration(milliseconds: 500),
                              curve: Curves.easeIn);
                        } else {
                          _pageController.previousPage(
                              duration: Duration(milliseconds: 500),
                              curve: Curves.easeIn);
                        }
                        setState(() {
                          _seenUsers = !_seenUsers;
                        });
                      }),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.grey),
                    onPressed: _submitDeleteHandler,
                  ),
                  SizedBox(width: 20),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                  controller: _pageController,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    seenUsersListView(widget.story.viewedUsers),
                    repliedUsersListView(widget.story.comments),
                  ]),
              // child:
              //     _seenUsers ? seenUsersListView() : repliedUsersListView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget seenUsersListView(List<StoryUser> storyViewers) {
    return ListView.builder(
      itemCount: storyViewers.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                CachedNetworkImageProvider(storyViewers[index].profilePicture),
            //'https://image.cnbcfm.com/api/v1/image/105753692-1550781987450gettyimages-628353178.jpeg?v=1550782124'),
          ),
          title: Text(storyViewers[index].username),
          subtitle: Text(timeago.format(storyViewers[index].viewedTime)),
        );
      },
    );
  }

  Widget repliedUsersListView(List<StoryComment> comments) {
    return ListView.builder(
      itemCount: comments.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                CachedNetworkImageProvider(comments[index].profilePicture),
            //'https://image.cnbcfm.com/api/v1/image/105753692-1550781987450gettyimages-628353178.jpeg?v=1550782124'),
          ),
          title: Text(comments[index].username),
          subtitle: Text(comments[index].comment),
        );
      },
    );
  }

  Future<void> _submitDeleteHandler() async {
    Map<String, String> deleteReq = {
      'id': widget.story.storyId.toString(),
    };

    Uri url = Uri.http(localhost, 'api/story_delete', deleteReq);

    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        SharedPreferences _prefs = await SharedPreferences.getInstance();
        int userId = _prefs.getInt('id');
        var myBox = Hive.box('MyStories');
        UserStoryModel myStoryUser = myBox.get(userId);
        myStoryUser.deleteOldStory(id: widget.story.storyId, userId: userId);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => LandingPage()),
        );
      } else {
        CustomOverlay overlay = CustomOverlay(
            context: context, animationController: _animationController);
        overlay.show("Sorry. Something went wrong.\n Please try again later.");
      }
    } catch (e) {
      CustomOverlay overlay = CustomOverlay(
          context: context, animationController: _animationController);
      overlay.show("Check your internet connection and try again later");
    }
  }
}

class ReplyModalSheet extends StatefulWidget {
  final int storyId;

  ReplyModalSheet({this.storyId});

  @override
  _ReplyModalSheetState createState() => _ReplyModalSheetState();
}

class _ReplyModalSheetState extends State<ReplyModalSheet> {
  TextEditingController _textController;
  SharedPreferences _prefs;

  @override
  initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15),
      color: Colors.transparent,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(
            Radius.circular(30.0),
            // topLeft: Radius.circular(30.0),
            // topRight: Radius.circular(30.0),
          ),
        ),
        child: Row(
          children: [
            Expanded(
                child: TextField(
              controller: _textController,
              autofocus: true,
              decoration: InputDecoration(
                hintStyle: GoogleFonts.sourceSansPro(),
                hintText: "Reply",
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.only(
                    left: 20, right: 8.0, top: 5.0, bottom: 8.0),
              ),
            )),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: _submitReplyHandler,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReplyHandler() async {
    _prefs = await SharedPreferences.getInstance();
    final username = _prefs.getString("username");
    final Map<String, dynamic> userReply = {
      'username': username,
      "id": widget.storyId,
      'comment': _textController.text,
    };

    var response = await http.post(
      Uri.http(localhost, 'api/add_story_comment'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8'
      },
      body: jsonEncode(userReply),
    );
    _textController.text = '';
    Navigator.pop(context);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Reply sent!")));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Sending failed!...")));
    }
  }
}
