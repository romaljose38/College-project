import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foo/landing_page.dart';
import 'package:foo/test_cred.dart';
import 'package:http/http.dart' as http;
import 'package:foo/custom_overlay.dart';

class AudioUploadScreen extends StatefulWidget {
  File audio;

  AudioUploadScreen({this.audio});

  @override
  _AudioUploadScreenState createState() => _AudioUploadScreenState();
}

class _AudioUploadScreenState extends State<AudioUploadScreen>
    with TickerProviderStateMixin {
  TextEditingController captionController;
  AnimationController _animationController;

  bool hasImage = false;
  bool _isBlurred = false;
  File imageFile;
  bool uploading = false;

  //
  OverlayEntry _overlayEntry;
  AnimationController _overlayAnimationController;
  Animation _overlayAnimation;

  var percent;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 100));

    captionController = TextEditingController();

    //
    _overlayAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 100));
    _overlayAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(_overlayAnimationController);
  }

  @override
  void dispose() {
    captionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  showProgressOverlay() {
    OverlayState _state = Overlay.of(context);
    _overlayEntry = OverlayEntry(builder: (context) {
      return FadeTransition(
        opacity: _overlayAnimation,
        child: Scaffold(
          backgroundColor: Colors.black.withOpacity(.4),
          body: Center(
            child: Container(
              width: 100,
              height: 150,
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 100,
                        width: 100,
                        child: Center(
                          child: Text((percent ?? 0).toString(),
                              style: GoogleFonts.raleway(
                                  color: Colors.white, fontSize: 16)),
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                          backgroundColor: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    ],
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 15),
                    child: Text("Uploading..",
                        style: GoogleFonts.raleway(
                            color: Colors.white, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
    _overlayAnimationController
        .forward()
        .whenComplete(() => _state.insert(_overlayEntry));
  }

  Future<void> _upload(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int userId = prefs.getInt('id');

    var dio = Dio(BaseOptions(baseUrl: 'http://' + localhost));
    var formData = FormData.fromMap({
      'user_id': userId.toString(),
      'type': _isBlurred ? 'aud_blurred' : 'aud',
      'caption': captionController.text,
      'hasThumbnail': (imageFile == null) ? '0' : '1',
      'file': await MultipartFile.fromFile(widget.audio.path),
      'thumbnail':
          imageFile != null ? await MultipartFile.fromFile(imageFile.path) : "",
    });

    // var uri = Uri.http(
    //     localhost, '/api/post_upload'); //This web address has to be changed
    // var request = http.MultipartRequest('POST', uri)
    //   ..fields['user_id'] = userId.toString()
    //   ..fields['type'] = _isBlurred ? 'aud_blurred' : 'aud'
    //   ..fields['caption'] = captionController.text
    //   ..fields['hasThumbnail'] = (imageFile == null) ? '0' : '1'
    //   ..files.add(await http.MultipartFile.fromPath(
    //     'file',
    //     widget.audio.path,
    //   ));

    // if (imageFile != null) {
    //   formData.fields
    //       .add(MapEntry('thumbnail', await MultipartFile.fromFile(imageFile.path)));
    //   // request.files
    //   //     .add(await http.MultipartFile.fromPath('thumbnail', imageFile.path));
    // }
    CustomOverlay overlay = CustomOverlay(
        context: context, animationController: _animationController);
    showProgressOverlay();
    try {
      var response = await dio.post('/api/post_upload', data: formData,
          onSendProgress: (int sent, int total) {
        setState(() {
          percent = sent / total;
        });
      });

      // setState(() {
      //   uploading = true;
      // });

      if (response.statusCode == 200) {
        overlay.show("Upload successful");
        await _overlayAnimationController
            .reverse()
            .whenComplete(() => _overlayEntry.remove());
        Timer(
            Duration(seconds: 2),
            () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => LandingPage())));
      } else {
        overlay.show("Sorry. Upload Failed. \n Please try again later");
        await _overlayAnimationController
            .reverse()
            .whenComplete(() => _overlayEntry.remove());

        Timer(
            Duration(seconds: 2),
            () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => LandingPage())));
      }
    } catch (e) {
      overlay.show("Sorry. Upload Failed.\n Please try again later.");
      await _overlayAnimationController
          .reverse()
          .whenComplete(() => _overlayEntry.remove());

      Timer(
          Duration(seconds: 2),
          () => Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => LandingPage())));
    }
  }

  GestureDetector bottomSheetTile(
          String type, Color color, IconData icon, Function onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 70,
              width: 70,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: Colors.grey.shade600,
                size: 30,
              ),
            ),
            SizedBox(height: 8),
            Text(
              type,
              style: GoogleFonts.raleway(
                color: Color.fromRGBO(176, 183, 194, 1),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );

  showOverlay() {
    showModalBottomSheet(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        context: context,
        builder: (context) {
          return Container(
            height: 200,
            margin: EdgeInsets.fromLTRB(10, 20, 10, 0),
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Change Video Cover",
                        style: GoogleFonts.lato(
                            fontSize: 20, fontWeight: FontWeight.w600)),
                  ],
                ),
                SizedBox(height: 30),
                Expanded(
                  child: Container(
                    child: Center(
                      child: Row(
                        children: [
                          Spacer(),
                          bottomSheetTile(
                              "Reset Cover",
                              Color.fromRGBO(232, 252, 246, 1),
                              Ionicons.trash_outline,
                              _revertToGeneratedThumbnail),
                          Spacer(),
                          bottomSheetTile(
                              "Set Cover",
                              Color.fromRGBO(235, 221, 217, 1),
                              Ionicons.images_outline,
                              _uploadThumbnail),
                          Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  Future<void> _uploadThumbnail() async {
    if (await Permission.storage.request().isGranted) {
      FilePickerResult result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      setState(() {
        imageFile = File(result.files.single.path);
      });
      Navigator.pop(context);
    }
  }

  void _revertToGeneratedThumbnail() async {
    setState(() {
      imageFile = null;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(20.0),
        child: Container(
          padding: EdgeInsets.only(top: 30.0, left: 4.0),
          color: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Row(
            children: [
              Container(
                  height: size.height,
                  width: size.width * .5,
                  color: Color.fromRGBO(0, 1, 25, 1)),
              Container(
                height: size.height,
                width: size.width * .5,
              )
            ],
          ),
          Positioned(
              top: 0,
              left: 0,
              child: Container(
                  height: size.height * .4,
                  width: size.width,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(0, 1, 25, 1),
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(70),
                    ),
                  ))),
          Positioned(
            top: size.height * .4,
            child: Container(
              height: size.height * .6,
              width: size.width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(70),
                ),
              ),
            ),
          ),
          Container(
            width: size.width,
            height: size.height - 50,
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.only(top: 100),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                        width: size.width * 0.9,
                        height: size.width * 0.9,
                        margin:
                            //EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                            EdgeInsets.only(
                                top: 40, bottom: 10, left: 20, right: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25.0),
                          boxShadow: [
                            BoxShadow(
                                // color: Color.fromRGBO(190, 205, 232, .5),
                                color: Colors.black.withOpacity(.2),
                                blurRadius: 4,
                                spreadRadius: 1,
                                offset: Offset(0, 3)),
                          ],
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                  height: size.height * 0.7,
                                  width: size.height * 0.7,
                                  decoration: imageFile != null
                                      ? BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          image: DecorationImage(
                                            image: FileImage(imageFile),
                                            // image: imageFile == null
                                            //     ? AssetImage(
                                            //         "assets/images/user3.png")
                                            //     : FileImage(imageFile),
                                            fit: BoxFit.cover,
                                          ))
                                      : BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: Colors.black,
                                        ),
                                  // decoration: hasImage
                                  //     ? backgroundImage()
                                  //     : backgroundColor(),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: _isBlurred ? 5 : 0,
                                      sigmaY: _isBlurred ? 5 : 0,
                                    ),
                                    child: Center(
                                      child: Player(file: widget.audio),
                                    ),
                                  )),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Align(
                                alignment: Alignment.topRight,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: GestureDetector(
                                    onTap: showOverlay,
                                    child: Container(
                                      height: 35,
                                      width: 40,
                                      color: Colors.black.withOpacity(0.2),
                                      child: BackdropFilter(
                                        child: Icon(Icons.edit,
                                            size: 18, color: Colors.white),
                                        filter: ImageFilter.blur(
                                          sigmaX: _isBlurred ? 0.0 : 2.0,
                                          sigmaY: _isBlurred ? 0.0 : 2.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )),
                    SizedBox(height: 20),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.only(left: 4),
                              child: Text(
                                "Blurred background",
                                style: GoogleFonts.lato(
                                  fontSize: 13,
                                  color: Color.fromRGBO(6, 8, 53, 1),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          Switch(
                            value: _isBlurred,
                            onChanged: (bool val) {
                              print(val);
                              setState(() {
                                _isBlurred = !_isBlurred;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      height: 45,
                      width: MediaQuery.of(context).size.width * 0.9,
                      decoration: BoxDecoration(
                        // borderRadius: BorderRadius.only(
                        //   topLeft: Radius.circular(10),
                        //   bottomLeft: Radius.circular(10),
                        // ),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        border: Border.all(
                          width: 0.2,
                          color: Colors.black.withOpacity(.3),
                        ),
                      ),
                      child: TextField(
                        controller: captionController,
                        decoration: InputDecoration(
                          hintText: "Add a caption",
                          hintStyle: GoogleFonts.lato(
                              fontSize: 12, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(5),
                        ),
                        cursorColor: Colors.green,
                        cursorWidth: 1,
                      ),
                    ),
                    // Text
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 70,
        width: MediaQuery.of(context).size.width,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            uploading
                ? CircularProgressIndicator()
                : TextButton(
                    onPressed: () => _upload(context),
                    child: Text(
                      "Next",
                      style: GoogleFonts.lato(
                          fontSize: 17, fontWeight: FontWeight.w500),
                    ),
                  )
          ],
        ),
      ),
    );
  }
}

class CurvedBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          // Container(
          //     height: size.height * .3,
          //     width: size.width,
          //     color: Color.fromRGBO(0, 1, 25, 1)),
          // Positioned(
          //   top: size.height * .3,
          //   child: Container(
          //     height: size.height * .7,
          //     width: size.width,
          //     color: Colors.white,
          //   ),
          // ),
          Row(
            children: [
              Container(
                  height: size.height,
                  width: size.width * .5,
                  color: Color.fromRGBO(0, 1, 25, 1)),
              Container(
                height: size.height,
                width: size.width * .5,
              )
            ],
          ),
          Positioned(
              top: 0,
              left: 0,
              child: Container(
                  height: size.height * .3,
                  width: size.width,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(0, 1, 25, 1),
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(70),
                    ),
                  ))),
          Positioned(
            top: size.height * .3,
            child: Container(
              height: size.height * .7,
              width: size.width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(70),
                ),
              ),
            ),
          ),
          Container(
            width: size.width,
            height: size.height,
            color: Colors.transparent,
            // child:
          ),
        ],
      ),
    );
  }
}

