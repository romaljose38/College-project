import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:foo/chat/render.dart';
import 'package:foo/chat/socket.dart';
import 'package:foo/colour_palette.dart';
import 'package:foo/main.dart';
import 'package:foo/profile/profile.dart';
import 'package:foo/screens/feed_screen.dart';
import 'package:foo/upload_screen.dart';
import 'package:ionicons/ionicons.dart';

class LandingPageProxy extends StatelessWidget {
  NotificationController controller = NotificationController();

  @override
  Widget build(BuildContext context) {
    return LandingPage();
  }
}

class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    List pages = [
      PageView(children: [FeedScreen(), ChatRenderer()]),
      Scaffold(),
      Profile(),
      Scaffold()
    ];
    return Scaffold(
      backgroundColor: Palette.lavender,
      body: pages[_page],
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: ClipOval(
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.2),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: IconButton(
              icon: Icon(Ionicons.add, color: Colors.black, size: 20),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UploadScreen(),
                  ),
                );
              },
            ),
          ),
        ),
      ),

      bottomNavigationBar: BottomAppBar(
          color: Colors.white,
          shape: CircularNotchedRectangle(),
          child: Container(
            // decoration: BoxDecoration(
            //   color:Colors.transparent
            // ),
            child: new Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                IconButton(
                    icon: Icon(Ionicons.home_outline,
                        size: 25, color: Colors.black),
                    disabledColor: Colors.green,
                    onPressed: () => setState(() => _page = 0)),
                IconButton(
                    icon: Icon(Ionicons.search_outline,
                        size: 25, color: Colors.black),
                    disabledColor: Colors.green,
                    onPressed: () => setState(() => _page = 1)),
                SizedBox(
                  width: 14,
                ),
                IconButton(
                    icon: Icon(Ionicons.person_outline,
                        size: 25, color: Colors.black),
                    disabledColor: Colors.green,
                    onPressed: () => setState(() => _page = 2)),
                IconButton(
                    icon: Icon(Ionicons.settings_outline,
                        size: 25, color: Colors.black),
                    disabledColor: Colors.green,
                    onPressed: () => setState(() => _page = 2)),
              ],
            ),
          )),
      // bottomNavigationBar: BottomNavigationBar(
      //   showSelectedLabels: false,
      //   showUnselectedLabels: false,
      //   items: [
      //     BottomNavigationBarItem(
      //         label: "",
      //         icon: Icon(Ionicons.home_outline, size: 25, color: Colors.black)),
      //     BottomNavigationBarItem(
      //         label: "",
      //         icon:Icon(Ionicons.search_outline, size: 25, color: Colors.black)),
      //     BottomNavigationBarItem(
      //         label: "",
      //         icon:Icon(Ionicons.person_outline, size: 25, color: Colors.black)),
      //     BottomNavigationBarItem(
      //         label: "",
      //         icon: Icon(Ionicons.settings_outline,
      //             size: 25, color: Colors.black)),
      //   ],
      //  onTap: (index) {
      //       setState(() {
      //         _page = index;
      //       });
      //     },
      // ),
    );
  }
}
// ChatRenderer()
