import 'dart:convert';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:foo/colour_palette.dart';
import 'package:foo/custom_overlay.dart';
import 'package:foo/models.dart';
import 'package:foo/notifications/notification_screen.dart';
import 'package:foo/profile/profile_test.dart';
import 'package:foo/screens/post_tile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ionicons/ionicons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../test_cred.dart';
import 'dart:math' as math;
import 'dart:io';
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
  ScrollController _scrollController = ScrollController();
  SharedPreferences prefs;
  String curUser;
  int curUserId;
  int itemCount = 0;
  bool isConnected = false;
  GlobalKey<SliverAnimatedListState> listKey;
  bool hasRequested = false;
  double currentPos = 0;
  UserStoryModel myStory;
  List<Post> postsList = <Post>[];
  var myStoryList = [];
  AnimationController _animationController;
  AnimationController _tileAnimationController;

  String myProfPic;
  bool hasFetchedPic = false;
  //

  bool isStacked = false;
  //
  @override
  initState() {
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    _tileAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    listKey = GlobalKey<SliverAnimatedListState>();
    //_fetchStory();
    super.initState();
    _getMyProfPic();
    setInitialData();
    _checkAndDeleteOldStory(Duration(hours: 1));
    // _getNewPosts();
    //_getMyProfPic();

    _scrollController
      ..addListener(() {
        if (_scrollController.position.maxScrollExtent -
                _scrollController.position.pixels <=
            800) {
          print("max max max");
          if (!hasRequested) {
            getPreviousPosts();
          }
          //
        }
      });
  }

  getPreviousPosts() async {
    hasRequested = true;
    print(postsList);
    var response = await http.get(Uri.http(
        localhost,
        '/api/$curUser/get_previous_posts',
        {'id': postsList.last.postId.toString()}));
    var respJson = jsonDecode(utf8.decode(response.bodyBytes));

    respJson.forEach((e) {
      Post post = Post(
          username: e['user']['username'],
          postUrl: 'http://' + localhost + e['file'],
          userDpUrl: 'http://' + localhost + e['user']['dp'],
          postId: e['id'],
          userId: e['user']['id'],
          commentCount: e['comment_count'],
          caption: e['caption'],
          likeCount: e['likeCount'],
          haveLiked: e['hasLiked'],
          thumbNailPath: ((e['post_type'] == "aud" ||
                  e['post_type'] == "aud_blurred" ||
                  e['post_type'] == "vid")
              ? (e['thumbnail'] == ''
                  ? ""
                  : 'http://' + localhost + e['thumbnail'])
              : ""),
          type: e['post_type']);
      int index = postsList.length - 1;
      listKey.currentState.insertItem(index);
      postsList.add(post);
      setState(() {
        itemCount += 1;
        // postsList = postsList;
      });
    });
    hasRequested = false;
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _tileAnimationController.dispose();
    // _nestedScrollController.dispose();
  }

  Future<void> _checkConnectionStatus() async {
    bool result = await DataConnectionChecker().hasConnection;

    if (result == true) {
      if (mounted) {
        setState(() {
          isConnected = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          isConnected = false;
        });
      }
    }
  }

  Future<void> setInitialData() async {
    prefs = await SharedPreferences.getInstance();
    curUser = prefs.getString("username");
    curUserId = prefs.getInt("id");
    _curMoodNotifier.value = prefs.getInt("curMood");
    var feedBox = Hive.box("Feed");
    Feed feed;
    String id;
    if (feedBox.containsKey("feed") && feedBox.get("feed").posts != null) {
      feed = feedBox.get("feed");
      if (feed.posts.length > 0) {
        id = feed.posts.first.postId.toString();
        for (int i = feed.posts.length - 1; i >= 0; i--) {
          listKey.currentState
              .insertItem(0, duration: Duration(milliseconds: 100));
          postsList.insert(0, feed.posts[i]);
        }
        setState(() {
          itemCount += postsList.length;
        });
      }
    } else {
      feed = Feed();
      id = "null";
      await feedBox.put('feed', feed);
    }
    await _checkConnectionStatus();
    if (isConnected) {
      var response = await http
          .get(Uri.http(localhost, '/api/$curUser/posts', {"id": (id ?? '0')}));
      var respJson = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        respJson.reversed.toList().forEach((e) {
          Post post = Post(
              username: e['user']['username'],
              postUrl: 'http://' + localhost + e['file'],
              userDpUrl: 'http://' + localhost + e['user']['dp'],
              postId: e['id'],
              commentCount: e['comment_count'],
              caption: e['caption'],
              userId: e['user']['id'],
              likeCount: e['likeCount'],
              haveLiked: e['hasLiked'],
              thumbNailPath: ((e['post_type'] == "aud" ||
                      e['post_type'] == "aud_blurred" ||
                      e['post_type'] == "vid")
                  ? (e['thumbnail'] == ''
                      ? ""
                      : 'http://' + localhost + e['thumbnail'])
                  : ""),
              type: e['post_type']);

          if (feed.isNew(e['id'])) {
            listKey.currentState.insertItem(0);
            postsList.insert(0, post);
            //feed.addPost(post);

            setState(() {
              itemCount += 1;
            });
          }
          feed.addPost(post);
          feed.save();
        });
      }
    }
  }

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

  Future<String> _getMyProfPic() async {
    prefs = await SharedPreferences.getInstance();
    var pic =
        (await getApplicationDocumentsDirectory()).path + '/images/dp/dp.jpg';
    if (!File(pic).existsSync()) {
      String url = 'http://$localhost' + prefs.getString('dp');
      var response = await http.get(Uri.parse(url));

      try {
        File file = File(pic);
        await file.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes);
      } catch (e) {
        print(e);
      }
    }
    setState(() {
      myProfPic = pic;
      hasFetchedPic = true;
    });
    return pic;
  }

  Widget _newHoriz() {
    return ValueListenableBuilder(
        valueListenable: Hive.box('MyStories').listenable(),
        builder: (context, box, widget) {
          // List<UserStoryModel> seenStoryList = <UserStoryModel>[];
          // List<UserStoryModel> unSeenStoryList = <UserStoryModel>[];

          var boxList = box.values.toList();
          var seenList = [];
          var unSeenList = [];
          var myStoryList = [];
          //_getCurrentStoryViewer();

          if (curUserId != null) {
            for (int item = 0; item < boxList.length; item++) {
              print("USERID = ${box.get(boxList[item].userId).stories}");
              if (boxList[item].userId == curUserId) {
                myStory = boxList[item];
              } else {
                if (boxList[item].stories.length > 0) {
                  if (boxList[item].hasUnSeen() == -1) {
                    seenList.add(boxList[item]);
                  } else {
                    unSeenList.add(boxList[item]);
                  }
                }
              }
            }
          }
          // myStoryList = boxList.where((x) => x.username != curUser).toList();
          seenList
              .sort((a, b) => b.timeOfLastStory.compareTo(a.timeOfLastStory));
          unSeenList
              .sort((a, b) => b.timeOfLastStory.compareTo(a.timeOfLastStory));
          myStoryList = [...unSeenList, ...seenList];

          return Container(
            width: double.infinity,
            height: 120.0,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              //itemCount: pst.stories.length + 1,
              itemCount: myStoryList.length + 1, //myStoryList.length + 1,
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  return Column(
                    children: [
                      hasFetchedPic
                          ? StoryUploadPick(
                              myStory: myStory, myProfPic: myProfPic)
                          : SizedBox(
                              width: 80,
                              height: 80,
                              child: Center(
                                child: SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1,
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.green),
                                    )),
                              ),
                            ),

                      //StoryUploadPick(myStory: myStory, myProfPic: myProfPic),
                      SizedBox(
                        width: 80,
                        child: Text(
                          "Momentos",
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                }
                return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => StoryBuilder(
                                  myStoryList: myStoryList,
                                  initialPage: index - 1,
                                  //profilePic: pst.stories,
                                )),
                      );
                    },
                    child: Column(
                      children: [
                        Container(
                          margin:
                              EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: myStoryList[index - 1].hasUnSeen() != -1
                                  ? [
                                      Color.fromRGBO(250, 87, 142, 1),
                                      Color.fromRGBO(202, 136, 18, 1),
                                      Color.fromRGBO(253, 167, 142, 1),
                                    ]
                                  : [
                                      Color.fromRGBO(255, 255, 255, 1),
                                      Color.fromRGBO(190, 190, 190, 1),
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
                                        // image:
                                        //     AssetImage(pst.stories[index - 1]),
                                        image: CachedNetworkImageProvider(
                                          myStoryList[index - 1].dpUrl,
                                        ),
                                        //'https://img.republicworld.com/republic-prod/stories/promolarge/xxhdpi/32qfhrhvfuzpdiev_1597135847.jpeg?tr=w-758,h-433'),
                                        fit: BoxFit.cover,
                                      )),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 75,
                          child: Text(myStoryList[index - 1].username,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato()),
                        ),
                      ],
                    ));
              },
            ),
          );
        });
  }

  //The below function deletes stories that are older than a given period of time

  Future<void> _checkAndDeleteOldStory(Duration timePeriod) async {
    List<dynamic> boxList = Hive.box('MyStories').values.toList();
    for (int i = 0; i < boxList.length; i++) {
      print("Checking stories to delete");
      boxList[i].deleteOldStory(period: timePeriod);
    }
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
    var feedBox = Hive.box("Feed");
    var feed;
    var id;
    if (feedBox.containsKey("feed")) {
      feed = feedBox.get('feed');
      id = feed.posts.first.postId.toString();
    } else {
      feed = Feed();
      await feedBox.put("feed", feed);
      id = "null";
    }
    var response =
        await http.get(Uri.http(localhost, '/api/$curUser/posts', {"id": id}));
    var respJson = jsonDecode(utf8.decode(response.bodyBytes));
    print(respJson);
    respJson.reversed.toList().forEach((e) {
      Post post = Post(
          username: e['user']['username'],
          postUrl: 'http://' + localhost + e['file'],
          userDpUrl: 'http://' + localhost + e['user']['dp'],
          postId: e['id'],
          userId: e['user']['id'],
          commentCount: e['comment_count'],
          caption: e['caption'],
          likeCount: e['likeCount'],
          haveLiked: e['hasLiked'],
          thumbNailPath: ((e['post_type'] == "aud" ||
                  e['post_type'] == "aud_blurred" ||
                  e['post_type'] == "vid")
              ? (e['thumbnail'] == ''
                  ? ""
                  : 'http://' + localhost + e['thumbnail'])
              : ""),
          type: e['post_type']);

      if (feed.isNew(e['id'])) {
        setState(() {
          listKey.currentState.insertItem(0);
          postsList.insert(0, post);
        });

        setState(() {
          itemCount += 1;
          // postsList = postsList;
        });
      }
      feed.addPost(post);
      feed.save();
    });
  }

  // evict() async{
  //   await CachedNetworkImage.evictFromCa
  // }
  _updateMood() async {
    try {
      int curMood = _curMoodNotifier.value;
      int userId = prefs.getInt('id');
      http.Response response = await http.get(Uri.http(
          localhost,
          '/api/change_mood',
          {'user': userId.toString(), 'mood': curMood.toString()}));

      if (response.statusCode == 200) {
        prefs.setInt("curMood", curMood);
        return true;
      }
      _curMoodNotifier.value = prefs.getInt("curMood");
      return false;
    } catch (e) {
      print(e);
      _curMoodNotifier.value = prefs.getInt("curMood");

      return false;
    }
  }

  ValueNotifier _curMoodNotifier = ValueNotifier(0);
  _showMoodSelector(BuildContext context) {
    showModalBottomSheet(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        context: context,
        builder: (ctx) => StatefulBuilder(
              builder: (ctx, moodSetState) {
                return Container(
                    height: 320,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(children: [
                      Container(
                          margin: EdgeInsets.only(top: 40, bottom: 30),
                          child: Center(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "How are you ",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.merriweather(
                                  wordSpacing: 5,
                                  fontSize: 25,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 5),
                              RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                      text: "feeling today ",
                                      style: GoogleFonts.merriweather(
                                        wordSpacing: 5,
                                        fontSize: 25,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      children: [
                                        TextSpan(
                                            text: "?",
                                            style: GoogleFonts.lato(
                                                fontSize: 25,
                                                color: Colors.black,
                                                fontWeight: FontWeight.w600))
                                      ])
                                  // "feeling today?",
                                  // textAlign: TextAlign.center,
                                  // style: GoogleFonts.merriweather(
                                  //   wordSpacing: 5,
                                  //   fontSize: 25,
                                  //   fontWeight: FontWeight.w600,
                                  // ),
                                  ),
                            ],
                          ))),
                      Container(
                          child: Center(
                              child: getProperText(_curMoodNotifier.value))),
                      SizedBox(height: 10),
                      Expanded(
                        child: Row(
                          children: [
                            Spacer(),
                            emogiTile('😑', moodSetState, 1),
                            Spacer(),
                            emogiTile('😶', moodSetState, 2),
                            Spacer(),
                            emogiTile('😃', moodSetState, 3),
                            Spacer(),
                            emogiTile('😌', moodSetState, 4),
                            Spacer(),
                            emogiTile('😎', moodSetState, 5),
                            Spacer(),
                          ],
                        ),
                      ),
                      Divider(),
                      Container(
                        margin: EdgeInsets.only(top: 6, bottom: 14),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              // margin: EdgeInsets.fromLTRB(0, 0, 20, 0),
                            ),
                            GestureDetector(
                              onTap: () async {
                                bool status = await _updateMood();
                                CustomOverlay overlay = CustomOverlay(
                                    context: context,
                                    animationController: _animationController);
                                if (status) {
                                  overlay.show("Mood update", duration: 1);
                                  Navigator.pop(ctx);
                                } else {
                                  overlay.show(
                                      "Something went wrong please try again later",
                                      duration: 1);
                                  Navigator.pop(ctx);
                                }
                              },
                              child: Container(
                                // margin: EdgeInsets.only(left: 7),
                                child: Text(
                                  "Confirm",
                                  style: GoogleFonts.openSans(
                                    fontSize: 16,
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                alignment: Alignment.centerLeft,
                                // margin: EdgeInsets.fromLTRB(20, 0, 0, 0),
                              ),
                            ),
                          ],
                        ),
                      )
                    ]));
              },
            ));
  }

  getProperText(index) {
    switch (index) {
      case 1:
        return Text("IDK, Cursed or somethin!",
            style: TextStyle(color: Colors.red, fontSize: 14));
      case 2:
        return Text("Existential crisis",
            style: TextStyle(color: Colors.orange, fontSize: 14));
      case 3:
        return Text("O..k..a ..y",
            style: TextStyle(color: Colors.blueGrey, fontSize: 14));
      case 4:
        return Text("Happie",
            style: TextStyle(color: Colors.greenAccent, fontSize: 14));
      case 5:
        return Text("Ellarum dence kelii",
            style: TextStyle(color: Colors.green, fontSize: 14));
      default:
        return Text("Ayinu");
    }
  }

  emogiTile(String emogi, Function moodSet, int index) {
    bool selected = false;
    if (_curMoodNotifier.value == index) {
      selected = true;
    }
    return GestureDetector(
        onTap: () => moodSet(() {
              if (_curMoodNotifier.value == index) {
                _curMoodNotifier.value = 0;
              } else {
                _curMoodNotifier.value = index;
              }
            }),
        child: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: selected ? Colors.blue : Colors.white, width: 2)),
          child: Image.asset(Essentials.emojis[index],
              width: 28,
              height:
                  28), // child: Text(emogi, style: TextStyle(fontSize: 20))),
        ));
  }

  @override
  Widget build(BuildContext context) {
    var height = math.min(540.0, MediaQuery.of(context).size.height * .7);
    var heightFactor = (height - 58) / height;
    // evict();
    Essentials.width = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size(double.infinity, 60),
          child: Container(
              width: double.infinity,
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => NotificationScreen())),
                    child: Container(
                      margin: EdgeInsets.only(left: 15),
                      child: ValueListenableBuilder(
                          valueListenable:
                              Hive.box("Notifications").listenable(),
                          builder: (context, snapshot, child) {
                            var value = prefs?.getBool("hasNotif") ?? false;

                            return Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Ionicons.notifications_outline,
                                    size: 20,
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      height: 6,
                                      width: 6,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: value
                                              ? Colors.orange
                                              : Colors.transparent),
                                    ),
                                  ),
                                ]);
                          }),
                    ),
                  ),
                  Text(
                    "Flutter",
                    style: GoogleFonts.dancingScript(
                      color: Colors.purple,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  GestureDetector(
                    onLongPress: () => _showMoodSelector(context),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => Profile(
                              myProfile: true,
                            ))),
                    child: Container(
                      margin: EdgeInsets.only(right: 15),
                      child: hasFetchedPic
                          ? Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                image: DecorationImage(
                                  image: FileImage(
                                    File(myProfPic),
                                  ),
                                ),
                              ),
                            )
                          : SizedBox(
                              height: 30,
                              width: 30,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.green),
                              )),
                    ),
                  ),
                ],
              )),
        ),
        // extendBodyBehindAppBar: true,
        // extendBody: true,
        // backgroundColor: Color.fromRGBO(24, 4, 29, 1),
        // backgroundColor: Color.fromRGBO(218, 228, 237, 1),
        // floatingActionButtonLocation: FloatingActionButtonLocation.miniEndTop,
        // floatingActionButton: TextButton(
        //   child: Row(
        //     children: [
        //       GestureDetector(
        //         onTap: () {
        //           var feedBox = Hive.box("Feed");
        //           Feed feed = feedBox.get("feed");
        //           listKey.currentState.insertItem(0);
        //           postsList.insert(0, feed.posts[0]);
        //         },
        //         child: Text(
        //           "hoi",
        //           style: TextStyle(color: Colors.black, fontSize: 30),
        //         ),
        //       ),
        //       GestureDetector(
        //         onTap: () {
        //           if (isStacked) {
        //             _tileAnimationController
        //                 .reverse()
        //                 .whenComplete(() => setState(() {
        //                       isStacked = false;
        //                     }));
        //           } else {
        //             _tileAnimationController
        //                 .forward()
        //                 .whenComplete(() => setState(() {
        //                       isStacked = true;
        //                     }));
        //           }
        //         },
        //         child: Text(
        //           "anm",
        //           style: TextStyle(color: Colors.black, fontSize: 30),
        //         ),
        //       ),
        //     ],
        //   ),
        //   onPressed: () {},
        // ),
        backgroundColor: Colors.white,
        body: Container(
          // margin: EdgeInsets.only(bottom: 40),
          // padding: const EdgeInsets.only(bottom: 40),
          child: RefreshIndicator(
            triggerMode: RefreshIndicatorTriggerMode.anywhere,
            onRefresh: () async {
              await _getNewPosts();
              //_fetchStory();
              return true;
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: BouncingScrollPhysics(),
              slivers: [
                //SliverToBoxAdapter(child: _horiz()),
                SliverToBoxAdapter(child: _newHoriz()),
                SliverToBoxAdapter(child: SizedBox(height: 10)),

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
                        child: AnimatedBuilder(
                            animation: _tileAnimationController,
                            builder: (context, child) {
                              var val = _tileAnimationController.value;
                              var value = .08 * val;
                              return Align(
                                heightFactor: 1 - value,
                                alignment: Alignment.topCenter,
                                child: PostTile(
                                    key: ValueKey(postsList[index].postId),
                                    postsList: postsList,
                                    post: postsList[index],
                                    index: index,
                                    isLast: index == (postsList.length - 1)
                                        ? true
                                        : false),
                              );
                            }),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Essentials {
  static var width;
  static Map emojis = {
    1: "assets/emojis/very_sad.png",
    2: "assets/emojis/sad.png",
    3: "assets/emojis/normal.png",
    4: "assets/emojis/happy.png",
    5: "assets/emojis/very_happy.png",
  };
}
