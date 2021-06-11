import 'dart:io';

import 'package:flutter/material.dart';
import 'package:foo/screens/feed_screen.dart';
import 'package:image_crop/image_crop.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ionicons/ionicons.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vidThumbnail;
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:foo/landing_page.dart';
import 'package:foo/test_cred.dart';
import 'package:foo/models.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

import 'package:foo/stories/story_new.dart';
import 'package:foo/main.dart' show deviceCameras;

import 'dart:convert';

class StoryUploadPick extends StatefulWidget {
  final String myProfPic;
  final myStory;

  StoryUploadPick({this.myStory, this.myProfPic});

  @override
  _StoryUploadPickState createState() => _StoryUploadPickState();
}

class _StoryUploadPickState extends State<StoryUploadPick> {
  // final Trimmer _trimmer = Trimmer();
  ImagePicker _picker = ImagePicker();
  String myProfPic;

  Future<void> _uploadStory(
      BuildContext context, File mediaFile, String caption) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('username');
    int userId = prefs.getInt('id');
    var uri = Uri.http(localhost, '/api/story_upload');
    var request = http.MultipartRequest('POST', uri)
      ..fields['username'] = username
      ..fields['caption'] = caption
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        mediaFile.path,
      ));
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    var decodedResponse = jsonDecode(response.body);

    if (response.statusCode == 200) {
      var myBox = await Hive.box('MyStories');

      if (myBox.containsKey(userId)) {
        var userStory = myBox.get(userId);
        userStory.addStory(Story(
          file: decodedResponse['url'],
          time: DateTime.now(),
          storyId: decodedResponse['s_id'],
          caption: caption,
        ));
        userStory.save();
      } else {
        UserStoryModel newUser = UserStoryModel()
          ..username = username
          ..userId = userId
          ..stories = <Story>[];
        newUser.addStory(Story(
          file: decodedResponse['url'],
          time: DateTime.now(),
          storyId: decodedResponse['s_id'],
          caption: caption,
        ));

        await myBox.put(userId, newUser);
        newUser.save();
      }

      print("Uploaded");
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => LandingPage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    myProfPic = widget.myProfPic;
  }

  Future<File> testCompressAndGetFile(File file, String extension) async {
    String targetPath = (await getTemporaryDirectory()).path +
        '/upload/${DateTime.now().millisecondsSinceEpoch}.$extension';
    File(targetPath).createSync(recursive: true);
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 80,
    );

    return result;
  }

  _pickStoryToUpload(ctx, {bool isCamera = false}) async {
    File media;
    String mediaExt;
    if (isCamera == true) {
      final pickedFile = await _picker.getImage(source: ImageSource.camera);

      if (pickedFile != null) {
        mediaExt = pickedFile.path.split('.').last;
        media = File(pickedFile.path);
      }
    } else {
      FilePickerResult result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mkv'],
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        mediaExt = file.extension;
        media = File(file.path);
      }
    }

    print(mediaExt);

    if (['jpg', 'jpeg', 'png'].contains(mediaExt)) {
      media = await testCompressAndGetFile(media, mediaExt);
      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return CropMyImage(file: media, uploadFunc: _uploadStory);
      }));
    } else {
      // await _trimmer.loadVideo(videoFile: media);
      Navigator.of(ctx).push(MaterialPageRoute(builder: (context) {
        // return TrimmerView(_trimmer,
        //     uploadFunc: _uploadStory);
        return VideoTrimmerTest(
            file: media, extension: mediaExt, uploadFunc: _uploadStory);
        // return VideoEditor(
        //   file: media,
        //   uploadFunc: _uploadStory,
        // ); //TrimmerView(_trimmer, uploadFunc: _uploadStory);
      }));
    }
  }

  GestureDetector bottomSheetTile(
          String type, Color color, IconData icon, Function onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 100,
              width: 100,
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

  GestureDetector bottomSheetCamera(
          String type, Color color, IconData icon, Function onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  clipBehavior: Clip.antiAlias,
                  height: 100,
                  width: 100,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child:
                      AspectRatio(aspectRatio: 1, child: BottomSheetCamera()),
                ),
                Positioned(
                  right: 35,
                  top: 35,
                  child: Icon(
                    Ionicons.camera,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
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
            height: 250,
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
                    Text("Set Your Moments",
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
                          bottomSheetCamera(
                              "Camera",
                              Color.fromRGBO(232, 252, 246, 1),
                              Ionicons.trash_outline, () async {
                            await _pickStoryToUpload(context, isCamera: true);
                          }),
                          Spacer(),
                          bottomSheetTile(
                              "Upload status",
                              Color.fromRGBO(235, 221, 217, 1),
                              Ionicons.images_outline,
                              () => _pickStoryToUpload(context)),
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.myStory != null && !widget.myStory.isEmpty()) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => MyStoryScreen(
                  storyObject: widget.myStory, profilePic: myProfPic)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Long press to add a new moment")));
        }
      },
      onLongPress: () {
        try {
          showOverlay();
          //await _pickStoryToUpload();
        } catch (e) {
          print(e);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Something went wrong. Try again later")),
          );
        }
      },
      child: Stack(
        children: [
          Container(
            //margin: EdgeInsets.only(left: 20, top: 10, bottom: 10, right: 5),
            margin: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            height: 80, //50,
            width: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              //color: Color.fromRGBO(203, 212, 217, 1),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                // colors: [
                //   if (myStory != null)
                //     if (!myStory.isEmpty()) ...[
                //       Color.fromRGBO(250, 87, 142, 1),
                //       Color.fromRGBO(202, 136, 18, 1),
                //       Color.fromRGBO(253, 167, 142, 1),
                //     ] else ...[
                //       Color.fromRGBO(255, 255, 255, 1),
                //       Color.fromRGBO(190, 190, 190, 1),
                //     ]
                //   else ...[
                //     Color.fromRGBO(255, 255, 255, 1),
                //     Color.fromRGBO(190, 190, 190, 1),
                //   ],
                // ],
                colors: (widget.myStory != null && !widget.myStory.isEmpty())
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
                    decoration: myProfPic != null
                        ? BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(23),
                            image: DecorationImage(
                              image: FileImage(File(myProfPic)),
                              fit: BoxFit.cover,
                            ),
                          )
                        : BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(23),
                          ),
                    child: Center(
                        child: myProfPic == null
                            ? CircularProgressIndicator()
                            : Container()
                        // child: plusButton(),
                        ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Container(
                    height: 24,
                    width: 24,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    // )
                    child: Center(
                        child: Icon(Icons.add, color: Colors.white, size: 18))),
              ),
            ),
          )
        ],
      ),
    );
  }
}

