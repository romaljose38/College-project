import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foo/chat/render.dart';
import 'package:foo/chat/socket.dart';
import 'package:foo/colour_palette.dart';
import 'package:foo/profile/profile.dart';
import 'package:foo/screens/feed_screen.dart';
import 'package:foo/screens/search_screen.dart';
import 'package:foo/upload_screens/image_upload_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:foo/upload_screens/video_upload_screen.dart';
import 'package:image_picker/image_picker.dart';

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
  ImagePicker _picker = ImagePicker();

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

  // function that picks an image from the gallery
  Future<void> _getImage() async {
    FilePickerResult result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null) {
      File _image = File(result.files.single.path);

      animationController.reverse().whenComplete(() {
        overlayVisible = false;
        overlayEntry.remove();
      });

      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImageUploadScreen(
              mediaInserted: _image,
            ),
          ));
    }
  }
  //

  //Function that picks up a video from the gallery

  Future<void> _getVideo() async {
    FilePickerResult result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );
    if (result != null) {
      File _video = File(result.files.single.path);

      animationController.reverse().whenComplete(() {
        overlayVisible = false;
        overlayEntry.remove();
      });

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => VideoUploadScreen(
                    mediaInserted: _video,
                  )));
    }
  }

  //

  // Function that takes an image using the camera

  Future<void> _takePic() async {
    File _image;

    final pickedFile = await _picker.getImage(source: ImageSource.camera);
    _image = File(pickedFile.path);

    if (_image != null) {
      animationController.reverse().whenComplete(() {
        overlayVisible = false;
        overlayEntry.remove();
      });

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ImageUploadScreen(
                    mediaInserted: _image,
                  )));
    }
  }

  //

  // To exit the overlay on back press

  bool overlayVisible = false;

  Future<bool> onBackPress() async {
    if (overlayVisible == true) {
      animationController.reverse().whenComplete(() {
        overlayVisible = false;
        overlayEntry.remove();
      });
    } else if (_page == 0) {
      //0th _page is home(feed)
      SystemNavigator.pop(); //Exits the app
    } else {
      setState(() {
        _page = 0;
      });
    }

    return Future.value(false);
  }

  //

  int _page = 0;

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
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    InkWell(
                      onTap: _getImage,
                      child: Column(
                        children: [
                          Icon(
                            Ionicons.image_outline,
                            color: Colors.white,
                            size: 30,
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
                      onTap: _getVideo,
                      splashFactory: InkRipple.splashFactory,
                      child: Column(
                        children: [
                          Icon(
                            Ionicons.videocam_outline,
                            color: Colors.white,
                            size: 30,
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
                      onTap: _takePic,
                      child: Column(
                        children: [
                          Icon(
                            Ionicons.camera_outline,
                            color: Colors.white,
                            size: 30,
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
      SearchScreen(),
      Profile(),
      Scaffold()
    ];
    return Scaffold(
      backgroundColor: Palette.lavender,
      body: WillPopScope(
        onWillPop: onBackPress,
        child: pages[_page],
      ),
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
