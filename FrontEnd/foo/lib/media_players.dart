import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:video_player/video_player.dart';

class Player extends StatefulWidget {
  final String url;

  Player({Key key, this.url}) : super(key: key);

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
        totalDuration = d.inMicroseconds;
      });
    });

    player.onAudioPositionChanged.listen((e) {
      if (e.inMicroseconds == totalDuration) {
        setState(() {
          isPlaying = false;
        });
      }
      var percent = e.inMicroseconds / totalDuration;

      setState(() {
        valState = percent;
      });
    });

    player.onPlayerCompletion.listen((event) {
      setState(() {
        isPlaying = false;
        valState = 1;
      });
    });
  }

  //activates the player and responsible for changing the pause/play icon
  Future<void> playerStateChange() async {
    if (!hasInitialized) {
      await player.play(widget.url, volume: 0.8);
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
  Future<void> seekAudio(double val) async {
    print(val);

    Duration position = Duration(milliseconds: (val * totalDuration).toInt());
    await player.seek(position);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
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
          InkWell(
            customBorder: CircleBorder(),
            child: Icon(
                this.isPlaying ? Ionicons.pause_circle : Ionicons.play_circle,
                size: 45,
                color: Colors.white),
            onTap: playerStateChange,
          ),
        ],
      ),
    );
  }
}

class VideoPlayerProvider extends StatefulWidget {
  final File videoFile;
  final String videoUrl;

  VideoPlayerProvider({this.videoFile, this.videoUrl});

  @override
  _VideoPlayerProviderState createState() => _VideoPlayerProviderState();
}

class _VideoPlayerProviderState extends State<VideoPlayerProvider> {
  VideoPlayerController _videoPlayerController;
  BetterPlayerController _controller;
  BetterPlayerDataSource source;
  @override
  void initState() {
    super.initState();
    _videoPlayerController = (widget.videoFile != null)
        ? VideoPlayerController.file(widget.videoFile)
        : VideoPlayerController.network(widget.videoUrl);
    source = (widget.videoFile != null)
        ? BetterPlayerDataSource.file(widget.videoFile.path)
        : BetterPlayerDataSource.network(widget.videoUrl);
    _controller =
        BetterPlayerController(btrPlayerConf(), betterPlayerDataSource: source);
  }

  btrPlayerConf() => BetterPlayerConfiguration(
        fullScreenByDefault: true,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        autoDetectFullscreenDeviceOrientation: true,
        allowedScreenSleep: false,
        autoDispose: true,
        autoPlay: true,
        fit: BoxFit.contain,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          enableSkips: false,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        // alignment: Alignment.center,
        child: BetterPlayer(
          controller: _controller,
        ),
        // child: (widget.videoFile != null)
        //     ? BetterPlayer.file(widget.videoFile.path,
        //         betterPlayerConfiguration:
        //             btrPlayerConf(_videoPlayerController))
        //     : BetterPlayer.network(
        //         widget.videoUrl,
        //         betterPlayerConfiguration:
        //             btrPlayerConf(_videoPlayerController),
        //       ),
      ),
    );
  }
}
