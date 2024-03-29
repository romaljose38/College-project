// import 'dart:convert';
// import 'dart:ui';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flappy_search_bar/flappy_search_bar.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:hive/hive.dart';
// import 'package:ionicons/ionicons.dart';
// import 'package:foo/models.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../test_cred.dart';
// import 'feed_icons.dart' as icon;

// class ViewPostScreen extends StatefulWidget {
//   final Post post;
//   final int index;

//   ViewPostScreen({@required this.post, this.index});

//   @override
//   _ViewPostScreenState createState() => _ViewPostScreenState();
// }

// class _ViewPostScreenState extends State<ViewPostScreen>
//     with TickerProviderStateMixin {
//   TextEditingController _commentController = TextEditingController();
//   bool hasFetched = false;
//   List<Widget> commentsList = <Widget>[];
//   bool hasLiked = false;
//   int likeCount = 0;
//   int postId;
//   String userName;

//   @override
//   void initState() {
//     super.initState();
//     setUserName();
//     _getComments();
//     likeCount = widget.post.likeCount ?? 0;
//     hasLiked = widget.post.haveLiked ?? false;
//     postId = widget.post.postId ?? 0;
//   }

//   Future<void> setUserName() async {
//     SharedPreferences _prefs = await SharedPreferences.getInstance();
//     userName = _prefs.getString("username");

//     //For overlay(mention)
//     animationController = AnimationController(
//       vsync: this,
//       duration: Duration(milliseconds: 400),
//     );
//     animation =
//         Tween<double>(begin: 0.0, end: 1.0).animate(animationController);
//     //
//   }

//   @override
//   void dispose() {
//     animationController?.dispose();
//     _commentController?.dispose();
//     overlayEntry?.dispose();
//     super.dispose();
//   }

//   Future<void> _getComments() async {
//     var response = await http
//         .get(Uri.http(localhost, '/api/${widget.post.postId}/post_detail'));
//     if (response.statusCode == 200) {
//       var respJson = jsonDecode(utf8.decode(response.bodyBytes));
//       print(respJson);

//       respJson['comment_set'].forEach((e) {
//         var comment = jsonDecode(e['comment']);

//         setState(() {
//           commentsList.insert(
//               0,
//               _buildComment(Comment(
//                   comment: comment,
//                   userdpUrl: widget.post.userDpUrl,
//                   username: e['user'])));
//         });
//       });
//     }
//     setState(() {
//       hasFetched = true;
//     });
//   }

//   // Future<void> likePost() async {
//   //   print(hasLiked);
//   //   print(likeCount);
//   //   print(postId);
//   //   if (hasLiked) {
//   //     var response = await http.get(Uri.http(localhost, 'api/remove_like', {
//   //       'username': userName,
//   //       'id': postId.toString(),
//   //     }));
//   //     if (response.statusCode == 200) {
//   //       setState(() {
//   //         hasLiked = false;
//   //         likeCount -= 1;
//   //       });
//   //     }
//   //     updatePostInHive(postId, false);
//   //   } else {
//   //     var response = await http.get(Uri.http(localhost, '/api/add_like', {
//   //       'username': userName,
//   //       'id': postId.toString(),
//   //     }));
//   //     if (response.statusCode == 200) {
//   //       setState(() {
//   //         hasLiked = true;
//   //         likeCount += 1;
//   //       });
//   //     }
//   //     updatePostInHive(postId, true);
//   //   }
//   // }

//   // void updatePostInHive(int id, bool status) {
//   //   var feedBox = Hive.box("Feed");
//   //   Feed feed = feedBox.get('feed');
//   //   if ((id <= feed.posts.first.postId) & (id >= feed.posts.last.postId)) {
//   //     feed.updatePostStatus(id, status);
//   //     feed.save();
//   //   }
//   // }

