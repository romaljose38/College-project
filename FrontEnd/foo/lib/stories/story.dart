import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:foo/stories/media_downloader.dart';

// ignore: must_be_immutable
class StoryScreen extends StatefulWidget {
  final storyObject;
  final storyBuilderController;
  String username;
  var stories;

  StoryScreen(
      {@required this.storyObject, @required this.storyBuilderController}) {
    username = storyObject['username'];
    stories = storyObject['stories'];
  }

  @override
  _StoryScreenState createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen>
    with SingleTickerProviderStateMixin {
  PageController _pageController;
  AnimationController _animController;
  //VideoPlayerController _videoController;
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
            // _currentIndex = 0;
            // _loadStory(story: widget.stories[_currentIndex]);
            widget.storyBuilderController.nextPage(
              duration: const Duration(milliseconds: 600),
              curve: Curves.linear,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    StoryController.videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) => _onTapDown(details, story),
        child: Stack(
          children: <Widget>[
            PageView.builder(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              itemCount: widget.stories.length,
              onPageChanged: (int page) {
                StoryController.videoController?.dispose();
              },
              itemBuilder: (context, i) {
                final story = widget.stories[i];

                return NetworkFileMedia(
                  url: story['url'],
                  animController: _animController,
                  mediaType: story['type'],
                );
                //return const SizedBox.shrink();
              },
            ),
            Positioned(
              top: 40.0,
              left: 10.0,
              right: 10.0,
              child: Column(
                children: <Widget>[
                  // Row(
                  //   children: <Widget>[
                  //     ...widget.stories
                  //         .asMap()
                  //         .map((i, e) {
                  //           return MapEntry(
                  //             i,
                  //             AnimatedBar(
                  //               animController: _animController,
                  //               position: i,
                  //               currentIndex: _currentIndex,
                  //             ),
                  //           );
                  //         })
                  //         .values
                  //         .toList()
                  //   ],
                  // ),
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
                      horizontal: 1.5,
                      vertical: 10.0,
                    ),
                    child: UserInfo(username: widget.username),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTapDown(TapDownDetails details, Map story) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dx = details.globalPosition.dx;
    if (dx < screenWidth / 3) {
      setState(() {
        if (_currentIndex - 1 >= 0) {
          _currentIndex -= 1;
          _loadStory(story: widget.stories[_currentIndex]);
        } else {
          widget.storyBuilderController.previousPage(
            duration: const Duration(milliseconds: 600),
            curve: Curves.linear,
          );
        }
      });
    } else if (dx > 2 * screenWidth / 3) {
      setState(() {
        if (_currentIndex + 1 < widget.stories.length) {
          _currentIndex += 1;
          _loadStory(story: widget.stories[_currentIndex]);
        } else {
          // Out of bounds - loop story
          // You can also Navigator.of(context).pop() here
          // _currentIndex = 0;
          // _loadStory(story: widget.stories[_currentIndex]);
          widget.storyBuilderController.nextPage(
            duration: const Duration(milliseconds: 600),
            curve: Curves.linear,
          );
        }
      });
    } else {
      if (story['type'] == 'video') {
        print("Video is ${StoryController.videoController}");
        if (StoryController.videoController.value.isPlaying) {
          StoryController.videoController.pause();
          _animController.stop();
        } else {
          StoryController.videoController.play();
          _animController.forward();
        }
      }
    }
  }

  void _loadStory({Map story, bool animateToPage = true}) {
    _animController.stop();
    _animController.reset();
    if (story['type'] == 'image')
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
      height: 5.0,
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

  const UserInfo({
    Key key,
    @required this.username,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        CircleAvatar(
          radius: 20.0,
          backgroundColor: Colors.grey[300],
          backgroundImage: CachedNetworkImageProvider(
            'https://www.filmibeat.com/ph-big/2019/07/ismart-shankar_156195627930.jpg',
          ),
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
                "52 minutes ago",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.0,
                  //fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // IconButton(
        //   icon: const Icon(
        //     Icons.close,
        //     size: 30.0,
        //     color: Colors.white,
        //   ),
        //   onPressed: () => Navigator.of(context).pop(),
        // ),
      ],
    );
  }
}