Container plusButton() => Container(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 15,
            width: 3,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Container(
            width: 15,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
            ),
          )
        ],
      ),
    );

// class TrimmerView extends StatefulWidget {
//   final Trimmer _trimmer;
//   final Function uploadFunc;
//   TrimmerView(this._trimmer, {this.uploadFunc});
//   @override
//   _TrimmerViewState createState() => _TrimmerViewState();
// }

// class _TrimmerViewState extends State<TrimmerView> {
//   double _startValue = 0.0;
//   double _endValue = 0.0;

//   bool _isPlaying = false;
//   bool _progressVisibility = false;

//   Future<String> _saveVideo() async {
//     setState(() {
//       _progressVisibility = true;
//     });

//     String _value;
//     print("Startvalue = $_startValue and Endvalue = $_endValue");
//     await widget._trimmer
//         .saveTrimmedVideo(startValue: _startValue, endValue: _endValue)
//         .then((value) {
//       setState(() {
//         _progressVisibility = false;
//         _value = value;
//       });
//     });

//     return _value;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Scaffold(
//         body: Builder(
//           builder: (context) => Center(
//             child: Container(
//               padding: EdgeInsets.only(bottom: 30.0),
//               color: Colors.black,
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 mainAxisSize: MainAxisSize.max,
//                 children: <Widget>[
//                   Visibility(
//                     visible: _progressVisibility,
//                     child: LinearProgressIndicator(
//                       backgroundColor: Colors.red,
//                     ),
//                   ),
//                   Row(
//                     children: [
//                       IconButton(
//                         icon: Icon(Icons.arrow_back, color: Colors.white),
//                         padding: EdgeInsets.symmetric(horizontal: 20.0),
//                         onPressed: () {
//                           Navigator.of(context).pop();
//                         },
//                       ),
//                       Spacer(),
//                       IconButton(
//                         onPressed: _progressVisibility
//                             ? null
//                             : () async {
//                                 _saveVideo().then((outputPath) {
//                                   print('OUTPUT PATH: $outputPath');
//                                   Navigator.of(context).pushReplacement(
//                                     MaterialPageRoute(
//                                       builder: (context) => Preview(outputPath),
//                                     ),
//                                   );
//                                   // final snackBar = SnackBar(
//                                   //     content:
//                                   //         Text('Video Saved successfully'));
//                                   // ScaffoldMessenger.of(context)
//                                   //     .showSnackBar(snackBar);
//                                   // widget.uploadFunc(context, File(outputPath));
//                                 });
//                               },
//                         icon: Icon(Icons.save, color: Colors.white),
//                         padding: EdgeInsets.symmetric(horizontal: 20.0),
//                       ),
//                     ],
//                   ),
//                   Expanded(
//                     child: Stack(
//                       children: [
//                         VideoViewer(),
//                         Center(
//                             child: TextButton(
//                           child: _isPlaying
//                               ? Container()
//                               : Icon(
//                                   Icons.play_arrow,
//                                   size: 80.0,
//                                   color: Colors.white,
//                                 ),
//                           onPressed: () async {
//                             bool playbackState =
//                                 await widget._trimmer.videPlaybackControl(
//                               startValue: _startValue,
//                               endValue: _endValue,
//                             );
//                             setState(() {
//                               _isPlaying = playbackState;
//                             });
//                           },
//                         ))
//                       ],
//                     ),
//                   ),
//                   Center(
//                     child: TrimEditor(
//                       viewerHeight: 50.0,
//                       viewerWidth: MediaQuery.of(context).size.width,
//                       //maxVideoLength: Duration(seconds: 30),
//                       onChangeStart: (value) {
//                         _startValue = value;
//                       },
//                       onChangeEnd: (value) {
//                         _endValue = value;
//                       },
//                       onChangePlaybackState: (value) {
//                         setState(() {
//                           _isPlaying = value;
//                         });
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

