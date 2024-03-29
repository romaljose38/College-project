import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foo/media_players.dart';
import 'package:foo/screens/feed_icons.dart';
import 'package:foo/screens/feed_screen.dart';
import 'package:foo/screens/models/post_model.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:better_player/better_player.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ionicons/ionicons.dart';
import 'package:foo/landing_page.dart';
import 'package:foo/custom_overlay.dart';
import '../test_cred.dart';

class VideoUploadScreen extends StatefulWidget {
  final File mediaInserted;

  VideoUploadScreen({Key key, this.mediaInserted}) : super(key: key);

  @override
  _VideoUploadScreenState createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends State<VideoUploadScreen>
    with TickerProviderStateMixin {
  bool hasImage = false;
  File imageFile;
  File _generatedThumbnail;
  TextEditingController captionController;
  AnimationController _animationController;

  // VideoPlayerController _controller;
  bool uploading = false;

  //
  AnimationController _overlayAnimationController;
  Animation _overlayAnimation;
  OverlayEntry _overlayEntry;
  var uploadPercent;

  @override
  void initState() {
    super.initState();
    _overlayAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 100));
    _overlayAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(_overlayAnimationController);

    //
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 100));

    captionController = TextEditingController();
    _generateThumbnail();
  }

  @override
  void dispose() {
    captionController.dispose();
    _animationController.dispose();
    super.dispose();
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

  Future<void> _generateThumbnail() async {
    await Permission.storage.request();
    final VideoPlayerController _controller =
        VideoPlayerController.file(widget.mediaInserted);
    final Duration duration = _controller.value.duration;
    final int timeOfMiddleThumbnail = duration.inMilliseconds ~/ 2;
    final fileName = await VideoThumbnail.thumbnailFile(
      video: widget.mediaInserted.path,
      thumbnailPath: (await getApplicationDocumentsDirectory()).path,
      imageFormat: ImageFormat.JPEG,
      timeMs: timeOfMiddleThumbnail, //timeOfMiddleThumbnail,
      quality: 75,
    );

    setState(() {
      print("Thumbnail is being generated!");
      _generatedThumbnail = File(fileName);
      print("Thumbnail = $_generatedThumbnail");
    });
  }

  Future<void> _uploadThumbnail() async {
    if (await Permission.storage.request().isGranted) {
      FilePickerResult result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );

      File compressedFile = await testCompressAndGetFile(
          File(result.files.single.path), result.files.single.extension);

      setState(() {
        imageFile = compressedFile;
      });
      Navigator.pop(context);
    }
  }

  Future<File> testCompressAndGetFile(File file, String extension) async {
    String targetPath = (await getTemporaryDirectory()).path +
        '/upload/${DateTime.now().millisecondsSinceEpoch}.$extension';
    File(targetPath).createSync(recursive: true);
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 80,
      format: (extension == 'png') ? CompressFormat.png : CompressFormat.jpeg,
    );

    return result;
  }

  void _revertToGeneratedThumbnail() {
    setState(() {
      imageFile = null;
    });
    Navigator.pop(context);
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

    FormData formData = FormData.fromMap({
      'user_id': userId.toString(),
      'type': 'vid',
      'caption': captionController.text,
      'file': await MultipartFile.fromFile(widget.mediaInserted.path),
      'thumbnail': await MultipartFile.fromFile(
          (imageFile == null) ? _generatedThumbnail.path : imageFile.path)
    });
    // var uri = Uri.http(
    //     localhost, '/api/post_upload'); //This web address has to be changed
    // var request = http.MultipartRequest('POST', uri)
    //   ..fields['user_id'] = userId.toString()
    //   ..fields['type'] = 'vid'
    //   ..fields['caption'] = captionController.text
    //   ..files.add(await http.MultipartFile.fromPath(
    //     'file',
    //     widget.mediaInserted.path,
    //   ))
    //   ..files.add(await http.MultipartFile.fromPath('thumbnail',
    //       (imageFile == null) ? _generatedThumbnail.path : imageFile.path));
    showProgressOverlay();
    CustomOverlay overlay = CustomOverlay(
        context: context, animationController: _animationController);
    try {
      // setState(() {
      //   uploading = true;
      // });

      var response = await dio.post('/api/post_upload', data: formData,
          onSendProgress: (int sent, int total) {
        setState(() {
          uploadPercent = sent / total;
        });
      });

      if (response.statusCode == 200) {
        print('Uploaded');
        if (imageFile.existsSync()) {
          imageFile.deleteSync();
        }
        overlay.show("Upload successful", duration: 1);
        await _overlayAnimationController
            .reverse()
            .whenComplete(() => _overlayEntry.remove());

        Timer(
            Duration(seconds: 1),
            () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => LandingPage())));
      } else {
        if (imageFile.existsSync()) {
          imageFile.deleteSync();
        }
        overlay.show("Sorry. Upload failed. \n Please try again later.",
            duration: 1);
        await _overlayAnimationController
            .reverse()
            .whenComplete(() => _overlayEntry.remove());

        Timer(
            Duration(seconds: 1),
            () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => LandingPage())));
      }
    } catch (e) {
      print('catch = $e');
      if (imageFile.existsSync()) {
        imageFile.deleteSync();
      }
      overlay.show("Sorry. Upload Failed.\n Please try again later.",
          duration: 1);
      await _overlayAnimationController
          .reverse()
          .whenComplete(() => _overlayEntry.remove());

      Timer(
          Duration(seconds: 1),
          () => Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => LandingPage())));
    }
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
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  height: size.height * 0.7,
                                  width: size.height * 0.7,
                                  decoration: _generatedThumbnail != null
                                      ? BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          image: DecorationImage(
                                            image: imageFile == null
                                                ? FileImage(
                                                    _generatedThumbnail) //FileImage(imageFile)
                                                : FileImage(imageFile),
                                            fit: BoxFit.cover,
                                          ))
                                      : BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: Colors.cyan,
                                        ),
                                  // decoration: hasImage
                                  //     ? backgroundImage()
                                  //     : backgroundColor(),
                                  child: Center(
                                    child: IconButton(
                                        icon: Icon(Icons.play_arrow),
                                        color: Colors.white,
                                        iconSize: 80,
                                        onPressed: () {
                                          Navigator.of(context).push(
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      VideoPlayerProvider(
                                                        videoFile: widget
                                                            .mediaInserted,
                                                      )));
                                        }),
                                  ),
                                )),
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
                                          sigmaX: 2.0,
                                          sigmaY: 2.0,
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
                    // Container(
                    //   margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    //   child: Row(
                    //     children: [
                    //       Expanded(
                    //         child: Container(
                    //           padding: EdgeInsets.only(left: 4),
                    //           child: Text(
                    //             "Blurred background",
                    //             style: GoogleFonts.lato(
                    //               fontSize: 13,
                    //               color: Color.fromRGBO(6, 8, 53, 1),
                    //               fontWeight: FontWeight.w600,
                    //             ),
                    //           ),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
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
                        buildCounter: (_,
                                {currentLength, isFocused, maxLength}) =>
                            Offstage(),
                        maxLength: 500,
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
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
            TextButton(
              onPressed: () {
                _upload(context);
              },
              child: Text(
                "Next",
                style:
                    GoogleFonts.lato(fontSize: 17, fontWeight: FontWeight.w500),
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