class Player extends StatefulWidget {
  final File file;

  Player({Key key, @required this.file}) : super(key: key);

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  AudioPlayer player;
  bool isPlaying = false;
  int totalDuration;
  double valState = 0;
  bool hasInitialized = false;

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
    addListeners();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  //adds listeners to the player to update the slider and all..
  void addListeners() {
    player.onDurationChanged.listen((Duration d) {
      setState(() {
        totalDuration = d.inMilliseconds;
      });
    });
    print(totalDuration);
    player.onAudioPositionChanged.listen((e) {
      if (e.inMilliseconds == totalDuration) {
        setState(() {
          isPlaying = false;
        });
      }
      var percent = e.inMilliseconds / totalDuration;
      print(percent);
      print("percent");
      setState(() {
        valState = percent;
      });
      print(e.inMilliseconds);
    });

    player.onPlayerCompletion.listen((event) {
      setState(() {
        isPlaying = false;
      });
    });
  }

  //activates the player and responsible for changing the pause/play icon
  Future<void> playerStateChange() async {
    if (!hasInitialized) {
      await player.setUrl(widget.file.path, isLocal: true);
      var duration = await player.getDuration();
      print(duration);
      print("this is the duration");

      await player.resume();
      setState(() {
        valState = null;
        hasInitialized = true;
      });
    }
    // if ((widget.file != null) & (!hasInitialized)) {
    //   print("initializing");
    //
    // }
    if (isPlaying) {
      await player.pause();
      setState(() {
        isPlaying = false;
      });
    } else {
      await player.resume();
      setState(() {
        isPlaying = true;
      });
    }
  }

  //manages slider seeking

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          child: CircularProgressIndicator(
            value: valState,
            strokeWidth: 1,
            backgroundColor: Colors.white,
          ),
        ),
        Positioned(
            top: 22,
            left: 20,
            child: IconButton(
              icon: Icon(
                  this.isPlaying ? Ionicons.pause_circle : Ionicons.play_circle,
                  size: 45,
                  color: Colors.white),
              onPressed: playerStateChange,
            )),
      ],
    );
  }
}