class CropMyImage extends StatefulWidget {
  final File file;
  final Function uploadFunc;

  CropMyImage({@required this.file, @required this.uploadFunc});

  @override
  _CropMyImageState createState() => _CropMyImageState();
}

class _CropMyImageState extends State<CropMyImage> {
  final cropKey = GlobalKey<CropState>();
  File _file;
  File _sample;
  File _lastCropped;
  final String dirPath = '/storage/emulated/0/foo/stories/upload';
  String filePath;

  bool _isCropping = false;
  bool _isUploading = false;

  TextEditingController _captionController;

  @override
  void initState() {
    super.initState();
    requestPermission();
    _captionController = TextEditingController();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> requestPermission() async {
    await ImageCrop.requestPermissions();
  }

  Future<void> _openImage() async {
    final File file = File(widget.file.path);
    final sample = await ImageCrop.sampleImage(
      file: file,
      preferredSize: context.size.longestSide.ceil(),
    );

    _sample?.delete();
    _file?.delete();

    setState(() {
      _sample = sample;
      _file = file;
    });
  }

  Future<void> _cropImage() async {
    final scale = cropKey.currentState.scale;
    final area = cropKey.currentState.area;
    if (area == null) {
      // cannot crop, widget is not setup
      return;
    }

    final sample = await ImageCrop.sampleImage(
      file: _file,
      preferredSize: (2000 / scale).round(),
    );

    final file = await ImageCrop.cropImage(
      file: sample,
      area: area,
    );

    sample.delete();

    _lastCropped?.delete();
    _lastCropped = file;

    print("$file");
    print(file.path);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
          builder: (context) => CropMyImage(
                file: file,
                uploadFunc: widget.uploadFunc,
              )),
    );
  }

  Widget _buildCroppingImage() {
    return Column(
      children: <Widget>[
        Expanded(
          child: Crop.file(_sample, key: cropKey),
        ),
        Container(
          padding: const EdgeInsets.only(top: 20.0),
          alignment: AlignmentDirectional.center,
          child: Center(
            child: TextButton(
              child: Text(
                'Crop Image',
                style: Theme.of(context)
                    .textTheme
                    .button
                    .copyWith(color: Colors.white),
              ),
              onPressed: () {
                setState(() {
                  _isCropping = false;
                });
                _cropImage();
              },
            ),
          ),
        )
      ],
    );
  }

  Widget _buildOpenImage() {
    return OverflowBox(
      child: Image(
        image: FileImage(widget.file),
      ),
    );
  }

  Widget _buildOpeningImage() {
    return Center(child: _buildOpenImage());
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: _isUploading,
      child: WillPopScope(
        onWillPop: () {
          if (_isCropping == false) {
            Navigator.pop(context);
          } else {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (context) => CropMyImage(
                    file: widget.file, uploadFunc: widget.uploadFunc)));
          }
          return Future.value(false);
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          appBar: PreferredSize(
            preferredSize: Size(double.infinity, 100),
            child: Container(
              padding: EdgeInsets.only(top: 35),
              color: Colors.black,
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (_isCropping == false) {
                        Navigator.pop(context);
                      } else {
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (context) => CropMyImage(
                                file: widget.file,
                                uploadFunc: widget.uploadFunc)));
                      }
                      // setState(() {
                      //   _isCropping = false;
                      // });
                      //Navigator.pop(context);
                    },
                  ),
                  Spacer(),
                  _isCropping
                      ? Container()
                      : IconButton(
                          icon: Icon(Icons.crop, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _isCropping = true;
                            });
                            _openImage();
                          },
                        ),
                  _isCropping
                      ? Container()
                      : _isUploading
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: CircularProgressIndicator(),
                            )
                          : IconButton(
                              icon:
                                  Icon(Icons.upload_file, color: Colors.white),
                              onPressed: () {
                                String fileFormat =
                                    widget.file.path.split('.').last;
                                Directory(dirPath).createSync(recursive: true);
                                filePath = dirPath +
                                    '/${DateTime.now().millisecondsSinceEpoch}.' +
                                    fileFormat;
                                widget.file.copySync(filePath);
                                File uploadFile = File(filePath);
                                widget.file.delete();
                                print(uploadFile);
                                setState(() {
                                  _isUploading = true;
                                });
                                widget.uploadFunc(context, uploadFile,
                                    _captionController.text);
                              },
                            ),
                ],
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: Container(
                  //height: MediaQuery.of(context).size.height - 40,
                  color: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      vertical: 40.0, horizontal: 20.0),
                  child: _sample == null
                      ? _buildOpeningImage()
                      : _buildCroppingImage(),
                ),
              ),
              Offstage(
                offstage: _sample != null,
                child: Container(
                  height: 50,
                  width: double.infinity,
                  // child: Expanded(
                  child: TextField(
                    cursorColor: Colors.white,
                    cursorWidth: .8,
                    style: GoogleFonts.lato(color: Colors.white),
                    controller: _captionController,
                    decoration: InputDecoration(
                      isDense: true,
                      hintStyle: GoogleFonts.sourceSansPro(color: Colors.grey),
                      hintText: "Add a caption",
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.grey.withOpacity(.4), width: .6),
                      ),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.grey.withOpacity(.4), width: .6),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.grey.withOpacity(.4), width: .8),
                      ),
                      isCollapsed: true,
                      contentPadding: EdgeInsets.only(
                          left: 20, right: 8.0, top: 5.0, bottom: 8.0),
                    ),
                  ),
                  // ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Preview extends StatefulWidget {
  final String outputVideoPath;

  Preview(this.outputVideoPath);

  @override
  _PreviewState createState() => _PreviewState();
}

