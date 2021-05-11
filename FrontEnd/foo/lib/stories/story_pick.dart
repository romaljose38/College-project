import 'package:flutter/material.dart';
import 'package:foo/stories/story_builder.dart';
import 'data.dart';

class StoryPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: myStories['data'].length,
        itemBuilder: (context, index) {
          var myStoryList = myStories['data'];
          return Center(
            child: GestureDetector(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  myStoryList[index]['username'],
                ),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => StoryBuilder(
                            myStoryList: myStories['data'],
                            initialPage: index,
                          )),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
