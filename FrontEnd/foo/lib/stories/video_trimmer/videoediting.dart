import 'dart:io';
import 'package:helpers/helpers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_editor/video_editor.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:foo/landing_page.dart';
import 'package:google_fonts/google_fonts.dart';

// //-------------------//
// //PICKUP VIDEO SCREEN//
// //-------------------//
// class VideoPickerPage extends StatefulWidget {
//   @override
//   _VideoPickerPageState createState() => _VideoPickerPageState();
// }

// class _VideoPickerPageState extends State<VideoPickerPage> {
//   final ImagePicker _picker = ImagePicker();

//   void _pickVideo() async {
//     final PickedFile file = await _picker.getVideo(source: ImageSource.gallery);
//     if (file != null) context.to(VideoEditor(file: File(file.path)));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Image / Video Picker")),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             TextDesigned(
//               "Click on Pick Video to select video",
//               color: Colors.black,
//               size: 18.0,
//             ),
//             ElevatedButton(
//               onPressed: _pickVideo,
//               child: Text("Pick Video From Gallery"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

//-------------------//
//VIDEO EDITOR SCREEN//
//-------------------//
class VideoEditor extends StatefulWidget {
  VideoEditor({Key key, this.file, this.uploadFunc}) : super(key: key);

  final File file;
  final Function uploadFunc;

  @override
  _VideoEditorState createState() => _VideoEditorState();
}

class _VideoEditorState extends State<VideoEditor> {
  final _exportingProgress = ValueNotifier<double>(0.0);
  final _isExporting = ValueNotifier<bool>(false);
  final double height = 60;

  bool _exported = false;
  bool _isAbsorbing = false;
  bool _isUploading = false;
  String _exportText = "";
  VideoEditorController _controller;
  TextEditingController _captionController;

  @override
  void initState() {
    _controller = VideoEditorController.file(widget.file)
      ..initialize().then((_) => setState(() {}));
    _captionController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    print("This has been disposed");
    _exportingProgress.dispose();
    _isExporting.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    print("This has been deactivated");
    _exportingProgress.dispose();
    _isExporting.dispose();
    _controller.dispose();
    super.deactivate();
  }

  void _openCropScreen() => context.to(CropScreen(controller: _controller));

