import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_trimmer/video_trimmer.dart';

class TrimPickPage extends StatelessWidget {
  final Trimmer _trimmer = Trimmer();
  final ImagePicker _image = ImagePicker();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Video Trimmer"),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Container(
          child: ElevatedButton(
            child: Text("LOAD VIDEO"),
            onPressed: () async {
              PickedFile pickFile = await _image.getVideo(
                source: ImageSource.gallery,
              );
              File file = File(pickFile.path);
              if (file != null) {
                await _trimmer.loadVideo(videoFile: file);
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return TrimmerView(_trimmer);
                }));
              }
            },
          ),
        ),
      ),
    );
  }
}

class TrimmerView extends StatefulWidget {
  final Trimmer _trimmer;
  TrimmerView(this._trimmer);
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
        // appBar: AppBar(
        //   title: Text("Video Trimmer"),
        //   backgroundColor: Colors.transparent,
        // ),
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
                                  final snackBar = SnackBar(
                                      content:
                                          Text('Video Saved successfully'));
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(snackBar);
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
                              // ? Icon(
                              //     Icons.pause,
                              //     size: 80.0,
                              //     color: Colors.white,
                              //   )
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
                      maxVideoLength: Duration(seconds: 30),
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
                  // TextButton(
                  //   child: _isPlaying
                  //       ? Icon(
                  //           Icons.pause,
                  //           size: 80.0,
                  //           color: Colors.white,
                  //         )
                  //       : Icon(
                  //           Icons.play_arrow,
                  //           size: 80.0,
                  //           color: Colors.white,
                  //         ),
                  //   onPressed: () async {
                  //     bool playbackState =
                  //         await widget._trimmer.videPlaybackControl(
                  //       startValue: _startValue,
                  //       endValue: _endValue,
                  //     );
                  //     setState(() {
                  //       _isPlaying = playbackState;
                  //     });
                  //   },
                  // )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