//   Future<void> _addComment() async {
//     SharedPreferences _prefs = await SharedPreferences.getInstance();
//     String username = _prefs.getString("username");
//     String comment = _commentController.text;
//     List commentSplit = comment.split(' ');
//     List finalMentionList = [];
//     Map mapToSend = {};
//     print(commentSplit);
//     commentSplit.forEach((element) {
//       if (element != "") {
//         if (element[0] == "@") {
//           String stringToCheck = element.substring(1, element.length);
//           mapToSend[element] = true;
//           if (mentionList.contains(stringToCheck)) {
//             print("yep avdond");
//             finalMentionList.add(stringToCheck);
//           }
//         } else {
//           mapToSend[element] = false;
//         }
//       }
//     });
//     print(mapToSend);
//     print(finalMentionList);
//     var response =
//         await http.post(Uri.http(localhost, '/api/$username/add_comment'),
//             headers: <String, String>{
//               'Content-Type': 'application/json; charset=UTF-8',
//             },
//             body: jsonEncode({
//               'comment': mapToSend,
//               'post': widget.post.postId,
//               'mentions': finalMentionList,
//             }));

//     _commentController.text = "";
//     if (response.statusCode == 200) {
//       setState(() {
//         commentsList.insert(
//             0,
//             _buildComment(Comment(
//                 comment: mapToSend,
//                 userdpUrl: widget.post.userDpUrl,
//                 username: username)));
//       });
//     }
//   }

//   List<TextSpan> customizeComment(Map comments) {
//     List<TextSpan> children = [];
//     comments.forEach((key, val) {
//       if (val) {
//         children.add(TextSpan(
//           text: '$key ',
//           style: TextStyle(color: Colors.yellow),
//         ));
//       } else {
//         children.add(TextSpan(
//           text: '$key ',
//           // style: TextStyle(color: Colors.yellow),
//         ));
//       }
//     });
//     return children;
//   }

//   Widget _buildComment(Comment comment) {
//     return Padding(
//       padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
//       child: ListTile(
//         // tileColor: Colors.green,
//         leading: Container(
//           width: 35.0,
//           height: 35.0,
//           alignment: Alignment.center,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             border: Border.all(color: Colors.white, width: 1),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black45,
//                 offset: Offset(0, 2),
//                 blurRadius: 6.0,
//               ),
//             ],
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(2.0),
//             child: CircleAvatar(
//               child: ClipOval(
//                 child: Image(
//                   height: 35.0,
//                   width: 35.0,
//                   image: AssetImage(comment.userdpUrl),
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//           ),
//         ),
//         title: Text(
//           comment.username,
//           style: GoogleFonts.raleway(
//               color: Color.fromRGBO(91, 75, 95, 1),
//               fontWeight: FontWeight.w400,
//               fontSize: 14),
//         ),
//         subtitle: Padding(
//           padding: EdgeInsets.only(top: 5),
//           child: RichText(
//             text: TextSpan(
//               children: customizeComment(comment.comment),
//               style: GoogleFonts.raleway(
//                 fontSize: 13,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ),
//         trailing: IconButton(
//           icon: Icon(
//             Ionicons.heart_outline,
//             size: 23,
//           ),
//           color: Colors.grey,
//           onPressed: () => print('Like comment'),
//         ),
//       ),
//     );
//   }

//   //For mention
//   List mentionList = [];
//   bool overlayVisible = false;
//   Animation animation;
//   OverlayEntry overlayEntry;
//   AnimationController animationController;
//   int start = 0, end = 0;

//   Future<List<UserTest>> search(String search) async {
//     print(search);
//     var resp =
//         await http.get(Uri.http(localhost, '/api/users', {'name': search}));
//     var respJson = jsonDecode(resp.body);
//     print(respJson);

//     List<UserTest> returList = [];
//     respJson.forEach((e) {
//       print(e);
//       returList.add(UserTest(
//           name: e["username"],
//           id: e['id'],
//           f_name: e['f_name'],
//           l_name: e['l_name']));
//     });
//     return returList;
//   }

//   showOverlay(BuildContext context) {
//     overlayVisible = true;
//     OverlayState overlayState = Overlay.of(context);
//     overlayEntry = OverlayEntry(
//       builder: (context) => Scaffold(
//         backgroundColor: Colors.black.withOpacity(.3),
//         body: FadeTransition(
//           opacity: animation,
//           child: GestureDetector(
//             onTap: () {
//               animationController
//                   .reverse()
//                   .whenComplete(() => {overlayEntry.remove()});
//             },
//             child: Container(
//               // clipBehavior: Clip.antiAlias,
//               width: double.infinity,
//               height: double.infinity,
//               color: Colors.transparent,