class _PreviewState extends State<Preview> {
  VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.file(File(widget.outputVideoPath))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Preview"),
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: _controller.value.isInitialized
              ? Container(
                  child: VideoPlayer(_controller),
                )
              : Container(
                  child: Center(
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class BottomSheetCamera extends StatefulWidget {
  const BottomSheetCamera({Key key}) : super(key: key);

  @override
  _BottomSheetCameraState createState() => _BottomSheetCameraState();
}

class _BottomSheetCameraState extends State<BottomSheetCamera> {
  CameraController controller;

  @override
  void initState() {
    super.initState();
    controller = CameraController(deviceCameras[0], ResolutionPreset.max);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }
    return CameraPreview(controller);
  }
}

class VideoTrimmerTest extends StatefulWidget {
  final File file;
  final String extension;
  final Function uploadFunc;
  VideoTrimmerTest(
      {@required this.file,
      @required this.extension,
      @required this.uploadFunc});

  @override
  _VideoTrimmerTestState createState() => _VideoTrimmerTestState();
}

class _VideoTrimmerTestState extends State<VideoTrimmerTest> {
  VideoPlayerController _videoController;
  bool inited = false;

  Duration totalDuration;
  double value = 10;
  double startThumbValue = 10;
  double endThumbValue = 16;
  int videoStart;
  int videoEnd;
  int maxDuration = 35;

  Duration beginTime;
  Duration durationTime;
  int totalProgress = 0;
  bool exporting = false;

  double height = 50;
  bool isPlaying = false;
  Color boxColor = Colors.white;
  TextEditingController _captionController;

  final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();

  List<String> thumbnailList = <String>[];
  bool gotThumbnail = false;
  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController();
    initVideo();
  }

  Future<File> _trimVideo() async {
    totalProgress = 0;
    final String targetFilePath =
        '/storage/emulated/0/foo/stories/upload/${DateTime.now().millisecondsSinceEpoch}.${widget.extension}';
    await Permission.storage.request();
    File(targetFilePath).createSync(recursive: true);

    beginTime = Duration(milliseconds: videoStart);
    durationTime =
        Duration(milliseconds: videoEnd) - Duration(milliseconds: videoStart);
    String begin = (videoStart < 36000000)
        ? '0${beginTime.toString()}'
        : beginTime.toString();
    String duration = (durationTime.inMilliseconds < 36000000)
        ? '0${durationTime.toString()}'
        : durationTime.toString();

    String command =
        '-i ${widget.file.path} -ss ${begin} -t ${duration} -y $targetFilePath';
    print("mpegcommand = $command");
    int rc = await _flutterFFmpeg.execute(command);
    print("FFmpeg exited with rc: $rc");
    return File(targetFilePath);
  }

  initVideo() async {
    _videoController = VideoPlayerController.file(
      widget.file,
    );
    var val = startThumbValue / (Essentials.width * 0.95);
    await _videoController.initialize();

    setState(() {
      totalDuration = _videoController.value.duration;
      inited = true;
      videoEnd = _videoController.value.duration.inMilliseconds;
      videoStart =
          (_videoController.value.duration.inMilliseconds * val).toInt();
    });
    thumbnails();
    addlistener();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _captionController?.dispose();
    super.dispose();
  }

  _handleUpload() async {
    File file = await _trimVideo();
    await widget.uploadFunc(context, file, _captionController.text ?? '');
  }

  addlistener() {
    _videoController.addListener(() async {
      var curDecimal = _videoController.value.position.inMilliseconds /
          totalDuration.inMilliseconds;

      setState(() {
        value = Essentials.width * .95 * curDecimal;
      });

      if ((value >= endThumbValue) && (_videoController.value.isPlaying)) {
        _videoController.pause();
      }
      // if()
    });
  }

  _dragStart1(DragStartDetails details) {
    double width = MediaQuery.of(context).size.width;
    double val = details.globalPosition.dx - (width * .025);

    double videoDecimal = val / (width * .95);
    int duration = totalDuration.inMilliseconds;
    int requiredMill = (duration * videoDecimal).toInt();
    print(val);
    if ((val >= endThumbValue) ||
        (((videoEnd ?? 10000000000) - requiredMill) >= (maxDuration * 1000))) {
      print(videoEnd - requiredMill);
      print(maxDuration * 1000);
      return;
    }
    _videoController.seekTo(Duration(milliseconds: requiredMill));

    setState(() {
      videoStart = requiredMill;
      startThumbValue = val;
    });
  }

  _dragUpdate1(DragUpdateDetails details) {
    double width = MediaQuery.of(context).size.width;
    double val = details.globalPosition.dx - (width * .025);

    double videoDecimal = val / (width * .95);
    int duration = totalDuration.inMilliseconds;
    int requiredMill = (duration * videoDecimal).toInt();
    if ((val > endThumbValue) ||
        (((videoEnd ?? 10000000000) - requiredMill) >= (maxDuration * 1000))) {
      return;
    }
    _videoController.seekTo(Duration(milliseconds: requiredMill));

    setState(() {
      videoStart = requiredMill;
      startThumbValue = val;
    });
  }

  _dragStart2(DragStartDetails details) {
    double width = MediaQuery.of(context).size.width;
    double val = details.globalPosition.dx - (width * .025);
    if (val <= startThumbValue) {
      return;
    }

    double videoDecimal = val / (width * .95);
    int duration = totalDuration.inMilliseconds;
    int requiredMill = (duration * videoDecimal).toInt();
    if ((requiredMill - (videoStart ?? 10000000000)) >= (maxDuration * 1000))
      return;
    setState(() {
      endThumbValue = val;
    });
    setState(() {
      videoEnd = requiredMill;
    });
  }

  _dragUpdate2(DragUpdateDetails details) {
    double width = MediaQuery.of(context).size.width;
    double val = details.globalPosition.dx - (width * .025);
    if (val <= startThumbValue) {
      return;
    }

    double videoDecimal = val / (width * .95);
    int duration = totalDuration.inMilliseconds;
    int requiredMill = (duration * videoDecimal).toInt();
    print("$requiredMill, ${videoStart ?? 10000000000}, $maxDuration");
    print(requiredMill - (videoStart ?? 10000000000) >= (maxDuration * 1000));
    if ((requiredMill - (videoStart ?? 10000000000)) >= (maxDuration * 1000)) {
      print(requiredMill - (videoStart ?? 10000000000) >= (maxDuration * 1000));
      return;
    }
    // return;
    setState(() {
      endThumbValue = val;
    });
    setState(() {
      videoEnd = requiredMill;
    });
  }

  _play() async {
    double width = MediaQuery.of(context).size.width;
    if (value >= endThumbValue) {
      double videoDecimal = startThumbValue / (width * .95);
      int duration = totalDuration.inMilliseconds;
      int requiredMill = (duration * videoDecimal).toInt();
      await _videoController.seekTo(Duration(milliseconds: requiredMill));
    } else if (value <= startThumbValue) {
      double videoDecimal = startThumbValue / (width * .95);
      int duration = totalDuration.inMilliseconds;
      int requiredMill = (duration * videoDecimal).toInt();
      await _videoController.seekTo(Duration(milliseconds: requiredMill));
    }
    _videoController.play();
  }

  _sliderAreaDragStart(DragStartDetails details) {
    // print(details.globalPosition.)
  }

  _sliderAreaDragUpdate(DragUpdateDetails details) {
    print(details.delta.dx);
    var width = MediaQuery.of(context).size.width * .95;
    if ((startThumbValue < 0)) {
      setState(() {
        startThumbValue += 1;
        endThumbValue += 1;
      });
      return;
    } else if (endThumbValue > (width - 3)) {
      setState(() {
        startThumbValue -= 1;
        endThumbValue -= 1;
      });
      return;
    }
    setState(() {
      startThumbValue += details.delta.dx;
      endThumbValue += details.delta.dx;
    });
    double videoDecimal = startThumbValue / width;
    int duration = totalDuration.inMilliseconds;
    int requiredMill = (duration * videoDecimal).toInt();
    _videoController.seekTo(Duration(microseconds: requiredMill));
    double newStartThumbVal = startThumbValue + details.delta.dx;
    double newEndThumbVal = endThumbValue + details.delta.dx;

    setState(() {
      startThumbValue += details.delta.dx;
      endThumbValue += details.delta.dx;
      videoStart = ((newStartThumbVal / width) * duration).toInt();
      videoEnd = ((newEndThumbVal / width) * duration).toInt();
    });
  }

  //Widgets

  videoProgressSlider() => Positioned(
        left: value,
        child: Container(
            height: height,
            width: 1,
            decoration: BoxDecoration(
              color: Colors.white,
            )),
      );

  startThumb() => Positioned(
        left: startThumbValue,
        child: Container(
            height: height,
            width: 5,
            color: boxColor,
            child: Stack(alignment: Alignment.center, children: [
              OverflowBox(
                maxWidth: 18,
                child: GestureDetector(
                  onHorizontalDragStart: _dragStart1,
                  onHorizontalDragUpdate: _dragUpdate1,
                  child: Container(
                      height: 18,
                      width: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      )),
                ),
              )
            ])),
      );

