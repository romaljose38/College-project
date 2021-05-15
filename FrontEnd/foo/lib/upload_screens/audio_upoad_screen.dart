import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class AudioUploadScreen extends StatefulWidget {
  File audio;

  AudioUploadScreen({this.audio});

  @override
  _AudioUploadScreenState createState() => _AudioUploadScreenState();
}

class _AudioUploadScreenState extends State<AudioUploadScreen> {
  bool hasImage = false;
  File imageFile;

  BoxDecoration backgroundImage() => BoxDecoration(
      borderRadius: BorderRadius.circular(25),
      image: DecorationImage(image: FileImage(imageFile), fit: BoxFit.cover));

  BoxDecoration backgroundColor() => BoxDecoration(
      borderRadius: BorderRadius.circular(25), color: Colors.black);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
              width: double.infinity,
              height: 420.0,
              margin: EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25.0),
                boxShadow: [
                  BoxShadow(
                      // color: Color.fromRGBO(190, 205, 232, .5),
                      color: Colors.black.withOpacity(.2),
                      blurRadius: 4,
                      spreadRadius: 1,
                      offset: Offset(0, 3)),
                ],
              ),
              child: Stack(
                children: [
                  Container(
                      height: 420,
                      width: double.infinity,
                      decoration:
                          hasImage ? backgroundImage() : backgroundColor(),
                      child: Center(
                        child: Player(file: widget.audio),
                      ))
                ],
              )),
          // Text
        ],
      ),
    );
  }
}

class Player extends StatefulWidget {
  final File file;

  Player({Key key, @required this.file}) : super(key: key);

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  AudioPlayer player;
  bool isPlaying = false;
  int totalDuration;
  double valState = 0;
  bool hasInitialized = false;

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
    addListeners();
  }

  @override
  void dispose() {
    super.dispose();
    player.dispose();
  }

  //adds listeners to the player to update the slider and all..
  void addListeners() {
    player.onDurationChanged.listen((Duration d) {
      setState(() {
        totalDuration = d.inMilliseconds;
      });
    });
    print(totalDuration);
    player.onAudioPositionChanged.listen((e) {
      if (e.inMilliseconds == totalDuration) {
        setState(() {
          isPlaying = false;
        });
      }
      var percent = e.inMilliseconds / totalDuration;
      print(percent);
      print("percent");
      setState(() {
        valState = percent;
      });
      print(e.inMilliseconds);
    });

    player.onPlayerCompletion.listen((event) {
      setState(() {
        isPlaying = false;
      });
    });
  }

  //activates the player and responsible for changing the pause/play icon
  Future<void> playerStateChange() async {
    if (!hasInitialized) {
      await player.setUrl(widget.file.path, isLocal: true);
      var duration = await player.getDuration();
      print(duration);
      print("this is the duration");

      await player.resume();
      setState(() {
        valState = null;
        hasInitialized = true;
      });
    }
    // if ((widget.file != null) & (!hasInitialized)) {
    //   print("initializing");
    //
    // }
    if (isPlaying) {
      await player.pause();
      setState(() {
        isPlaying = false;
      });
    } else {
      await player.resume();
      setState(() {
        isPlaying = true;
      });
    }
  }

  //manages slider seeking

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          child: CircularProgressIndicator(
            value: valState,
            strokeWidth: 1,
            backgroundColor: Colors.white,
          ),
        ),
        Positioned(
            top: 22,
            left: 20,
            child: IconButton(
              icon: Icon(
                  this.isPlaying ? Ionicons.pause_circle : Ionicons.play_circle,
                  size: 45,
                  color: Colors.white),
              onPressed: playerStateChange,
            )),
      ],
    );
  }
}
