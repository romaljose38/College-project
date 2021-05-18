import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:foo/models.dart';
import 'package:ionicons/ionicons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart' as intl;

class AudioCloud extends StatelessWidget {
  final ChatMessage msgObj;

  AudioCloud({this.msgObj});

  FutureOr convertEncodedString() async {
    if ((this.msgObj.isMe == true) & (this.msgObj.filePath != null)) {
      bool exists = await File(this.msgObj.filePath).exists();
      if (exists) {
        File file = File(this.msgObj.filePath);
        if (file != null) {
          return file;
        }
      }
      return "does not exist";
    } else {
      var ext = this.msgObj.ext;
      var aud64 = this.msgObj.base64string;
      Directory appDir = await getApplicationDocumentsDirectory();
      String path =
          appDir.path + '/Audio/' + this.msgObj.id.toString() + '.$ext';
      bool isPresent = await File(path).exists();
      if (!isPresent) {
        if (ext == null) {
          return;
        }

        print(ext);
        var bytes = base64Decode(aud64);
        print(bytes);

        File(appDir.path + '/Audio/' + this.msgObj.id.toString() + '.$ext')
            .createSync(recursive: true);
        print(appDir.path + '/Audio/' + this.msgObj.id.toString() + '.$ext');

        File fle = File(path);
        await fle.writeAsBytes(bytes);
        print("writing done successfully to " + fle.path);
        return fle;
      }
      print("already exists");
      return File(path);
    }
  }

  String getTime() => intl.DateFormat('hh:mm').format(this.msgObj.time);

  BoxDecoration _getDecoration() {
    return BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            stops: [
              .3,
              1
            ],
            colors: [
              Color.fromRGBO(255, 143, 187, 1),
              Color.fromRGBO(255, 117, 116, 1)
            ]));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: (this.msgObj.isMe == true)
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Stack(
              children: [
                FutureBuilder(
                    future: convertEncodedString(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        // addListeners();
                        print(snapshot.data);
                        File file = snapshot.data;
                        return Player(file: file);
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                              margin: EdgeInsets.all(5),
                              height: 60,
                              width: 260,
                              decoration: _getDecoration(),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  IconButton(
                                      icon: Icon(Icons.play_arrow_rounded),
                                      onPressed: () {}),
                                  Slider(value: 0, onChanged: (val) {}),
                                ],
                              )),
                        ),
                      );
                    }),
                Positioned(
                  bottom: 7.0,
                  right: 15.0,
                  child: Row(
                    children: <Widget>[
                      Text(getTime(),
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            color: this.msgObj.isMe == true
                                ? Colors.white
                                : Colors.black,
                            fontSize: 10.0,
                          )),
                      SizedBox(width: 3.0),
                      Icon(
                        (this.msgObj.haveReachedServer == true)
                            ? (this.msgObj.haveReceived
                                ? Icons.done_all
                                : Icons.done)
                            : Icons.timelapse_outlined,
                        size: 12.0,
                        color: Colors.black38,
                      )
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class Player extends StatefulWidget {
  final File file;

  Player({Key key, this.file}) : super(key: key);

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

  //adds listeners to the player to update the slider and all..
  void addListeners() {
    player.onDurationChanged.listen((Duration d) {
      setState(() {
        totalDuration = d.inMilliseconds;
      });
      print('Max duration: $d');
    });

    player.onAudioPositionChanged.listen((e) {
      if (e.inMilliseconds == totalDuration) {
        setState(() {
          isPlaying = false;
        });
      }
      var percent = e.inMilliseconds / totalDuration;
      print(percent);
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
    print("button click");
    print(totalDuration);
    if ((widget.file != null) & (!hasInitialized)) {
      print("initializing");
      await player.play(widget.file.path,
          isLocal: true, volume: .8, stayAwake: true);
      setState(() {
        hasInitialized = true;
      });
    }
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

  BoxDecoration _getDecoration() {
    return BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            stops: [
              .3,
              1
            ],
            colors: [
              Color.fromRGBO(255, 143, 187, 1),
              Color.fromRGBO(255, 117, 116, 1)
            ]));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.all(5),
        height: 60,
        width: 240,
        decoration: _getDecoration(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
                icon: Icon(
                  this.isPlaying ? Ionicons.pause_circle : Ionicons.play_circle,
                  size: 26,
                  color: Colors.white,
                ),
                onPressed: playerStateChange),
            SliderTheme(
              data: SliderThemeData(
                  trackHeight: 1.4,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7)),
              child: Slider(
                  value: valState,
                  onChanged: seekAudio,
                  activeColor: Colors.white),
            ),
          ],
        ));
  }
}
