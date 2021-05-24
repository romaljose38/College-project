import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_crop/image_crop.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ionicons/ionicons.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import 'package:foo/landing_page.dart';
import 'package:foo/test_cred.dart';

import 'package:video_player/video_player.dart';
import 'package:foo/stories/video_trimmer/videoediting.dart';

import 'package:foo/stories/story_new.dart';

class StoryUploadPick extends StatelessWidget {
  final Trimmer _trimmer = Trimmer();
  final myStory;

  StoryUploadPick({this.myStory});

  Future<void> _uploadStory(BuildContext context, File mediaFile) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('username');
    var uri = Uri.http(localhost, '/api/story_upload');
    var request = http.MultipartRequest('POST', uri)
      ..fields['username'] = username
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        mediaFile.path,
      ));
    var response = await request.send();

    if (response.statusCode == 200) {
      print("Uploaded");
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => LandingPage()));
    } else {
      print("Upload failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (myStory == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Long press to add a new moment")));
        }
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => MyStoryScreen(storyObject: myStory)));
      },
      onLongPress: () async {
        FilePickerResult result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mkv'],
        );

        if (result != null) {
          PlatformFile file = result.files.first;
          String mediaExt = file.extension;
          File media = File(file.path);

          print(mediaExt);

          if (['jpg', 'jpeg', 'png', 'gif'].contains(mediaExt)) {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) {
              return CropMyImage(file: media, uploadFunc: _uploadStory);
            }));
          } else {
            await _trimmer.loadVideo(videoFile: media);
            Navigator.of(context).push(MaterialPageRoute(builder: (context) {
              // return TrimmerView(_trimmer,
              //     uploadFunc: _uploadStory);
              return VideoEditor(
                file: media,
                uploadFunc: _uploadStory,
              ); //TrimmerView(_trimmer, uploadFunc: _uploadStory);
            }));
          }
        }
      },
      child: Container(
        //margin: EdgeInsets.only(left: 20, top: 10, bottom: 10, right: 5),
        margin: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        height: 80, //50,
        width: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Color.fromRGBO(203, 212, 217, 1),
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
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(23),
                ),
                child: Center(
                  child: plusButton(),
                ),
              ),
            ),
          ),
        ),
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

class TrimmerView extends StatefulWidget {
  final Trimmer _trimmer;
  final Function uploadFunc;
  TrimmerView(this._trimmer, {this.uploadFunc});
  @override
  _TrimmerViewState createState() => _TrimmerViewState();
}

class _TrimmerViewState extends State<TrimmerView> {
  double _startValue = 0.0;
  double _endValue = 0.0;

  bool _isPlaying = false;
  bool _progressVisibility = false;

  Future<String> _saveVideo() async {
    setState(() {
      _progressVisibility = true;
    });

    String _value;
    print("Startvalue = $_startValue and Endvalue = $_endValue");
    await widget._trimmer
        .saveTrimmedVideo(startValue: _startValue, endValue: _endValue)
        .then((value) {
      setState(() {
        _progressVisibility = false;
        _value = value;
      });
    });

    return _value;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: Container(
              padding: EdgeInsets.only(bottom: 30.0),
              color: Colors.black,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Visibility(
                    visible: _progressVisibility,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.red,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      Spacer(),
                      IconButton(
                        onPressed: _progressVisibility
                            ? null
                            : () async {
                                _saveVideo().then((outputPath) {
                                  print('OUTPUT PATH: $outputPath');
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => Preview(outputPath),
                                    ),
                                  );
                                  // final snackBar = SnackBar(
                                  //     content:
                                  //         Text('Video Saved successfully'));
                                  // ScaffoldMessenger.of(context)
                                  //     .showSnackBar(snackBar);
                                  // widget.uploadFunc(context, File(outputPath));
                                });
                              },
                        icon: Icon(Icons.save, color: Colors.white),
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        VideoViewer(),
                        Center(
                            child: TextButton(
                          child: _isPlaying
                              ? Container()
                              : Icon(
                                  Icons.play_arrow,
                                  size: 80.0,
                                  color: Colors.white,
                                ),
                          onPressed: () async {
                            bool playbackState =
                                await widget._trimmer.videPlaybackControl(
                              startValue: _startValue,
                              endValue: _endValue,
                            );
                            setState(() {
                              _isPlaying = playbackState;
                            });
                          },
                        ))
                      ],
                    ),
                  ),
                  Center(
                    child: TrimEditor(
                      viewerHeight: 50.0,
                      viewerWidth: MediaQuery.of(context).size.width,
                      //maxVideoLength: Duration(seconds: 30),
                      onChangeStart: (value) {
                        _startValue = value;
                      },
                      onChangeEnd: (value) {
                        _endValue = value;
                      },
                      onChangePlaybackState: (value) {
                        setState(() {
                          _isPlaying = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
    Navigator.of(context).push(
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
    return Scaffold(
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
                  setState(() {
                    _isCropping = false;
                  });
                  Navigator.pop(context);
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
                  : IconButton(
                      icon: Icon(Icons.upload_file, color: Colors.white),
                      onPressed: () {
                        String fileFormat = widget.file.path.split('.').last;
                        Directory(dirPath).createSync(recursive: true);
                        filePath = dirPath +
                            '/${DateTime.now().millisecondsSinceEpoch}.' +
                            fileFormat;
                        widget.file.copySync(filePath);
                        File uploadFile = File(filePath);
                        widget.file.delete();
                        print(uploadFile);
                        widget.uploadFunc(context, uploadFile);
                      },
                    )
            ],
          ),
        ),
      ),
      body: Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
        child: _sample == null ? _buildOpeningImage() : _buildCroppingImage(),
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
