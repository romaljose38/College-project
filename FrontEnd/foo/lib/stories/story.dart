import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:foo/test_cred.dart';

import 'dart:io';
import 'dart:async';

// ignore: must_be_immutable
class StoryScreen extends StatefulWidget {
  final storyObject;
  final storyBuilderController;
  String username;
  var stories;
  String profilePic;
  int userCount;

  StoryScreen(
      {@required this.storyObject,
      @required this.storyBuilderController,
      @required this.userCount}) {
    username = storyObject['username'];
    stories = storyObject['stories'];
    profilePic =
        'https://cdn.britannica.com/s:300x169,c:crop/15/153115-050-9C83E2C3/Steve-Jobs-computer-Apple-II-1977.jpg';
  }

  @override
  _StoryScreenState createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen>
    with SingleTickerProviderStateMixin {
  AnimationController _animController;
  PageController _pageController;
  TransformationController transformationController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animController = AnimationController(vsync: this);

    final firstStory = widget.stories.first;
    _loadStory(story: firstStory, animateToPage: false);
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animController.stop();
        _animController.reset();
        setState(() {
          if (_currentIndex + 1 < widget.stories.length) {
            _currentIndex += 1;
            _loadStory(story: widget.stories[_currentIndex]);
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
              Navigator.pop(context);
            }
          }
        });
      }
    });
    transformationController = TransformationController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    transformationController.dispose();
    super.dispose();
  }

  String _getTypeOf(String url) {
    List<String> video_formats = ['mp4', 'mkv', 'flv'];
    // List<String> image_formats = ['jpeg', 'gif', 'png', 'jpg'];
    String format = url.split('.').last;
    return (video_formats.contains(format)) ? 'video' : 'image';
  }

  String _formatTime(String timeString) {
    DateTime time = DateTime.parse(timeString);
    return timeago.format(time);
  }

  String timeUploaded;

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
    String mediaName = _getMediaName(url);
    if (!(await _isExistsInStorage(url))) {
      await _downloadMedia(url);
    }
    return File("$storyDir/$mediaName");
  }

  var a = Offset.zero;

  //

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];
    timeUploaded = _formatTime(story['time']);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          PageView.builder(
            controller: _pageController,
            physics: NeverScrollableScrollPhysics(),
            itemCount: widget.stories.length,
            itemBuilder: (context, i) {
              final story = widget.stories[i];
              timeUploaded = _formatTime(story['time']);

              return FutureBuilder(
                  future: _getOrDownload('http://$localhost${story['file']}'),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      switch (_getTypeOf(story['file'])) {
                        case 'image':
                          {
                            _animController.forward();
                            return GestureDetector(
                              onTapDown: (_) {
                                _animController.stop();
                                _timer =
                                    Timer(Duration(milliseconds: 200), () {});
                              },
                              onTapUp: (details) {
                                _animController.forward();
                                if (_timer.isActive) {
                                  _backwardOrForward(details);
                                }
                              },
                              child: InteractiveViewer(
                                transformationController:
                                    transformationController,
                                minScale: 0.8,
                                maxScale: 1.6,
                                onInteractionStart: (details) {
                                  _animController.stop();
                                },
                                onInteractionEnd: (details) {
                                  _animController.forward();
                                },
                                child: Image(
                                    image: FileImage(snapshot.data),
                                    fit: BoxFit.contain),
                              ),
                            );
                          }
                        case 'video':
                          {
                            return GestureDetector(
                              child: StoryVideoPlayer(
                                videoFile: snapshot.data,
                                animController: _animController,
                                backwardOrForward: _backwardOrForward,
                              ),
                            );
                          }
                      }
                    } else {
                      _animController.stop();
                      return UnconstrainedBox(
                          child: CircularProgressIndicator(
                        strokeWidth: 1,
                        backgroundColor: Colors.purple,
                      ));
                    }
                    return Container(); //Just to avoid the warning!
                  });
            },
          ),
          Positioned(
            top: 40.0,
            left: 10.0,
            right: 10.0,
            child: Column(
              children: <Widget>[
                Row(children: [
                  for (int i = 0; i < widget.stories.length; i++)
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
                    username: widget.username,
                    timeUploaded: timeUploaded,
                    profilePic: widget.profilePic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _backwardOrForward(TapUpDetails details) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dx = details.globalPosition.dx;
    if (dx < screenWidth / 2) {
      setState(() {
        if (_currentIndex - 1 >= 0) {
          _currentIndex -= 1;
          _loadStory(story: widget.stories[_currentIndex]);
        } else {
          if (widget.storyBuilderController.page.round() - 1 >= 0) {
            widget.storyBuilderController.previousPage(
              duration: const Duration(milliseconds: 600),
              curve: Curves.linear,
            );
          } else {
            Navigator.pop(context);
          }
        }
      });
    } else if (dx > screenWidth / 2) {
      setState(() {
        if (_currentIndex + 1 < widget.stories.length) {
          _currentIndex += 1;
          _loadStory(story: widget.stories[_currentIndex]);
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
            Navigator.pop(context);
          }
        }
      });
    }
  }

  void _loadStory({Map story, bool animateToPage = true}) {
    _animController.stop();
    _animController.reset();
    if (_getTypeOf(story['file']) == 'image') //story['type'], == 'image')
      _animController.duration = const Duration(seconds: 10);
    if (animateToPage) {
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 1),
        curve: Curves.easeInOut,
      );
    }
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
        // CircleAvatar(
        //   radius: 20.0,
        //   backgroundColor: Colors.grey[300],
        //   backgroundImage: CachedNetworkImageProvider(
        //     profilePic,
        //   ),
        // ),
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

class StoryVideoPlayer extends StatefulWidget {
  final File videoFile;
  final AnimationController animController;
  final Function backwardOrForward;

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
          _timer = Timer(Duration(milliseconds: 200), () {});
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
