import 'package:flutter/material.dart';
import 'package:foo/stories/story.dart';

// ignore: must_be_immutable
class StoryBuilder extends StatelessWidget {
  final int initialPage;
  final Map myStories;
  PageController storyBuildController;

  StoryBuilder({this.myStories, this.initialPage}) {
    storyBuildController = PageController(initialPage: this.initialPage);
  }
  @override
  Widget build(BuildContext context) {
    var myStoryList = myStories['data'];
    return PageView.builder(
      controller: storyBuildController,
      //itemCount: storyList.length,
      itemCount: myStoryList.length,
      itemBuilder: (context, index) {
        //return StoryScreen(stories: this.storyList[index]);
        return StoryScreen(
          storyObject: myStoryList[index],
          storyBuilderController: storyBuildController,
        );
      },
    );
  }
}
