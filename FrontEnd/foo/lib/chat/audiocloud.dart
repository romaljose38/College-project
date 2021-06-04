import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'package:foo/custom_overlay.dart';
import 'package:foo/models.dart';
import 'package:foo/test_cred.dart';
import 'package:ionicons/ionicons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:swipe_to/swipe_to.dart';

class AudioCloud extends StatefulWidget {
  final ChatMessage msgObj;
  final AnimationController controller;
  final String otherUser;
  final Function swipingHandler;
  final bool disableSwipe;
  final Function outerSetState;
  bool hasSelectedSomething;
  Map forwardMap;
  Function forwardRemover;

  AudioCloud(
      {Key key,
      this.msgObj,
      this.controller,
      this.forwardRemover,
      this.otherUser,
      this.swipingHandler,
      this.outerSetState,
      this.hasSelectedSomething,
      this.forwardMap,
      this.disableSwipe = false})
      : super(key: key);

  @override
  _AudioCloudState createState() => _AudioCloudState();
}

class _AudioCloudState extends State<AudioCloud> {
  File file;
  bool fileExists = false;
  SharedPreferences _prefs;
  bool hasSetPrefs = false;
  bool isUploading = false;
  ValueNotifier tryingNotifier;
  bool reachedServer = false;

  @override
  void initState() {
    super.initState();

    if (widget.msgObj.isMe == true) {
      setFile();

      if (widget.msgObj.haveReachedServer == true) {
        setState(() {
          reachedServer = true;
        });

        // trySendingToServer();
        // setState(() {
        //   reachedServer = true;
        // });
      } else {
        setState(() {
          reachedServer = false;
        });
        trySendingToServer();
      }
    } else {
      tryDownloading();
    }
  }

  tryDownloading() async {
    var ext = widget.msgObj.filePath.split('.').last;

    String mediaName =
        '/storage/emulated/0/foo/audio/${widget.msgObj.time.microsecondsSinceEpoch}.$ext';
    setState(() {
      isUploading = true;
    });
    if (await Permission.storage.request().isGranted) {
      if (widget.msgObj.hasSeen != true) {
        var url = 'http://$localhost${widget.msgObj.filePath}';
        try {
          var response = await http.get(Uri.parse(url));

          if (response.statusCode == 200) {
            File _file = File(mediaName);
            await _file.create(recursive: true);
            await _file.writeAsBytes(response.bodyBytes);
            setState(() {
              fileExists = true;
              file = _file;
              isUploading = false;
              reachedServer = true;
            });
            widget.msgObj.hasSeen = true;
            widget.msgObj.save();
          } else {
            setState(() {
              isUploading = false;
            });
          }
        } catch (e) {
          setState(() {
            isUploading = false;
          });
        }
      } else {
        if (await File(mediaName).exists()) {
          setState(() {
            fileExists = true;
            file = File(mediaName);
            isUploading = false;
            reachedServer = true;
          });
        } else {
          setState(() {
            fileExists = false;
            isUploading = false;
            reachedServer = true;
          });
        }
      }
    }
  }

  void setFile() async {
    if ((widget.msgObj.filePath != null) &
        (await File(widget.msgObj.filePath).exists())) {
      if (await Permission.storage.request().isGranted) {
        File _file = File(widget.msgObj.filePath);
        if (_file != null) {
          // return file;
          if (mounted) {
            setState(() {
              file = _file;
              fileExists = true;
              tryingNotifier = ValueNotifier(isUploading);
            });
          }
        }
      }
    }
  }

  setPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    hasSetPrefs = true;
  }

  void trySendingToServer() async {
    if (hasSetPrefs != true) {
      await setPrefs();
    }
    setState(() {
      tryingNotifier = ValueNotifier(true);
    });
    if (await Permission.storage.request().isGranted) {
      try {
        int curUserId = _prefs.getInt('id');
        var uri = Uri.http(localhost, '/api/upload_chat_audio');
        var request = http.MultipartRequest('POST', uri)
          ..fields['u_id'] = curUserId.toString()
          ..fields['time'] = widget.msgObj.time.toString()
          ..fields['msg_id'] = widget.msgObj.id.toString()
          ..fields['username'] = widget.otherUser
          ..files.add(await http.MultipartFile.fromPath(
              'file', widget.msgObj.filePath));
        var response = await request.send();
        if (response.statusCode == 200) {
          setState(() {
            tryingNotifier.value = false;
            reachedServer = true;
          });
        } else {
          setState(() {
            tryingNotifier.value = false;
          });
        }
      } catch (error) {
        setState(() {
          tryingNotifier.value = false;
        });
      }
    }
  }

  String getTime() => intl.DateFormat('hh:mm').format(this.widget.msgObj.time);

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

  showError(val) {
    CustomOverlay overlay =
        CustomOverlay(context: context, animationController: widget.controller);
    overlay.show("File is missing");
  }

  noAudioHim() {
    return Container(
        margin: EdgeInsets.all(5),
        height: 60,
        width: 240,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                stops: [
                  .3,
                  1
                ],
                colors: [
                  Color.fromRGBO(248, 251, 255, 1),
                  Color.fromRGBO(255, 255, 255, 1)
                ])),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Spacer(),
            GestureDetector(
                child: isUploading
                    ? SizedBox(
                        height: 26,
                        width: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 1,
                        ),
                      )
                    : Icon(
                        Ionicons.cloud_download,
                        size: 26,
                        color: Colors.black,
                      ),
                onTap: tryDownloading),
            SliderTheme(
              data: SliderThemeData(
                  trackHeight: 1.4,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7)),
              child: Slider(
                  value: 0, onChanged: showError, activeColor: Colors.white),
            ),
          ],
        ));
  }

  noAudio() {
    return Container(
        margin: EdgeInsets.all(5),
        height: 60,
        width: 240,
        decoration: BoxDecoration(
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
                ])),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
                child: Icon(Ionicons.play_circle), onTap: () => showError(0)),
            SliderTheme(
              data: SliderThemeData(
                  trackHeight: 1.4,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7)),
              child: Slider(
                  value: 0, onChanged: showError, activeColor: Colors.white),
            ),
          ],
        ));
  }

  cloudContent() => Column(
        children: [
          Row(
            mainAxisAlignment: (this.widget.msgObj.isMe == true)
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Wrap(
                direction: Axis.vertical,
                crossAxisAlignment: widget.msgObj.isMe
                    ? WrapCrossAlignment.end
                    : WrapCrossAlignment.start,
                children: [
                  Stack(
                    children: [
                      fileExists
                          ? Player(
                              file: file,
                              notifier: tryingNotifier,
                              reachedServer: reachedServer,
                              uploadFunction: trySendingToServer,
                              isMe: widget.msgObj.isMe,
                            )
                          : widget.msgObj.isMe
                              ? noAudio()
                              : noAudioHim(),
                      Positioned(
                        bottom: 7.0,
                        right: 15.0,
                        child: Row(
                          children: <Widget>[
                            Text(getTime(),
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  color: this.widget.msgObj.isMe == true
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 10.0,
                                )),
                            SizedBox(width: 3.0),
                            (widget.msgObj.isMe == true)
                                ? Icon(
                                    widget.msgObj.haveReachedServer
                                        ? (widget.msgObj.haveReceived
                                            ? (widget.msgObj.hasSeen == true)
                                                ? Icons.done_outline_sharp
                                                : Icons.done_all
                                            : Icons.done)
                                        : Icons.timelapse_outlined,
                                    size: 12.0,
                                    color: Colors.black38,
                                  )
                                : Container(),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

  swipeAble() => SwipeTo(
      offsetDx: .2,
      iconColor: Colors.black54,
      iconSize: 16,
      onLeftSwipe: widget.msgObj.isMe
          ? () => widget.swipingHandler(widget.msgObj)
          : null,
      onRightSwipe: widget.msgObj.isMe
          ? null
          : () => widget.swipingHandler(widget.msgObj),
      child: cloudContent());

  bool hasSelected = false;

  @override
  Widget build(BuildContext context) {
    return this.widget.disableSwipe
        ? cloudContent()
        : GestureDetector(
            onLongPress: (widget.msgObj.haveReachedServer ?? false) ||
                    (widget.msgObj.isMe == false)
                ? () {
                    print("on long press");
                    // widget.outerSetState(() {
                    //   widget.hasSelectedSomething = true;
                    // });
                    widget.outerSetState(true);
                    setState(() {
                      hasSelected = true;
                    });
                    widget.forwardMap[widget.msgObj.id] = widget.msgObj;
                    print(widget.forwardMap);
                  }
                : null,
            onTap: (((widget.msgObj.haveReachedServer ?? false) ||
                        (widget.msgObj.isMe == false)) &&
                    widget.forwardMap.length >= 1)
                ? (widget.hasSelectedSomething ?? false)
                    ? () {
                        if (hasSelected == true) {
                          if (widget.forwardMap.length == 1) {
                            widget.forwardRemover();
                            widget.outerSetState(false);
                            widget.forwardMap.remove(widget.msgObj.id);
                          } else {
                            widget.forwardMap.remove(widget.msgObj.id);
                          }
                          setState(() {
                            hasSelected = false;
                          });
                        } else if (hasSelected == false) {
                          widget.forwardMap[widget.msgObj.id] = widget.msgObj;
                          setState(() {
                            hasSelected = true;
                          });
                        }
                        print(widget.forwardMap);
                      }
                    : null
                : null,
            child: Container(
                color: //(widget.hasSelectedSomething &&
                    (widget.forwardMap.containsKey(widget.msgObj.id) &&
                            hasSelected)
                        ? Colors.blue.withOpacity(.3)
                        : Colors.transparent,
                child: swipeAble()));
  }
}

class Player extends StatefulWidget {
  final File file;
  final ValueNotifier notifier;
  final bool reachedServer;
  final Function uploadFunction;
  final bool isMe;

  Player(
      {Key key,
      this.file,
      this.notifier,
      this.reachedServer,
      this.uploadFunction,
      this.isMe})
      : super(key: key);

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
    player?.dispose();
  }

  //adds listeners to the player to update the slider and all..
  void addListeners() {
    player.onDurationChanged.listen((Duration d) {
      setState(() {
        totalDuration = d.inMicroseconds;
      });
      print('Max duration: $d');
    });

    player.onAudioPositionChanged.listen((e) {
      print("not fired");

      var percent = e.inMicroseconds / totalDuration;
      print(percent);
      setState(() {
        valState = percent;
      });
      print("value sett");
      print(e.inMilliseconds);
      if (e.inMicroseconds == totalDuration) {
        print("total duration reached");
        setState(() {
          isPlaying = false;
          valState = 1;
        });
      }
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
    if ((widget.file != null) & (!hasInitialized)) {
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
    print("value changesd $val");
    Duration position = Duration(microseconds: (val * totalDuration).toInt());
    await player.seek(position);
  }

  BoxDecoration _getDecoration() {
    return BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            stops: [.3, 1],
            colors: widget.isMe
                ? [
                    Color.fromRGBO(255, 143, 187, 1),
                    Color.fromRGBO(255, 117, 116, 1)
                  ]
                : [
                    Color.fromRGBO(248, 251, 255, 1),
                    Color.fromRGBO(255, 255, 255, 1)
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
            Spacer(),
            widget.reachedServer
                ? GestureDetector(
                    onTap: playerStateChange,
                    child: Icon(
                      this.isPlaying
                          ? Ionicons.pause_circle
                          : Ionicons.play_circle,
                      size: 26,
                      color: widget.isMe ? Colors.white : Colors.black,
                    ),
                  )
                : ValueListenableBuilder(
                    valueListenable: widget.notifier,
                    builder: (context, snapshot, _widget) {
                      Widget child;
                      if (widget.notifier.value == true) {
                        child = SizedBox(
                          height: 26,
                          width: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 1,
                          ),
                        );
                      } else {
                        child = Icon(
                          Ionicons.cloud_upload,
                          size: 26,
                          color: Colors.white,
                        );
                      }

                      return GestureDetector(
                          child: child,
                          onTap: (widget.notifier.value == true)
                              ? () {}
                              : widget.uploadFunction);
                    }),
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
