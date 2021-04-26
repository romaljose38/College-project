import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:foo/chat/render.dart';
import 'package:foo/chat/socket.dart';
import 'package:foo/colour_palette.dart';
import 'package:foo/profile/profile.dart';
import 'package:foo/screens/feed_screen.dart';
import 'package:foo/upload_screen.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  AnimationController animationController;
  Animation animation;
  OverlayEntry overlayEntry;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: Duration(microseconds: 200),
    );
    animation =
        Tween<double>(begin: 0.0, end: 1.0).animate(animationController);
  }

  int _page = 0;

  showOverlay(BuildContext context) {
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
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    InkWell(
                      onTap: () {},
                      child: Column(
                        children: [
                          IconButton(
                            icon: Icon(
                              Ionicons.image_outline,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: () {},
                          ),
                          Text(
                            "Image",
                            style: GoogleFonts.raleway(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {},
                      child: Column(
                        children: [
                          IconButton(
                            icon: Icon(
                              Ionicons.videocam_outline,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: () {},
                          ),
                          Text(
                            "Video",
                            style: GoogleFonts.raleway(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {},
                      child: Column(
                        children: [
                          IconButton(
                            icon: Icon(
                              Ionicons.camera_outline,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: () {},
                          ),
                          Text(
                            "Camera",
                            style: GoogleFonts.raleway(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 25,
                            ),
                          ),
                        ],
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
                showOverlay(context);
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (_) => UploadScreen(),
                //   ),
                // );
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
    );
  }
}