  endThumb() => Positioned(
        left: endThumbValue,
        child: Container(
            height: height,
            width: 5,
            color: boxColor,
            child: Stack(alignment: Alignment.center, children: [
              OverflowBox(
                maxWidth: 18,
                child: GestureDetector(
                  onHorizontalDragStart: _dragStart2,
                  onHorizontalDragUpdate: _dragUpdate2,
                  child: Container(
                      height: 18,
                      width: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      )),
                ),
              )
            ])),
      );

  sliderArea() {
    return Positioned(
      left: startThumbValue,
      child: GestureDetector(
        onPanStart: _sliderAreaDragStart,
        onPanUpdate: _sliderAreaDragUpdate,
        child: Container(
            width: endThumbValue - startThumbValue,
            height: height,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.3),
              border: Border(
                  top: BorderSide(width: 2, color: Colors.white),
                  bottom: BorderSide(width: 4, color: Colors.white)),
            )),
      ),
    );
  }

  thumbnails() async {
    int interval = totalDuration.inMilliseconds ~/ 9;
    List images = [];
    for (int i = 0; i < 10; i++) {
      if (i == 0) {
        images.add(interval);
      } else {
        images.add(images[i - 1] + interval);
      }
    }
    print(images);

    for (int i in images) {
      String path = await vidThumbnail.VideoThumbnail.thumbnailFile(
          video: widget.file.path,
          thumbnailPath: (await getTemporaryDirectory()).path + '$i.jpg',
          imageFormat: vidThumbnail.ImageFormat.JPEG,
          timeMs: i,
          quality: 10);
      thumbnailList.add(path);
    }
    setState(() {
      gotThumbnail = true;
    });
  }

  bgTile(String path) => Container(
      height: height + 5,
      width: ((MediaQuery.of(context).size.width * .95) - 2) / 10,
      decoration: BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.cover,
          image: FileImage(
            File(path),
          ),
        ),
      ));

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.only(top: 35),
      child: WillPopScope(
        onWillPop: () async {
          _flutterFFmpeg.cancel();
          Navigator.pop(context);
          return Future.value(false);
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: PreferredSize(
              preferredSize: Size(size.width, 60),
              child: Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () {},
                    )
                  ],
                ),
              )),
          body:
              Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(
                width: MediaQuery.of(context).size.width * .95,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(width: 1, color: Colors.white54),
                ),
                child: Stack(children: [
                  Container(
                      decoration: BoxDecoration(color: Colors.black),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                          children: gotThumbnail
                              ? <Widget>[
                                  ...thumbnailList
                                      .map((path) => bgTile(path))
                                      .toList()
                                ]
                              : [])),
                  videoProgressSlider(),
                  sliderArea(),
                  startThumb(),
                  endThumb(),
                ])),

            Expanded(
              child: Container(
                  // height: size.height * .6,
                  width: double.infinity,
                  child: inited
                      ? Center(
                          child: GestureDetector(
                            onTap: playerHandler,
                            child: Stack(
                              children: [
                                AspectRatio(
                                    aspectRatio:
                                        _videoController.value.aspectRatio,
                                    child: VideoPlayer(_videoController)),
                                Positioned.fill(
                                    child: Center(
                                        child: IconButton(
                                  icon: Icon(
                                      isPlaying
                                          ? Ionicons.pause_circle
                                          : Ionicons.play_circle,
                                      size: 35,
                                      color: Colors.white),
                                  onPressed: playerHandler,
                                )))
                              ],
                            ),
                          ),
                        )
                      : Text("initing")),
            ),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _captionController,
                  cursorColor: Colors.black,
                  cursorWidth: .3,
                  textAlign: TextAlign.start,
                  style: GoogleFonts.lato(color: Colors.white),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: "     Add a caption...",
                    hintStyle: GoogleFonts.openSans(
                        fontSize: 15,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.grey.withOpacity(.4), width: .6),
                    ),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.grey.withOpacity(.4), width: .6),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.grey.withOpacity(.4), width: .8),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _handleUpload,
                child: Container(
                  margin: EdgeInsets.only(
                    right: 10,
                    bottom: 5,
                  ),
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: Colors.white),
                  child: Icon(Ionicons.send, color: Colors.black, size: 15),
                ),
              )
            ])

            // RangeSlider(
            //     onChanged: sliderChange,
            //     values: RangeValues(start, end),
            //     activeColor: Colors.black)
          ]),
        ),
      ),
    );
  }

  playerHandler() {
    if (_videoController.value.isPlaying) {
      _videoController.pause();
      setState(() {
        isPlaying = false;
      });
    } else {
      _play();
      setState(() {
        isPlaying = true;
      });
    }
  }
  // sliderChange(RangeValues val) {
  //   setState(() {
  //     start = val.start;
  //     end = val.end;
  //   });
  //   var duration = _videoController.value.duration;
  //   int seek = (duration.inMilliseconds * val.start).toInt();
  //   _videoController.seekTo(Duration(milliseconds: seek));
  //   print(val.start);
  //   print(val.end);
  // }
}