//               child: Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Container(
//                       width: MediaQuery.of(context).size.width * 0.95,
//                       height: MediaQuery.of(context).size.height * 0.3,
//                       color: Colors.white,
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 20),
//                         child: SearchBar<UserTest>(
//                           minimumChars: 1,
//                           onSearch: search,
//                           onError: (err) {
//                             print(err);
//                             return Container();
//                           },
//                           onItemFound: (UserTest user, int index) {
//                             return GestureDetector(
//                               onTap: () {
//                                 print("$start, $end");
//                                 _commentController.text = insertAtChangedPoint(
//                                     '@${user.name}', start, end);
//                                 print(user.name);
//                                 mentionList.add(user.name);
//                               },
//                               child: ListTile(
//                                 title: Text(user.name),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//     animationController.addListener(() {
//       overlayState.setState(() {});
//     });
//     animationController.forward();
//     overlayState.insert(overlayEntry);
//   }

//   // String insertAtChangedPoint(String word) {
//   //   String text = _commentController.text;
//   //   TextSelection cursor = _commentController.selection;
//   //   String newText = text.replaceRange(cursor.start, cursor.end, word);
//   //   final wordLength = word.length;
//   //   _commentController.selection = cursor.copyWith(
//   //     baseOffset: cursor.start + wordLength,
//   //     extentOffset: cursor.start + wordLength,
//   //   );
//   //   return newText;
//   // }

