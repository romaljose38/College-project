import 'package:flutter/material.dart';
import 'package:foo/stories/story.dart';

// ignore: must_be_immutable
class StoryBuilder extends StatelessWidget {
  final int initialPage;
  final myStoryList;
  PageController storyBuildController;

  StoryBuilder({this.myStoryList, this.initialPage}) {
    storyBuildController = PageController(initialPage: this.initialPage);
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: storyBuildController,
      itemCount: myStoryList.length,
      itemBuilder: (context, index) {
        //return StoryScreen(stories: this.storyList[index]);
        return StoryScreen(
          storyObject: myStoryList[index],
          storyBuilderController: storyBuildController,
          userCount: myStoryList.length,
        );
      },
    );
  }
}

// // ignore: must_be_immutable
// class StoryBuilder extends StatefulWidget {
//   final int initialPage;
//   final myStoryList;

//   StoryBuilder({this.myStoryList, this.initialPage});

//   @override
//   _StoryBuilderState createState() => _StoryBuilderState();
// }

// class _StoryBuilderState extends State<StoryBuilder> {
//   PageController storyBuildController;
//   double currentPageValue;

//   @override
//   void initState() {
//     super.initState();
//     storyBuildController = PageController(initialPage: widget.initialPage);
//     currentPageValue = widget.initialPage * 1.0;
//     storyBuildController.addListener(() {
//       setState(() {
//         currentPageValue = storyBuildController.page;
//       });
//     });
//   }

//   void dispose() {
//     storyBuildController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return PageView.builder(
//       controller: storyBuildController,
//       //itemCount: storyList.length,
//       itemCount: widget.myStoryList.length,
//       itemBuilder: (context, index) {
//         if (index == currentPageValue.floor()) {
//           return Transform(
//             transform: Matrix4.identity()
//               ..rotateY(currentPageValue - index)
//               ..rotateZ(currentPageValue - index),
//             child: StoryScreen(
//               storyObject: widget.myStoryList[index],
//               storyBuilderController: storyBuildController,
//               userCount: widget.myStoryList.length,
//             ),
//           );
//         } else if (index == currentPageValue.floor() + 1) {
//           return Transform(
//             transform: Matrix4.identity()
//               ..rotateY(storyBuildController.page - index)
//               ..rotateZ(storyBuildController.page - index),
//             child: StoryScreen(
//               storyObject: widget.myStoryList[index],
//               storyBuilderController: storyBuildController,
//               userCount: widget.myStoryList.length,
//             ),
//           );
//         } else {
//           return StoryScreen(
//             storyObject: widget.myStoryList[index],
//             storyBuilderController: storyBuildController,
//             userCount: widget.myStoryList.length,
//           );
//         }
//         // return StoryScreen(
//         //   storyObject: myStoryList[index],
//         //   storyBuilderController: storyBuildController,
//         // );
//       },
//     );
//   }
// }
