import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  Container _default() => Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(.3),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
        ),
        child: Center(
          child: Text(
            "Change \n background",
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 12,
              color: Color.fromRGBO(6, 8, 53, 1),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
  Container thumbnail() => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
          image: DecorationImage(
              image: AssetImage("assets/images/user4.png"), fit: BoxFit.cover),
        ),
      );

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Row(
            children: [
              Container(
                  height: size.height,
                  width: size.width * .5,
                  color: Color.fromRGBO(0, 1, 25, 1)),
              Container(
                height: size.height,
                width: size.width * .5,
              )
            ],
          ),
          Positioned(
              top: 0,
              left: 0,
              child: Container(
                  height: size.height * .3,
                  width: size.width,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(0, 1, 25, 1),
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(70),
                    ),
                  ))),
          Positioned(
            top: size.height * .3,
            child: Container(
              height: size.height * .7,
              width: size.width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(70),
                ),
              ),
            ),
          ),
          Container(
            width: size.width,
            height: size.height - 50,
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.only(top: 50),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                        width: double.infinity,
                        height: 320.0,
                        margin:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
                                decoration: BoxDecoration(
                                    image: DecorationImage(
                                  image: AssetImage("assets/images/user3.png"),
                                  fit: BoxFit.cover,
                                )),
                                // decoration: hasImage
                                //     ? backgroundImage()
                                //     : backgroundColor(),
                                child: Center(
                                  child: Player(file: widget.audio),
                                ))
                          ],
                        )),
                    SizedBox(height: 20),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 20),
                      height: 100,
                      child: Row(
                        children: [
                          Container(
                            height: 100,
                            width: MediaQuery.of(context).size.width * .6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                bottomLeft: Radius.circular(10),
                              ),
                              border: Border.all(
                                width: 1,
                                color: Colors.black.withOpacity(.3),
                              ),
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: "Add a caption",
                                hintStyle: GoogleFonts.lato(
                                    fontSize: 12, color: Colors.grey),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(5),
                              ),
                              cursorColor: Colors.green,
                              cursorWidth: 1,
                              expands: true,
                              maxLines: null,
                              minLines: null,
                            ),
                          ),
                          Expanded(
                            child: hasImage ? thumbnail() : _default(),
                          )
                        ],
                      ),
                    ),

                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.only(left: 4),
                              child: Text(
                                "Blurred background",
                                style: GoogleFonts.lato(
                                  fontSize: 13,
                                  color: Color.fromRGBO(6, 8, 53, 1),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          Switch(
                            value: false,
                            onChanged: (bool val) {
                              print(val);
                            },
                          ),
                        ],
                      ),
                    ),

                    // Text
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 70,
        width: MediaQuery.of(context).size.width,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {},
              child: Text(
                "Next",
                style:
                    GoogleFonts.lato(fontSize: 17, fontWeight: FontWeight.w500),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class CurvedBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          // Container(
          //     height: size.height * .3,
          //     width: size.width,
          //     color: Color.fromRGBO(0, 1, 25, 1)),
          // Positioned(
          //   top: size.height * .3,
          //   child: Container(
          //     height: size.height * .7,
          //     width: size.width,
          //     color: Colors.white,
          //   ),
          // ),
          Row(
            children: [
              Container(
                  height: size.height,
                  width: size.width * .5,
                  color: Color.fromRGBO(0, 1, 25, 1)),
              Container(
                height: size.height,
                width: size.width * .5,
              )
            ],
          ),
          Positioned(
              top: 0,
              left: 0,
              child: Container(
                  height: size.height * .3,
                  width: size.width,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(0, 1, 25, 1),
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(70),
                    ),
                  ))),
          Positioned(
            top: size.height * .3,
            child: Container(
              height: size.height * .7,
              width: size.width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(70),
                ),
              ),
            ),
          ),
          Container(
            width: size.width,
            height: size.height,
            color: Colors.transparent,
            // child:
          ),
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
