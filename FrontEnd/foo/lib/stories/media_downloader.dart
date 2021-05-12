import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart';
import 'package:foo/stories/story.dart';
import 'dart:io';

class StoryController {
  static VideoPlayerController videoController;
}

// ignore: must_be_immutable
class NetworkFileMedia extends StatelessWidget {
  final String storyDir = '/storage/emulated/0/foo/stories';
  final String url;
  final AnimationController animController;
  final String mediaType;
  //VideoPlayerController videoController;

  NetworkFileMedia({
    @required this.url,
    @required this.animController,
    @required this.mediaType,
    //this.videoController
  });

  String _getMediaName(String url) {
    return url.split('/').last;
  }

  Future<void> _downloadMedia() async {
    var response = await get(Uri.parse(this.url));
    var mediaName = _getMediaName(this.url);
    var filePathAndName = "$storyDir/$mediaName";

    if (await Permission.storage.request().isGranted) {
      File file2 = File(filePathAndName);
      await file2.create(recursive: true);
      await file2.writeAsBytes(response.bodyBytes);
    }
  }

  Future<bool> _isExistsInStorage() async {
    String mediaName = _getMediaName(this.url);
    return await File("$storyDir/$mediaName").exists();
  }

  Future<File> _getOrDownload() async {
    String mediaName = _getMediaName(this.url);
    if (!(await _isExistsInStorage())) {
      await _downloadMedia();
    }
    return File("$storyDir/$mediaName");
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _getOrDownload(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            switch (mediaType) {
              case 'image':
                {
                  this.animController.forward();
                  return GestureDetector(
                    onTapDown: (_) {
                      this.animController.stop();
                    },
                    onTapUp: (_) {
                      this.animController.forward();
                    },
                    child: Image(
                        image: FileImage(snapshot.data), fit: BoxFit.contain),
                  );
                }
              case 'video':
                {
                  return StoryVideoPlayer(
                    videoFile: snapshot.data,
                    animController: animController,
                    //videoController: this.videoController,
                  );
                }
            }
          } else {
            this..animController.stop();
            return UnconstrainedBox(
                child: CircularProgressIndicator(
              strokeWidth: 1,
              backgroundColor: Colors.purple,
            ));
          }
          return Container(); //Just to avoid the warning!
        });
  }
}

class StoryVideoPlayer extends StatefulWidget {
  final File videoFile;
  final AnimationController animController;
  Function backwardOrForward;

  StoryVideoPlayer(
      {@required this.videoFile,
      @required this.animController,
      @required this.backwardOrForward});

  @override
  _StoryVideoPlayerState createState() => _StoryVideoPlayerState();
}

class _StoryVideoPlayerState extends State<StoryVideoPlayer> {
  VideoPlayerController videoController;

  @override
  void initState() {
    super.initState();
    videoController = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        setState(() {});
        if (videoController.value.isInitialized) {
          widget.animController.duration = videoController.value.duration;
          videoController.play();
          widget.animController.forward();
        }
      });
    widget.animController.addStatusListener((status) {
      if (status == AnimationStatus.forward) {
        videoController.play();
      } else {
        videoController.pause();
      }
    });
  }

  @override
  void dispose() {
    videoController.dispose();
    super.dispose();
  }

  Timer _timer;

  @override
  Widget build(BuildContext context) {
    if (videoController != null && videoController.value.isInitialized) {
      return GestureDetector(
        onTapDown: (_) {
          videoController.pause();
          widget.animController.stop();
          _timer = Timer(Duration(milliseconds: 200), () {
            print("Video tap timer started");
          });
        },
        onTapUp: (details) {
          videoController.play();
          widget.animController.forward();
          if (_timer.isActive) {
            widget.backwardOrForward(details);
          }
        },
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: videoController.value.size.width,
            height: videoController.value.size.height,
            child: VideoPlayer(videoController),
          ),
        ),
      );
    }
    return Center(child: Text("Video not working!"));
  }
}
