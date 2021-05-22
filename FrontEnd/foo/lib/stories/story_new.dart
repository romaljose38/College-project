import 'package:flutter/material.dart';
import 'package:foo/models.dart';
import 'package:foo/test_cred.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock/wakelock.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:http/http.dart';
import 'package:foo/test_cred.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:foo/stories/modalsheetviews.dart';

import 'dart:io';
import 'dart:async';

class StoryScreen extends StatefulWidget {
  final UserStoryModel storyObject;
  final PageController storyBuilderController;
  final int userCount;
  final String profilePic;

  StoryScreen(
      {this.storyObject,
      this.storyBuilderController,
      this.userCount,
      this.profilePic});

  @override
  _StoryScreenState createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen>
    with SingleTickerProviderStateMixin {
  String username;
  List<Story> stories;
  int _currentIndex;
  File mediaFile;
  String mediaType;
  String timeUploaded;
  VideoPlayerController videoController;
  AnimationController _animController;
  TransformationController transformationController;

  @override
  initState() {
    _setEssentialVariables();
    _setMedia();
    _animController = AnimationController(vsync: this);

    _animate();
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animController.stop();
        _animController.reset();
        setState(() {
          if (_currentIndex + 1 < stories.length) {
            mediaFile = null;
            _currentIndex += 1;
            _animate();
            _setMedia();
          } else {
            // Out of bounds - loop story
            // You can also Navigator.of(context).pop() here
            if (widget.storyBuilderController.page.round() + 1 <
                widget.userCount) {
              widget.storyBuilderController.nextPage(
                duration: const Duration(milliseconds: 600),
                curve: Curves.linear,
              );
            } else {
              disableWakeLock();
              Navigator.pop(context);
            }
          }
        });
      }
    });

    transformationController = TransformationController();

    super.initState();
  }

  dispose() {
    videoController?.dispose();
    _animController.dispose();
    transformationController.dispose();
    super.dispose();
  }

  void _setEssentialVariables() {
    username = widget.storyObject.username;
    stories = widget.storyObject.stories;
    _currentIndex = widget.storyObject.hasUnSeen();
    if (_currentIndex == -1) _currentIndex = 0;
    timeUploaded = _formatTime(stories[_currentIndex].time);
  }

  void _setMedia() {
    _getOrDownload('http://$localhost${stories[_currentIndex].file}')
        .then((value) {
      setState(() {
        mediaFile = value;
        mediaType = _getTypeOf(stories[_currentIndex].file);
        timeUploaded = _formatTime(stories[_currentIndex].time);
        if (mediaType == 'video') {
          videoController = VideoPlayerController.file(mediaFile);
        }
      });

      if (stories[_currentIndex].viewed == null) {
        widget.storyObject.stories[_currentIndex].viewed = true;
        widget.storyObject.save();
      }
      if (mediaType == 'image') {
        _animController.duration = Duration(seconds: 10);
      }
      _animController.forward();
    });
  }

  void _animate() {
    _animController.stop();
    _animController.reset();
    if (mediaType == 'image') //story['type'], == 'image')
      _animController.duration = const Duration(seconds: 10);

    // if (animateToPage) {
    //   setState(() {
    //     mediaFile = null;
    //     _currentIndex++;
    //     _setMedia();
    //   });
    // }
    // _pageController.animateToPage(
    //   _currentIndex,
    //   duration: const Duration(milliseconds: 1),
    //   curve: Curves.easeInOut,
    // );
  }

  Future<void> disableWakeLock() async {
    if (await Wakelock.enabled) Wakelock.disable();
  }

  String _getTypeOf(String url) {
    List<String> video_formats = ['mp4', 'mkv', 'flv'];
    // List<String> image_formats = ['jpeg', 'gif', 'png', 'jpg'];
    String format = url.split('.').last;
    return (video_formats.contains(format)) ? 'video' : 'image';
  }

  String _formatTime(DateTime time) {
    // DateTime time = DateTime.parse(timeString);
    return timeago.format(time);
  }

  // Things required for downloading the necessary files

  Timer _timer;
  String storyDir = '/storage/emulated/0/foo/stories';

  String _getMediaName(String url) {
    return url.split('/').last;
  }

  Future<void> _downloadMedia(String url) async {
    var response = await get(Uri.parse(url));
    var mediaName = _getMediaName(url);
    var filePathAndName = "$storyDir/$mediaName";

    if (await Permission.storage.request().isGranted) {
      File file2 = File(filePathAndName);
      await file2.create(recursive: true);
      await file2.writeAsBytes(response.bodyBytes);
    }
  }

  Future<bool> _isExistsInStorage(String url) async {
    String mediaName = _getMediaName(url);
    return await File("$storyDir/$mediaName").exists();
  }

  Future<File> _getOrDownload(String url) async {
    // String url = 'http://$localhost${story.file}';
    String mediaName = _getMediaName(url);
    if (await Permission.storage.request().isGranted) {
      if (!(await _isExistsInStorage(url))) {
        await _downloadMedia(url);
      }
      return File("$storyDir/$mediaName");
    } else {
      disableWakeLock();
      Navigator.pop(context);
    }
    return File(''); // just to avoid the return type warning
  }

  void _backwardOrForward(TapUpDetails details) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dx = details.globalPosition.dx;
    if (dx < screenWidth / 2) {
      setState(() {
        if (_currentIndex - 1 >= 0) {
          mediaFile = null;
          _currentIndex -= 1;
          _setMedia();
          _animate();
          // _loadStory(story: widget.stories[_currentIndex]);
        } else {
          if (widget.storyBuilderController.page.round() - 1 >= 0) {
            widget.storyBuilderController.previousPage(
              duration: const Duration(milliseconds: 600),
              curve: Curves.linear,
            );
          } else {
            disableWakeLock();
            Navigator.pop(context);
          }
        }
      });
    } else if (dx > screenWidth / 2) {
      setState(() {
        if (_currentIndex + 1 < stories.length) {
          mediaFile = null;
          _currentIndex += 1;
          _setMedia();
          _animate();
          // _loadStory(story: widget.stories[_currentIndex]);
        } else {
          // Out of bounds - loop story
          // You can also Navigator.of(context).pop() here
          if (widget.storyBuilderController.page.round() + 1 <
              widget.userCount) {
            widget.storyBuilderController.nextPage(
              duration: const Duration(milliseconds: 600),
              curve: Curves.linear,
            );
          } else {
            disableWakeLock();
            Navigator.pop(context);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _animController.stop();
        if (mediaType == 'video') {
          videoController?.pause();
        }
        _timer = Timer(Duration(milliseconds: 200), () {});
      },
      onTapUp: (details) {
        _animController.forward();
        if (mediaType == 'video') {
          videoController?.play();
        }
        if (_timer.isActive) {
          _backwardOrForward(details);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          color: Colors.black,
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Stack(
            children: [
              Center(
                child: mediaFile != null
                    ? mediaType == 'image'
                        ? InteractiveViewer(
                            transformationController: transformationController,
                            minScale: 0.8,
                            maxScale: 1.6,
                            onInteractionStart: (details) {
                              _animController.stop();
                            },
                            onInteractionEnd: (details) {
                              _animController.forward();
                            },
                            child: Image(
                                image: FileImage(
                              mediaFile,
                            )),
                          )
                        : StoryVideoProvider(
                            videoController: videoController,
                            animController: _animController)
                    : CircularProgressIndicator(),
              ),
              Positioned(
                top: 40.0,
                left: 10.0,
                right: 10.0,
                child: Column(
                  children: <Widget>[
                    Row(children: [
                      for (int i = 0; i < stories.length; i++)
                        AnimatedBar(
                          animController: _animController,
                          position: i,
                          currentIndex: _currentIndex,
                        )
                    ]),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.5,
                        vertical: 20.0,
                      ),
                      child: UserInfo(
                        username: username,
                        // timeUploaded: "53 minutes ago",
                        timeUploaded: timeUploaded,
                        profilePic: widget.profilePic,
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: TextButton(
                  child: Text("Reply", style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    _animController.forward();
                    if (mediaType == 'video') videoController?.pause();
                    showModalBottomSheet(
                        backgroundColor: Colors.transparent,
                        context: context,
                        builder: (context) {
                          return ReplyModalSheet();
                        })
                      ..then((_) {
                        _animController.forward();
                        if (mediaType == 'video') videoController?.play();
                      });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedBar extends StatelessWidget {
  final AnimationController animController;
  final int position;
  final int currentIndex;

  const AnimatedBar({
    Key key,
    @required this.animController,
    @required this.position,
    @required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1.5),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: <Widget>[
                _buildContainer(
                  double.infinity,
                  position < currentIndex
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                ),
                position == currentIndex
                    ? AnimatedBuilder(
                        animation: animController,
                        builder: (context, child) {
                          return _buildContainer(
                            constraints.maxWidth * animController.value,
                            Colors.white,
                          );
                        },
                      )
                    : const SizedBox.shrink(),
              ],
            );
          },
        ),
      ),
    );
  }

  Container _buildContainer(double width, Color color) {
    return Container(
      height: 3.0,
      width: width,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(
          color: Colors.black26,
          width: 0.8,
        ),
        borderRadius: BorderRadius.circular(3.0),
      ),
    );
  }
}

class UserInfo extends StatelessWidget {
  final String username;
  final String timeUploaded;
  final String profilePic;

  const UserInfo(
      {Key key,
      @required this.username,
      @required this.timeUploaded,
      @required this.profilePic})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        CircleAvatar(
          radius: 20.0,
          backgroundColor: Colors.grey[300],
          // backgroundImage: CachedNetworkImageProvider(
          //   profilePic,
          // ),
          backgroundImage: AssetImage(profilePic),
        ),
        const SizedBox(width: 10.0),
        Expanded(
          child: Wrap(
            spacing: 8.0,
            direction: Axis.vertical,
            children: [
              Text(
                username,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                timeUploaded,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.0,
                  //fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StoryVideoProvider extends StatefulWidget {
  final VideoPlayerController videoController;
  final AnimationController animController;

  StoryVideoProvider({this.videoController, this.animController});
  @override
  _StoryVideoProviderState createState() => _StoryVideoProviderState();
}

class _StoryVideoProviderState extends State<StoryVideoProvider> {
  @override
  void initState() {
    super.initState();
    widget.videoController.initialize()
      ..then((_) {
        if (widget.videoController.value.isInitialized) {
          widget.animController.duration =
              widget.videoController.value.duration;
          widget.videoController?.play();
          widget.animController.forward();
        }
      });
    widget.animController.addStatusListener((status) {
      if (status == AnimationStatus.forward) {
        widget.videoController?.play();
      } else {
        widget.videoController?.pause();
      }
    });
  }

  void dispose() {
    widget.videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VideoPlayer(widget.videoController);
  }
}
