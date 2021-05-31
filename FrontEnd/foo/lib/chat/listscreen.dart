import 'dart:convert';

import 'package:flappy_search_bar/flappy_search_bar.dart';
import 'package:flappy_search_bar/search_bar_style.dart';
import 'package:flutter/material.dart';
import 'package:foo/chat/chatscreen.dart';
import 'package:foo/models.dart';
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

  showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, tester) {
          return Container(
            height: 300,
            child: Column(
              children: [
                Container(
                  child: Text(
                    "Settings",
                    style: GoogleFonts.lato(
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  margin: EdgeInsets.fromLTRB(20, 20, 0, 8),
                ),
                Divider(),
                Container(
                  // height: 70,
                  width: double.infinity,
                  child: Row(
                    children: [
                      Spacer(),
                      Text("Hide last seen for everyone",
                          style: GoogleFonts.openSans(
                            fontSize: 16,
                          )),
                      Spacer(flex: 4),
                      Switch(
                        value: hidingLastSeen,
                        onChanged: (val) => changePreferences(val, tester),
                      ),
                      Spacer(),
                    ],
                  ),
                ),
                Divider(),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: SafeArea(
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
                        icon: Icon(isSearching
                            ? Ionicons.chatbox_outline
                            : Icons.search),
                        onPressed: () {
                          if (!isSearching) {
                            _animationController
                                .forward()
                                .whenComplete(() => setState(() {
                                      isSearching = true;
                                    }));
                          } else {
                            _animationController
                                .reverse()
                                .whenComplete(() => setState(() {
                                      isSearching = false;
                                    }));
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
                child: isSearching ? searchBar() : tiles(),
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
  UserTest({this.name, this.id, this.lname, this.fname});
}

Future<List<UserTest>> search(String search) async {
  print(search);
  var resp =
      await http.get(Uri.http(localhost, '/api/users', {'name': search}));
  var respJson = jsonDecode(resp.body);
  print(respJson);

  List<UserTest> returList = [];
  respJson.forEach((e) {
    print(e);
    returList.add(UserTest(
        name: e["username"],
        id: e['id'],
        fname: e['f name'],
        lname: e['l_name']));
  });
  print(returList);
  return returList;
}

class SearchTile extends StatelessWidget {
  final UserTest user;

  SearchTile({this.user});

  Future<void> handleChat(context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var threadBox = Hive.box("Threads");
    var curUser = prefs.getString('username');
    String threadName = "${prefs.getString('username')}_${user.name}";

    Thread thread;
    if (threadBox.containsKey(threadName)) {
      thread = threadBox.get(threadName);
    } else {
      thread = Thread(
        first: User(name: curUser),
        second: User(name: user.name),
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
                      image: AssetImage('assets/images/user4.png'),
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
                    Text(this.user.name,
                        style: GoogleFonts.raleway(
                            fontWeight: FontWeight.w600, fontSize: 17)),
                    SizedBox(height: 6),
                    Text(this.user.fname, style: TextStyle(fontSize: 13)),
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
