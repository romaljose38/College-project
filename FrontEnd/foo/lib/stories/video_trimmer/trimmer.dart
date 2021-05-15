import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_crop/image_crop.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import 'package:foo/landing_page.dart';
import 'package:foo/test_cred.dart';

import 'package:video_player/video_player.dart';
import 'package:foo/stories/video_trimmer/videoediting.dart';

class StoryUploadPick extends StatelessWidget {
  final Trimmer _trimmer = Trimmer();

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
      onTap: () async {
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
        margin: EdgeInsets.all(10.0),
        width: 80.0,
        height: 45.0,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: Colors.pink.shade400, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black45.withOpacity(.2),
              offset: Offset(0, 2),
              spreadRadius: 1,
              blurRadius: 6.0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(3.0),
          child: Container(
            width: 80,
            height: 40,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                // shape: BoxShape.circle,
                image: DecorationImage(
                  //image: AssetImage(pst.stories[index - 1]),
                  image: NetworkImage(
                      'https://vz.cnwimg.com/thumb-1200x/wp-content/uploads/2020/04/hj.jpg'),
                  fit: BoxFit.cover,
                )),
          ),
        ),
      ),
    );
  }
}

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
                        print(widget.file);
                        widget.uploadFunc(context, widget.file);
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
