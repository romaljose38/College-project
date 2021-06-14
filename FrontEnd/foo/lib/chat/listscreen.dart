import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:foo/chat/chatscreen.dart';
import 'package:foo/models.dart';
import 'package:foo/screens/feed_screen.dart';
import 'package:foo/search_bar/flappy_search_bar.dart';
import 'package:foo/search_bar/search_bar_style.dart';
import 'package:foo/test_cred.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:ionicons/ionicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chattile.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:foo/screens/feed_icons.dart' as doubleMoreVert;
import 'package:foo/custom_overlay.dart';

class ChatListScreen extends StatefulWidget {
  bool searchActive;
  Function toggleSearch;
  ChatListScreen({this.searchActive, this.toggleSearch});
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with TickerProviderStateMixin {
  bool isSearching = false;
  AnimationController _animationController;
  Animation _animation;
  SharedPreferences _prefs;

  @override
  void initState() {
    setPreferences();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 100));
    _animation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    super.initState();
  }

  Future<List<UserTest>> search(String search) async {
    var id = _prefs.getInt('id');
    var resp = await http.get(Uri.http(
        localhost, '/api/friends', {'name': search, 'id': id.toString()}));
    var respJson = jsonDecode(resp.body);
    print(respJson);

    List<UserTest> returList = [];
    respJson.forEach((e) {
      print(e);
      returList.add(UserTest(
          name: e["username"],
          id: e['id'],
          dp: e['dp'],
          fname: e['f_name'],
          lname: e['l_name']));
    });
    print(returList);
    return returList;
  }

  tiles() => ValueListenableBuilder(
      valueListenable: Hive.box("Threads").listenable(),
      builder: (context, box, widget) {
        List threads = box.values.toList() ?? [];

        if (threads.length >= 1) {
          threads.sort((a, b) {
            return b.lastAccessed.compareTo(a.lastAccessed);
          });
        }

        return ListView.builder(
            physics: BouncingScrollPhysics(),
            itemCount: threads.length,
            itemBuilder: (context, index) {
              return ChatTile(thread: threads[index]);
            });
      });

  searchBar() => FadeTransition(
        opacity: _animation,
        child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            child: SearchBar<UserTest>(
              loader: const Center(
                  child: CircularProgressIndicator(
                strokeWidth: 1,
                backgroundColor: Colors.purple,
              )),
              minimumChars: 1,
              onSearch: search,
              searchBarStyle: SearchBarStyle(
                borderRadius: BorderRadius.circular(10),
              ),
              onError: (err) {
                print(err);
                return Container();
              },
              onItemFound: (UserTest user, int index) {
                return SearchTile(user: user);
              },
            )),
      );

  bool hidingLastSeen;

  // showErrMessage() {
  //   CustomOverlay overlay = CustomOverlay(
  //       context: context, animationController: _animationController);
  //   overlay.show("Sorry. Something went wrong.\n Please try again later.");
  // }

  void setPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    String key = "general_hide_last_seen";
    if (_prefs.containsKey(key)) {
      setState(() {
        hidingLastSeen = _prefs.getBool(key);
      });
    } else {
      _prefs.setBool(key, false);
      setState(() {
        hidingLastSeen = false;
      });
    }
  }

  //Changes the preferences;
  Future<void> changePreferences(bool val, Function innerSetState) async {
    //String key = "am_i_hiding_last_seen_from_$otherUser";
    String key = 'general_hide_last_seen';

    String action = "";
    if (val) {
      action = "add";
    } else {
      action = "remove";
    }
    var id = _prefs.getInt('id');
    try {
      var response = await http.get(Uri.http(localhost,
          '/api/last_seen_general', {'id': id.toString(), 'action': action}));

      if (response.statusCode == 200) {
        _prefs.setBool(key, val);
        innerSetState(() {
          hidingLastSeen = val;
        });
      } else {
        CustomOverlay overlay = CustomOverlay(
            context: context, animationController: _animationController);
        overlay.show("Sorry. Something went wrong.\n Please try again later.");
      }
    } catch (e) {
      CustomOverlay overlay = CustomOverlay(
          context: context, animationController: _animationController);
      overlay.show("Sorry. Something went wrong.\n Please try again later.");
    }
  }

  Future<bool> clearAllThreads() async {
    bool shouldClear;
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text("Are you sure?",
                  style: GoogleFonts.lato(
                      fontWeight: FontWeight.w400, fontSize: 18)),
              content: Text("This action cannot be undone.",
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              actions: [
                TextButton(
                    child: Text("Yes"),
                    onPressed: () {
                      shouldClear = true;
                      Navigator.pop(context);
                    }),
                TextButton(
                    child: Text("No"),
                    onPressed: () {
                      shouldClear = false;
                      Navigator.pop(context);
                    })
              ],
            ));
    if (shouldClear == true) {
      Hive.box('Threads').clear();

      return true;
    } else {
      return false;
    }
  }

  showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
        topLeft: Radius.circular(15),
        topRight: Radius.circular(15),
      )),
      builder: (context) {
        return StatefulBuilder(builder: (context, tester) {
          return Container(
            height: 340,
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.symmetric(vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        margin: EdgeInsets.only(left: 7),
                        child: Text(
                          "Settings",
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        alignment: Alignment.centerLeft,
                        // margin: EdgeInsets.fromLTRB(20, 0, 0, 0),
                      ),
                      TextButton(
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        // margin: EdgeInsets.fromLTRB(0, 0, 20, 0),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(7, 0, 7, 15),
                  alignment: Alignment.centerLeft,
                  child: Text("General",
                      style: GoogleFonts.lato(
                          fontSize: 13, color: Colors.grey.shade500)),
                ),
                Container(
                    // height: 70,
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        TextButton(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Clear all chats",
                                    style: GoogleFonts.lato(
                                      fontSize: 16,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                    )),
                                SizedBox(height: 3),
                                Text(
                                    "Clears all chats. Media files will be retained.",
                                    style: GoogleFonts.lato(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    )),
                              ],
                            ),
                            onPressed: () async {
                              bool didDelete = await clearAllThreads();
                              if (didDelete) {
                                Navigator.pop(context);
                              }
                            }),
                      ],
                    )),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 7, vertical: 15),
                  alignment: Alignment.centerLeft,
                  child: Text("Preferences",
                      style: GoogleFonts.lato(
                          fontSize: 13, color: Colors.grey.shade500)),
                ),
                Container(
                  // height: 70,
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Hide last seen",
                                  style: GoogleFonts.lato(
                                    fontSize: 16,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  )),
                              SizedBox(height: 3),
                              Text("Hides your last seen from everyone",
                                  style: GoogleFonts.lato(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  )),
                            ],
                          ),
                          onPressed: () =>
                              changePreferences(!hidingLastSeen, tester)),
                      Checkbox(
                        value: hidingLastSeen,
                        onChanged: (val) => changePreferences(val, tester),
                        shape: CircleBorder(
                            side: BorderSide(color: Colors.black87, width: .7)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          print("in list screen");
          return Future.value(false);
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          extendBodyBehindAppBar: true,

          body: Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                padding: EdgeInsets.fromLTRB(20, 30, 10, 15),
                child: Row(
                  children: [
                    Text(
                      "Chat",
                      style: GoogleFonts.lato(
                        color: Color.fromRGBO(60, 82, 111, 1),
                        fontWeight: FontWeight.w600,
                        fontSize: 30,
                      ),
                    ),
                    Spacer(
                      flex: 3,
                    ),
                    IconButton(
                        icon: Icon((isSearching && widget.searchActive)
                            ? Ionicons.chatbox_outline
                            : Icons.search),
                        onPressed: () {
                          if (!isSearching) {
                            _animationController
                                .forward()
                                .whenComplete(() => setState(() {
                                      isSearching = true;
                                    }));
                            widget.toggleSearch(true);
                          } else {
                            _animationController
                                .reverse()
                                .whenComplete(() => setState(() {
                                      isSearching = false;
                                    }));
                            widget.toggleSearch(false);
                          }
                        }),
                    isSearching
                        ? Container()
                        : RotatedBox(
                            quarterTurns: 3,
                            child: IconButton(
                                icon: Icon(doubleMoreVert.Feed.colon),
                                onPressed: () => showSettings(context)),
                          ),
                  ],
                ),
              ),
              Expanded(
                child: widget.searchActive ? searchBar() : tiles(),
              ),
            ],
          ),

          //     )),
        ),
      ),
    );
  }
}

