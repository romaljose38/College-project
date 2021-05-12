import 'dart:io';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foo/screens/feed_icons.dart';
import 'package:foo/screens/feed_screen.dart';
import 'package:foo/screens/models/post_model.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_cred.dart';

class VideoUploadScreen extends StatefulWidget {
  final File mediaInserted;

  VideoUploadScreen({Key key, this.mediaInserted}) : super(key: key);

  @override
  _VideoUploadScreenState createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends State<VideoUploadScreen> {
  final TextEditingController captionController = TextEditingController();
  SharedPreferences prefs;
  VideoPlayerController _controller1;
  VideoPlayerController _controller2;
  bool uploading = false;

  @override
  void initState() {
    super.initState();
    _controller1 = VideoPlayerController.file(widget.mediaInserted)
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      })
      ..setLooping(true)
      ..setVolume(0.8);
    _controller2 = VideoPlayerController.file(widget.mediaInserted)
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();

    super.dispose();
  }

  Future<void> _upload(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('username');
    var uri =
        Uri.http(localhost, '/api/upload'); //This web address has to be changed
    var request = http.MultipartRequest('POST', uri)
      ..fields['username'] = username
      ..fields['type'] = 'vid'
      ..fields['caption'] = captionController.text
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        widget.mediaInserted.path,
      ));
    var response = await request.send();
    if (response.statusCode == 200) {
      print('Uploaded');
      Navigator.push(context, MaterialPageRoute(builder: (_) => FeedScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.all(10),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: EdgeInsets.only(top: 10.0),
                          width: double.infinity,
                          height: 465.0,
                          decoration: BoxDecoration(
                            color: Colors.white,
                          ),
                          child: _controller2.value.isInitialized
                              ? Container(
                                  height: 330,
                                  // decoration: B,
                                  child: AspectRatio(
                                    aspectRatio: _controller2.value.aspectRatio,
                                    child: VideoPlayer(_controller2),
                                  ),
                                )
                              : Container(),
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
                                      color: Colors.white,
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
                                            image: AssetImage(stories[2]),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Feed.colon),
                                      color: Colors.white,
                                      onPressed: () => print('More'),
                                    ),
                                  ],
                                ),
                                InkWell(
                                  onDoubleTap: () => print('Like post'),
                                  child: _controller1.value.isInitialized
                                      ? Container(
                                          height: 330,
                                          // decoration: B,
                                          child: AspectRatio(
                                            aspectRatio:
                                                _controller1.value.aspectRatio,
                                            child: Stack(
                                              children: [
                                                VideoPlayer(_controller1),
                                                Positioned.fill(
                                                  //   child: GestureDetector(
                                                  // behavior:
                                                  //     HitTestBehavior.opaque,
                                                  // onTap: () {
                                                  //   setState(() {
                                                  //     _controller1
                                                  //             .value.isPlaying
                                                  //         ? _controller1.pause()
                                                  //         : _controller1.play();
                                                  //   });
                                                  // },
                                                  // onHorizontalDragUpdate:
                                                  //     movePosition,
                                                  // onVerticalDragUpdate:
                                                  //     changeVolume,
                                                  child: BasicOverlayWidget(
                                                      controller: _controller1),
                                                ) //),
                                              ],
                                            ),
                                          ),
                                        )
                                      : Container(),
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
              SizedBox(
                height: 20,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black26, width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: captionController,
                    maxLength: 30,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    decoration: InputDecoration(
                      hintText: "Caption",
                      contentPadding: EdgeInsets.fromLTRB(10, 5, 5, 5),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              uploading
                  ? Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 1,
                      ))
                  : Container(),
              ElevatedButton(
                child: Text("Upload"),
                onPressed: () {
                  setState(() {
                    uploading = true;
                  });
                  return _upload(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BasicOverlayWidget extends StatefulWidget {
  final VideoPlayerController controller;

  BasicOverlayWidget({@required this.controller});

  @override
  _BasicOverlayWidgetState createState() => _BasicOverlayWidgetState();
}

class _BasicOverlayWidgetState extends State<BasicOverlayWidget> {
  // Controller functions for the video

  Future<void> movePosition(DragUpdateDetails details) async {
    Duration currPosition = await widget.controller.position;
    Duration newPosition;

    if (details.primaryDelta > 0) {
      newPosition = Duration(milliseconds: currPosition.inMilliseconds + 1000);
    } else {
      newPosition = Duration(milliseconds: currPosition.inMilliseconds - 1000);
    }
    setState(() {
      widget.controller.seekTo(newPosition);
    });
  }

  double videoVolume = 0.8;
  bool isChangingVolume = false;

  Future<void> changeVolume(DragUpdateDetails details) async {
    if (details.primaryDelta < 0 && videoVolume < 1) {
      //Drag up is negative
      videoVolume += 0.01;
    } else if (details.primaryDelta > 0 && videoVolume > 0) {
      videoVolume -= 0.01;
    }
    setState(() {
      widget.controller.setVolume(videoVolume);
    });
  }

  //

  Widget buildIndicator() {
    return VideoProgressIndicator(
      widget.controller,
      allowScrubbing: true,
    );
  }

  Widget buildPlay() => widget.controller.value.isPlaying
      ? Container()
      : Container(
          alignment: Alignment.center,
          color: Colors.black26,
          child: Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 80,
          ),
        );

  Widget buildVolume() => isChangingVolume
      ? Container(
          alignment: Alignment.center,
          color: Colors.black26,
          child: Text(
            "${(videoVolume * 100).toInt()}",
            style: GoogleFonts.raleway(
              color: Colors.white,
              fontSize: 40,
            ),
          ),
        )
      : Container();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            widget.controller.value.isPlaying
                ? widget.controller.pause()
                : widget.controller.play();
          });
        },
        onHorizontalDragUpdate: movePosition,
        onVerticalDragUpdate: changeVolume,
        onVerticalDragStart: (DragStartDetails details) {
          setState(() {
            isChangingVolume = true;
          });
        },
        onVerticalDragEnd: (DragEndDetails details) {
          setState(() {
            isChangingVolume = false;
          });
        },
        child: Stack(children: <Widget>[
          buildPlay(),
          buildVolume(),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: buildIndicator(),
          ),
        ]),
      ),
    );
  }
}