  void _exportVideo() async {
    Misc.delayed(1000, () => _isExporting.value = true);
    //NOTE: To use [-crf 17] and [VideoExportPreset] you need ["min-gpl-lts"] package
    final File exportedFile = await _controller.exportVideo(
      preset: VideoExportPreset.medium,
      customInstruction: "-crf 17",
      onProgress: (statics) {
        if (_controller.video != null)
          _exportingProgress.value =
              statics.time / _controller.video.value.duration.inMilliseconds;
      },
    );
    _isExporting.value = false;

    await Permission.storage.request();
    String directoryPath = '/storage/emulated/0/foo/stories/upload';
    Directory directory =
        await Directory(directoryPath).create(recursive: true);
    String uploadStoryPath =
        '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';

    exportedFile.copySync(uploadStoryPath);
    await exportedFile.delete();

    File file = File(uploadStoryPath);

    if (file != null) {
      _exportText = "Video export Success!";
      print(
          "File Path = ${file.path}"); //This is the path that has to posted via http post
      setState(() {
        _isUploading = true;
      });
      widget.uploadFunc(
          context, File(file.path), _captionController.text ?? '');
    } else
      _exportText = "Error on export video :(";

    setState(() => _exported = true);
    Misc.delayed(2000, () => setState(() => _exported = false));

    // Navigator.pushReplacement(
    //     context, MaterialPageRoute(builder: (context) => LandingPage()));
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: _isAbsorbing,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _controller.initialized
            ? Column(
                children: [
                  Expanded(
                    child: Stack(children: [
                      Column(children: [
                        _topNavBar(),
                        Expanded(
                          child: CropGridViewer(
                            controller: _controller,
                            showGrid: false,
                          ),
                        ),
                        ..._trimSlider(),
                      ]),
                      Center(
                        child: AnimatedBuilder(
                          animation: _controller.video,
                          builder: (_, __) => OpacityTransition(
                            visible: !_controller.isPlaying,
                            child: GestureDetector(
                              onTap: _controller.video.play,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.play_arrow),
                              ),
                            ),
                          ),
                        ),
                      ),
                      _customSnackBar(),
                      ValueListenableBuilder(
                        valueListenable: _isExporting,
                        builder: (_, bool export, __) => OpacityTransition(
                          visible: export,
                          child: AlertDialog(
                            title: ValueListenableBuilder(
                              valueListenable: _exportingProgress,
                              // builder: (_, double value, __) => TextDesigned(
                              //   "Exporting video ${(value * 100).ceil()}%",
                              // color: Colors.black,
                              //   bold: true,
                              builder: (_, double value, __) =>
                                  UnconstrainedBox(
                                child: CircularProgressIndicator(
                                  strokeWidth: 1,
                                  backgroundColor: Colors.purple,
                                  value: value,
                                  //),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    ]),
                  ),
                  SizedBox(height: 15),
                  Container(
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
                        hintStyle:
                            GoogleFonts.sourceSansPro(color: Colors.grey),
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
                ],
              )
            : Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _topNavBar() {
    return SafeArea(
      child: Container(
        height: height,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _controller.rotate90Degrees(RotateDirection.left),
                child: Icon(Icons.rotate_left, color: Colors.white),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => _controller.rotate90Degrees(RotateDirection.right),
                child: Icon(Icons.rotate_right, color: Colors.white),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: _openCropScreen,
                child: Icon(Icons.crop, color: Colors.white),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _controller.video.pause();
                  try {
                    setState(() {
                      _isAbsorbing = true;
                    });
                    _exportVideo();
                  } catch (e) {
                    print(e);
                    if (_isAbsorbing == true) {
                      setState(() {
                        _isAbsorbing = false;
                      });
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              "Something went wrong while exporting this video")),
                    );
                  }
                },
                child: _isUploading
                    ? UnconstrainedBox(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: UnconstrainedBox(
                              child: CircularProgressIndicator()),
                        ),
                      )
                    : Icon(Icons.save, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatter(Duration duration) => [
        duration.inMinutes.remainder(60).toString().padLeft(2, '0'),
        duration.inSeconds.remainder(60).toString().padLeft(2, '0')
      ].join(":");

  List<Widget> _trimSlider() {
    return [
      AnimatedBuilder(
        animation: _controller.video,
        builder: (_, __) {
          final duration = _controller.video.value.duration.inSeconds;
          final pos = _controller.trimPosition * duration;
          final start = _controller.minTrim * duration;
          final end = _controller.maxTrim * duration;

          return Padding(
            padding: Margin.horizontal(height / 4),
            child: Row(children: [
              TextDesigned(
                formatter(Duration(seconds: pos.toInt())),
                color: Colors.white,
              ),
              Expanded(child: SizedBox()),
              OpacityTransition(
                visible:
                    _controller.video.value.isPlaying, //_controller.isTrimming,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  TextDesigned(
                    formatter(Duration(seconds: start.toInt())),
                    color: Colors.white,
                  ),
                  SizedBox(width: 10),
                  TextDesigned(
                    formatter(Duration(seconds: end.toInt())),
                    color: Colors.white,
                  ),
                ]),
              ),
              // TextDesigned(
              //   formatter(Duration(seconds: end.toInt())),
              //   color: Colors.white,
              // ),
            ]),
          );
        },
      ),
      Container(
        height: height,
        margin: Margin.all(height / 4),
        child: TrimSlider(
          controller: _controller,
          maxDuration: Duration(seconds: 30),
          height: height,
        ),
      )
    ];
  }

  Widget _customSnackBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SwipeTransition(
        visible: _exported,
        direction: SwipeDirection.fromBottom,
        child: Container(
          height: height,
          width: double.infinity,
          color: Colors.black.withOpacity(0.8),
          child: Center(
            child: TextDesigned(
              _exportText,
              color: Colors.white,
              bold: true,
            ),
          ),
        ),
      ),
    );
  }
}

//-----------------//
//CROP VIDEO SCREEN//
//-----------------//
class CropScreen extends StatelessWidget {
  CropScreen({Key key, @required this.controller}) : super(key: key);

  final VideoEditorController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: Margin.all(30),
          child: Column(children: [
            Expanded(
              child: AnimatedInteractiveViewer(
                maxScale: 2.4,
                child: CropGridViewer(controller: controller),
              ),
            ),
            SizedBox(height: 15),
            Row(children: [
              Expanded(
                child: SplashTap(
                  onTap: context.goBack,
                  child: Center(
                    child: TextDesigned(
                      "CANCELAR",
                      color: Colors.white,
                      bold: true,
                    ),
                  ),
                ),
              ),
              buildSplashTap("16:9", 16 / 9, padding: Margin.horizontal(10)),
              buildSplashTap("1:1", 1 / 1),
              buildSplashTap("4:5", 4 / 5, padding: Margin.horizontal(10)),
              buildSplashTap("NO", null, padding: Margin.right(10)),
              Expanded(
                child: SplashTap(
                  onTap: () {
                    //2 WAYS TO UPDATE CROP
                    //WAY 1:
                    controller.updateCrop();
                    /*WAY 2:
                    controller.minCrop = controller.cacheMinCrop;
                    controller.maxCrop = controller.cacheMaxCrop;
                    */
                    context.goBack();
                  },
                  child: Center(
                    child: TextDesigned("OK", color: Colors.white, bold: true),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget buildSplashTap(
    String title,
    double aspectRatio, {
    EdgeInsetsGeometry padding,
  }) {
    return SplashTap(
      onTap: () => controller.preferredCropAspectRatio = aspectRatio,
      child: Padding(
        padding: padding ?? Margin.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.aspect_ratio, color: Colors.white),
            TextDesigned(title, color: Colors.white, bold: true),
          ],
        ),
      ),
    );
  }
}
