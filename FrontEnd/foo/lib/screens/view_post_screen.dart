import 'dart:ui';

import 'package:foo/screens/models/comment_model.dart';
import 'package:foo/screens/models/post_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';

import 'feed_icons.dart';

class ViewPostScreen extends StatefulWidget {
  final Post post;

  ViewPostScreen({@required this.post});

  @override
  _ViewPostScreenState createState() => _ViewPostScreenState();
}

class _ViewPostScreenState extends State<ViewPostScreen> {
  Widget _buildComment(int index) {
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
                  image: AssetImage(comments[index].authorImageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          comments[index].authorName,
          style: GoogleFonts.raleway(
              color: Color.fromRGBO(91, 75, 95, 1),
              fontWeight: FontWeight.w400,
              fontSize: 14),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 5),
          child: Text(comments[index].text,
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
                                  image: AssetImage(widget.post.imageUrl),
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
                          color: Colors.transparent,
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
                                        icon: Icon(Icons.arrow_back),
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
                                                  widget.post.authorImageUrl),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Feed.colon),
                                        color: Colors.black,
                                        onPressed: () => print('More'),
                                      ),
                                    ],
                                  ),
                                  InkWell(
                                    onDoubleTap: () => print('Like post'),
                                    child: Container(
                                      height: 330,
                                      width: double.infinity,
                                      margin:
                                          EdgeInsets.fromLTRB(18, 10, 18, 5),
                                      child: AspectRatio(
                                        aspectRatio: 4 / 5,
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
                                              image: AssetImage(
                                                  widget.post.imageUrl),
                                              fit: BoxFit.fitWidth,
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
                                                      Ionicons.heart_outline),
                                                  iconSize: 25.0,
                                                  onPressed: () =>
                                                      print('Like post'),
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
                                                  icon: Icon(
                                                      Ionicons.chatbox_outline),
                                                  iconSize: 25.0,
                                                  onPressed: () {
                                                    print('Chat');
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
                                          icon:
                                              Icon(Ionicons.bookmarks_outline),
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
                    child: Column(
                      children: <Widget>[
                        _buildComment(0),
                        _buildComment(1),
                        _buildComment(2),
                        _buildComment(3),
                        _buildComment(4),
                      ],
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
                          image: AssetImage(comments[0].authorImageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      cursorColor: Colors.black,
                      decoration: InputDecoration(
                        hintText: "Add a comment",
                        hintStyle: GoogleFonts.raleway(fontSize: 12),
                        contentPadding: EdgeInsets.fromLTRB(10, 5, 5, 5),
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  // Container(
                  //   padding: EdgeInsets.all(5),
                  //   decoration: BoxDecoration(
                  //     color:Colors.white,
                  //     shape: BoxShape.circle,
                  //   ),
                  //   child: CircleAvatar(
                  //     child:
                  //      IconButton(
                  //       icon:Icon(Ionicons.paper_plane),
                  //       onPressed: (){},
                  //     )
                  //   ),
                  // ),
                ],
              )),
        ],
      ),
    );
  }
}