//   String insertAtChangedPoint(String word, int start, int end) {
//     String text = _commentController.text;
//     String newText = text.replaceRange(start, end, word);
//     print(newText);
//     return newText;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color.fromRGBO(24, 4, 29, 1),
//       body: Column(
//         children: <Widget>[
//           Expanded(
//             child: SingleChildScrollView(
//               child: Column(
//                 children: [
//                   Stack(
//                     alignment: Alignment.center,
//                     children: [
//                       ClipRRect(
//                         borderRadius: BorderRadius.only(
//                             bottomRight: Radius.circular(25),
//                             bottomLeft: Radius.circular(25)),
//                         child: ImageFiltered(
//                           imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
//                           child: Container(
//                             padding: EdgeInsets.only(top: 10.0),
//                             width: double.infinity,
//                             height: 465.0,
//                             decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 // borderRadius: BorderRadius.only(
//                                 //     bottomLeft: Radius.circular(25),
//                                 //     bottomRight: Radius.circular(25)),
//                                 image: DecorationImage(
//                                   image: CachedNetworkImageProvider(
//                                       widget.post.postUrl),
//                                   fit: BoxFit.cover,
//                                 )),
//                           ),
//                         ),
//                       ),
//                       Container(
//                         padding: EdgeInsets.only(top: 10.0),
//                         width: double.infinity,
//                         height: 471.0,
//                         decoration: BoxDecoration(
//                           color: Colors.black.withOpacity(.3),
//                           borderRadius: BorderRadius.circular(25.0),
//                         ),
//                         child: Column(
//                           children: <Widget>[
//                             Padding(
//                               padding: EdgeInsets.symmetric(vertical: 10.0),
//                               child: Column(
//                                 children: <Widget>[
//                                   Row(
//                                     mainAxisAlignment:
//                                         MainAxisAlignment.spaceBetween,
//                                     children: <Widget>[
//                                       IconButton(
//                                         icon: Icon(
//                                           Icons.arrow_back,
//                                           color: Colors.white,
//                                         ),
//                                         iconSize: 20.0,
//                                         color: Colors.black,
//                                         onPressed: () => Navigator.pop(context),
//                                       ),
//                                       Container(
//                                         width: 30.0,
//                                         height: 30.0,
//                                         decoration: BoxDecoration(
//                                           shape: BoxShape.circle,
//                                           boxShadow: [
//                                             BoxShadow(
//                                               color: Colors.black45,
//                                               offset: Offset(0, 2),
//                                               blurRadius: 6.0,
//                                             ),
//                                           ],
//                                         ),
//                                         child: CircleAvatar(
//                                           child: ClipOval(
//                                             child: Image(
//                                               height: 50.0,
//                                               width: 50.0,
//                                               image: AssetImage(
//                                                   widget.post.userDpUrl),
//                                               fit: BoxFit.cover,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                       IconButton(
//                                         icon: Icon(icon.Feed.colon),
//                                         color: Colors.white,
//                                         onPressed: () => print('More'),
//                                       ),
//                                     ],
//                                   ),
//                                   InkWell(
//                                     onDoubleTap: () => print('Like post'),
//                                     child: Container(
//                                       height: 330,
//                                       width: double.infinity,
//                                       decoration: BoxDecoration(
//                                         color: Colors.white.withOpacity(.3),
//                                         borderRadius: BorderRadius.circular(25),
//                                       ),
//                                       margin:
//                                           EdgeInsets.fromLTRB(18, 10, 18, 5),
//                                       child: AspectRatio(
//                                         aspectRatio: 4 / 5,
//                                         child: Hero(
//                                           tag: "profile_${widget.index}",
//                                           child: Container(
//                                             decoration: BoxDecoration(
//                                               borderRadius:
//                                                   BorderRadius.circular(25.0),
//                                               boxShadow: [
//                                                 BoxShadow(
//                                                   color: Colors.black45,
//                                                   offset: Offset(0, 3),
//                                                   blurRadius: 8.0,
//                                                 ),
//                                               ],
//                                               image: DecorationImage(
//                                                 image:
//                                                     CachedNetworkImageProvider(
//                                                         widget.post.postUrl),
//                                                 fit: BoxFit.contain,
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   Padding(
//                                     padding:
//                                         EdgeInsets.symmetric(horizontal: 20.0),
//                                     child: Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceBetween,
//                                         children: <Widget>[
//                                           //action buttons if needed
//                                         ]),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 10.0),
//                   Container(
//                     width: double.infinity,
//                     decoration: BoxDecoration(
//                       color: Color.fromRGBO(24, 4, 29, 1),
//                     ),
//                     child: (hasFetched)
//                         ? Column(
//                             children: (commentsList == [])
//                                 ? [
//                                     Text("No comments",
//                                         style: TextStyle(color: Colors.white))
//                                   ]
//                                 : commentsList,
//                           )
//                         : Center(
//                             child: CircularProgressIndicator(
//                               backgroundColor: Colors.white,
//                               strokeWidth: 1,
//                             ),
//                           ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           Container(
//               height: 40,
//               margin: EdgeInsets.fromLTRB(10, 10, 10, 5),
//               decoration: BoxDecoration(
//                 // backgroundBlendMode: BlendMode.clear,
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(50),
//               ),
//               child: Row(
//                 children: [
//                   Container(
//                     padding: EdgeInsets.all(5),
//                     decoration: BoxDecoration(shape: BoxShape.circle),
//                     child: CircleAvatar(
//                       child: ClipOval(
//                         child: Image(
//                           height: 35.0,
//                           width: 35.0,
//                           image: AssetImage(widget.post.userDpUrl),
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: TextField(
//                       controller: _commentController,
//                       cursorColor: Colors.black,
//                       decoration: InputDecoration(
//                         hintText: "Add a comment",
//                         hintStyle: GoogleFonts.raleway(fontSize: 12),
//                         contentPadding: EdgeInsets.fromLTRB(10, 5, 5, 10),
//                         focusedBorder: InputBorder.none,
//                         suffix: InkWell(
//                           child: Text("@",
//                               style:
//                                   TextStyle(color: Colors.black, fontSize: 25)),
//                           onTap: () {
//                             var cursor = _commentController.selection;
//                             start = cursor.start;
//                             end = cursor.end;
//                             showOverlay(context);
//                           },
//                         ),
//                       ),
//                     ),
//                   ),
//                   Container(
//                     padding: EdgeInsets.all(5),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       shape: BoxShape.circle,
//                     ),
//                     child: CircleAvatar(
//                         child: IconButton(
//                       icon: Icon(Ionicons.paper_plane, size: 16),
//                       onPressed: _addComment,
//                     )),
//                   ),
//                 ],
//               )),
//         ],
//       ),
//     );
//   }
// }

// class UserTest {
//   final String name;
//   final String l_name;
//   final String f_name;
//   final int id;
//   UserTest({this.name, this.id, this.l_name, this.f_name});
// }
