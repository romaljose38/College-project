import 'dart:convert';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flappy_search_bar/flappy_search_bar.dart';
// import 'package:foo/screens/models/comment_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:foo/models.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../test_cred.dart';
import 'feed_icons.dart' as icon;

class ViewPostScreen extends StatefulWidget {
  final Post post;
  final int index;

  ViewPostScreen({@required this.post, this.index});

  @override
  _ViewPostScreenState createState() => _ViewPostScreenState();
}

class _ViewPostScreenState extends State<ViewPostScreen>
    with TickerProviderStateMixin {
  TextEditingController _commentController = TextEditingController();
  bool hasFetched = false;
  List<Widget> commentsList = <Widget>[];
  @override
  void initState() {
    super.initState();
    _getComments();

    //For overlay(mention)
    animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    animation =
        Tween<double>(begin: 0.0, end: 1.0).animate(animationController);
    //
  }

  @override
  void dispose() {
    animationController?.dispose();
    _commentController?.dispose();
    overlayEntry?.dispose();
    super.dispose();
  }

  Future<void> _getComments() async {
    var response = await http
        .get(Uri.http(localhost, '/api/${widget.post.postId}/post_detail'));
    if (response.statusCode == 200) {
      var respJson = jsonDecode(utf8.decode(response.bodyBytes));
      print(respJson);

      respJson['comment_set'].forEach((e) {
        setState(() {
          commentsList.insert(
              0,
              _buildComment(Comment(
                  comment: e['comment'],
                  userdpUrl: widget.post.userDpUrl,
                  username: e['user'])));
        });
      });
    }
    setState(() {
      hasFetched = true;
    });
  }

  _addComment() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    String username = _prefs.getString("username");
    String comment = _commentController.text;
    var response =
        await http.post(Uri.http(localhost, '/api/$username/add_comment'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode({
              'comment': comment,
              'post': widget.post.postId,
            }));
    _commentController.text = "";
    if (response.statusCode == 200) {
      setState(() {
        commentsList.insert(
            0,
            _buildComment(Comment(
                comment: comment,
                userdpUrl: widget.post.userDpUrl,
                username: username)));
      });
    }
  }

  Widget _buildComment(Comment comment) {
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: ListTile(
        // tileColor: Colors.green,
        leading: Container(
          width: 35.0,
          height: 35.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black45,
                offset: Offset(0, 2),
                blurRadius: 6.0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: CircleAvatar(
              child: ClipOval(
                child: Image(
                  height: 35.0,
                  width: 35.0,
                  image: AssetImage(comment.userdpUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          comment.username,
          style: GoogleFonts.raleway(
              color: Color.fromRGBO(91, 75, 95, 1),
              fontWeight: FontWeight.w400,
              fontSize: 14),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 5),
          child: Text(comment.comment,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.raleway(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
        trailing: IconButton(
          icon: Icon(
            Ionicons.heart_outline,
            size: 23,
          ),
          color: Colors.grey,
          onPressed: () => print('Like comment'),
        ),
      ),
    );
  }

  //For mention

  bool overlayVisible = false;
  Animation animation;
  OverlayEntry overlayEntry;
  AnimationController animationController;
  String ultimateString = '';
  String penultimateString = '';

  Future<List<UserTest>> search(String search) async {
    print(search);
    var resp =
        await http.get(Uri.http(localhost, '/api/users', {'name': search}));
    var respJson = jsonDecode(resp.body)['resp'];
    var list = jsonDecode(respJson);
    List<UserTest> returList = [];
    list.forEach((e) {
      print(e);
      returList.add(UserTest(name: e["fields"]["username"]));
    });
    print(returList);
    return returList;
  }

  showOverlay(BuildContext context) {
    overlayVisible = true;
    OverlayState overlayState = Overlay.of(context);
    overlayEntry = OverlayEntry(
      builder: (context) => Scaffold(
        backgroundColor: Colors.black.withOpacity(.3),
        body: FadeTransition(
          opacity: animation,
          child: GestureDetector(
            onTap: () {
              animationController
                  .reverse()
                  .whenComplete(() => {overlayEntry.remove()});
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.95,
                      height: MediaQuery.of(context).size.height * 0.3,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SearchBar<UserTest>(
                          minimumChars: 1,
                          onSearch: search,
                          onError: (err) {
                            print(err);
                            return Container();
                          },
                          onItemFound: (UserTest user, int index) {
                            return GestureDetector(
                              onTap: () {
                                _commentController.text = insertAtChangedPoint(
                                    ultimateString,
                                    penultimateString,
                                    '@${user.name}');
                                print(user.name);
                              },
                              child: ListTile(
                                title: Text(user.name),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    animationController.addListener(() {
      overlayState.setState(() {});
    });
    animationController.forward();
    overlayState.insert(overlayEntry);
  }

  int getPointOfInsertion(String ultimateString, String penultimateString) {
    for (int i = 0; i < ultimateString.length; i++) {
      String newString =
          ultimateString.substring(0, i) + ultimateString.substring(i + 1);
      if (newString == penultimateString) {
        return i;
      }
    }
    return -1;
  }

  String insertAtChangedPoint(
      String ultimateString, String penultimateString, String word) {
    int position = getPointOfInsertion(ultimateString, penultimateString);
    String newString = ultimateString.substring(0, position).trimRight() +
        ' $word ' +
        ultimateString.substring(position).trimLeft();
    return newString;
  }

  //

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(24, 4, 29, 1),
      body: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(25),
                            bottomLeft: Radius.circular(25)),
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: EdgeInsets.only(top: 10.0),
                            width: double.infinity,
                            height: 465.0,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                // borderRadius: BorderRadius.only(bottomLeft: Radius.circular(25),bottomRight: Radius.circular(25)),
                                image: DecorationImage(
                                  image: CachedNetworkImageProvider(
                                      widget.post.postUrl),
                                  fit: BoxFit.cover,
                                )),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 10.0),
                        width: double.infinity,
                        height: 471.0,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(.3),
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        child: Column(
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 10.0),
                              child: Column(
                                children: <Widget>[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      IconButton(
                                        icon: Icon(
                                          Icons.arrow_back,
                                          color: Colors.white,
                                        ),
                                        iconSize: 20.0,
                                        color: Colors.black,
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                      Container(
                                        width: 30.0,
                                        height: 30.0,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
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
                                              image: AssetImage(
                                                  widget.post.userDpUrl),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(icon.Feed.colon),
                                        color: Colors.white,
                                        onPressed: () => print('More'),
                                      ),
                                    ],
                                  ),
                                  InkWell(
                                    onDoubleTap: () => print('Like post'),
                                    child: Container(
                                      height: 330,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(.3),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      margin:
                                          EdgeInsets.fromLTRB(18, 10, 18, 5),
                                      child: AspectRatio(
                                        aspectRatio: 4 / 5,
                                        child: Hero(
                                          tag: "profile_${widget.index}",
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(25.0),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black45,
                                                  offset: Offset(0, 3),
                                                  blurRadius: 8.0,
                                                ),
                                              ],
                                              image: DecorationImage(
                                                image:
                                                    CachedNetworkImageProvider(
                                                        widget.post.postUrl),
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 20.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Row(
                                              children: <Widget>[
                                                IconButton(
                                                  icon: Icon(
                                                    Ionicons.heart_outline,
                                                    color: Colors.white,
                                                  ),
                                                  iconSize: 25.0,
                                                  onPressed: () =>
                                                      print('Like post'),
                                                ),
                                                Text(
                                                  '2,515',
                                                  style: TextStyle(
                                                    fontSize: 12.0,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(width: 20.0),
                                            Row(
                                              children: <Widget>[
                                                IconButton(
                                                  icon: Icon(
                                                      Ionicons.chatbox_outline,
                                                      color: Colors.white),
                                                  iconSize: 25.0,
                                                  onPressed: () {
                                                    print('Chat');
                                                  },
                                                ),
                                                Text(
                                                  '350',
                                                  style: TextStyle(
                                                      fontSize: 12.0,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Ionicons.bookmarks_outline,
                                            color: Colors.white,
                                          ),
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
                    ],
                  ),
                  SizedBox(height: 10.0),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(24, 4, 29, 1),
                    ),
                    child: (hasFetched)
                        ? Column(
                            children: (commentsList == [])
                                ? [Text("waiting")]
                                : commentsList,
                          )
                        : Center(
                            child: CircularProgressIndicator(
                              backgroundColor: Colors.white,
                              strokeWidth: 1,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          Container(
              height: 40,
              margin: EdgeInsets.fromLTRB(10, 10, 10, 5),
              decoration: BoxDecoration(
                // backgroundBlendMode: BlendMode.clear,
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(shape: BoxShape.circle),
                    child: CircleAvatar(
                      child: ClipOval(
                        child: Image(
                          height: 35.0,
                          width: 35.0,
                          image: AssetImage(widget.post.userDpUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                        controller: _commentController,
                        cursorColor: Colors.black,
                        decoration: InputDecoration(
                          hintText: "Add a comment",
                          hintStyle: GoogleFonts.raleway(fontSize: 12),
                          contentPadding: EdgeInsets.fromLTRB(10, 5, 5, 5),
                          focusedBorder: InputBorder.none,
                          suffix: InkWell(
                            child: Text("@",
                                style: TextStyle(
                                    color: Colors.black, fontSize: 30)),
                            onTap: () {
                              showOverlay(context);
                            },
                          ),
                        ),
                        onChanged: (value) {
                          penultimateString = ultimateString;
                          ultimateString = value;
                        }),
                  ),
                  Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                        child: IconButton(
                      icon: Icon(Ionicons.paper_plane),
                      onPressed: _addComment,
                    )),
                  ),
                ],
              )),
        ],
      ),
    );
  }
}

class UserTest {
  final String name;
  UserTest({this.name});
}