class UserTest {
  final String name;
  final String lname;
  final String fname;
  final int id;
  final String dp;
  UserTest({this.name, this.id, this.lname, this.fname, this.dp});
}

class SearchTile extends StatelessWidget {
  final UserTest user;

  SearchTile({this.user});

  Future<void> handleChat(context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var threadBox = Hive.box("Threads");
    var curUser = prefs.getString('username');
    String threadName = "${prefs.getString('username')}-${user.name}";

    Thread thread;
    if (threadBox.containsKey(threadName)) {
      thread = threadBox.get(threadName);
    } else {
      thread = Thread(
        first: User(name: curUser),
        second: User(
            name: user.name,
            dpUrl: user.dp,
            f_name: user.fname,
            l_name: user.lname),
      );
      thread.lastAccessed = DateTime.now();
      await threadBox.put(threadName, thread);
      thread.save();
    }
    Navigator.push(
      context,
      PageRouteBuilder(pageBuilder: (context, animation, secAnimation) {
        return ChatScreen(
          thread: thread,
          prefs: prefs,
        );
      }, transitionsBuilder: (context, animation, secAnimation, child) {
        return SlideTransition(
            position: Tween(begin: Offset(1, 0), end: Offset(0, 0))
                .animate(animation),
            child: child);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            print(user.id);
            handleChat(context);
          },
          child: Container(
            width: MediaQuery.of(context).size.width * .95,
            // margin: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              // borderRadius: BorderRadius.circular(20),
              // boxShadow: [
              //   BoxShadow(
              //     color: Palette.lavender,
              //     offset: Offset(0, 0),
              //     blurRadius: 7,
              //     spreadRadius: 1,
              //   )
              // ]
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  child: ClipOval(
                    child: Image(
                      height: 60.0,
                      width: 60.0,
                      image: CachedNetworkImageProvider(
                          'http://' + localhost + user.dp),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(
                  width: 15,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(this.user.fname + " " + this.user.lname,
                        maxLines: 2,
                        style: GoogleFonts.raleway(
                            fontWeight: FontWeight.w600, fontSize: 17)),
                    SizedBox(height: 6),
                  ],
                ),
              ],
            ),
          ),
        ),
        Divider(),
      ],
    );
  }
}
