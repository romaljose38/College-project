import 'package:flutter/material.dart';
import 'package:foo/stories/story.dart';

import 'package:wakelock/wakelock.dart';

// // ignore: must_be_immutable
// class StoryBuilder extends StatelessWidget {
//   final int initialPage;
//   final myStoryList;
//   PageController storyBuildController;

//   StoryBuilder({this.myStoryList, this.initialPage}) {
//     storyBuildController = PageController(initialPage: this.initialPage);
//     print("Hello, World!");
//   }

//   @override
//   Widget build(BuildContext context) {
//     print("Story builder is here");
//     return PageView.builder(
//       controller: storyBuildController,
//       itemCount: myStoryList.length,
//       itemBuilder: (context, index) {
//         //return StoryScreen(stories: this.storyList[index]);
//         return StoryScreen(
//           storyObject: myStoryList[index],
//           storyBuilderController: storyBuildController,
//           userCount: myStoryList.length,
//         );
//       },
//     );
//   }
// }

// ignore: must_be_immutable
class StoryBuilder extends StatefulWidget {
  final int initialPage;
  final myStoryList;
  final profilePic;

  StoryBuilder({this.myStoryList, this.initialPage, this.profilePic});

  @override
  _StoryBuilderState createState() => _StoryBuilderState();
}

class _StoryBuilderState extends State<StoryBuilder> {
  PageController storyBuildController;
  double currentPageValue;

  @override
  void initState() {
    super.initState();
    storyBuildController = PageController(initialPage: widget.initialPage);
    currentPageValue = widget.initialPage * 1.0;
    storyBuildController.addListener(() {
      setState(() {
        currentPageValue = storyBuildController.page;
      });
    });
  }

  void dispose() {
    storyBuildController.dispose();
    super.dispose();
  }

  Future<void> enableWakeLock() async {
    if (!(await Wakelock.enabled)) Wakelock.enable();
  }

  Future<void> disableWakeLock() async {
    if (await Wakelock.enabled) Wakelock.disable();
  }

  @override
  Widget build(BuildContext context) {
    enableWakeLock();
    return WillPopScope(
      onWillPop: () {
        disableWakeLock();
        Navigator.pop(context);

        return Future.value(false);
      },
      child: PageView.builder(
        controller: storyBuildController,
        //itemCount: storyList.length,
        itemCount: widget.myStoryList.length,
        itemBuilder: (context, index) {
          if (index == currentPageValue.floor()) {
            return Transform(
              transform: Matrix4.identity()
                ..rotateY(currentPageValue - index)
                ..rotateZ(currentPageValue - index),
              child: StoryScreen(
                storyObject: widget.myStoryList[index],
                storyBuilderController: storyBuildController,
                userCount: widget.myStoryList.length,
                profilePic: widget.profilePic[index],
              ),
            );
          } else if (index == currentPageValue.floor() + 1) {
            return Transform(
              transform: Matrix4.identity()
                ..rotateY(storyBuildController.page - index)
                ..rotateZ(storyBuildController.page - index),
              child: StoryScreen(
                storyObject: widget.myStoryList[index],
                storyBuilderController: storyBuildController,
                userCount: widget.myStoryList.length,
                profilePic: widget.profilePic[index],
              ),
            );
          } else {
            return StoryScreen(
              storyObject: widget.myStoryList[index],
              storyBuilderController: storyBuildController,
              userCount: widget.myStoryList.length,
              profilePic: widget.profilePic[index],
            );
          }
          // return StoryScreen(
          //   storyObject: myStoryList[index],
          //   storyBuilderController: storyBuildController,
          // );
        },
      ),
    );
  }
}
