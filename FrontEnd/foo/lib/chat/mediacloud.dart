import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:foo/models.dart';
import 'package:foo/test_cred.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:swipe_to/swipe_to.dart';

class MediaCloud extends StatefulWidget {
  final ChatMessage msgObj;
  final String otherUser;
  final bool disableSwipe;
  final Function swipingHandler;
  bool hasSelectedSomething;
  final Function outerSetState;
  Map forwardMap;
  Function forwardRemover;

  MediaCloud(
      {Key key,
      this.msgObj,
      this.otherUser,
      this.hasSelectedSomething,
      this.outerSetState,
      this.forwardRemover,
      this.forwardMap,
      this.disableSwipe = false,
      this.swipingHandler})
      : super(key: key);

  @override
  _MediaCloudState createState() => _MediaCloudState();
}

class _MediaCloudState extends State<MediaCloud> {
  File file;
  bool hasUploaded = true;
  bool processed = false;
  bool isTrying = false;
  SharedPreferences _prefs;
  bool hasSetPrefs = false;

  //for receiver
  bool hasDownloaded;
  bool fileExists;

  @override
  void initState() {
    super.initState();
    if (widget.msgObj.isMe == true) {
      processMyImage();
      if (widget.msgObj.haveReachedServer != true) {
        hasUploaded = false;
        trySendingImageAgain();
      }
      print(widget.otherUser);
    } else {
      processHerImage();
    }
  }

  setPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    hasSetPrefs = true;
  }

  trySendingImageAgain() async {
    if (hasSetPrefs != true) {
      await setPrefs();
    }
    setState(() {
      isTrying = true;
    });

    int curUserId = _prefs.getInt('id');
    var uri = Uri.http(localhost, '/api/upload_chat_image');
    var request = http.MultipartRequest('POST', uri)
      ..fields['u_id'] = curUserId.toString()
      ..fields['time'] = widget.msgObj.time.toString()
      ..fields['msg_id'] = widget.msgObj.id.toString()
      ..fields['username'] = widget.otherUser
      ..files.add(
          await http.MultipartFile.fromPath('file', widget.msgObj.filePath));
    print(request.fields);
    try {
      var response = await request.send();

      if (response.statusCode != 200) {
        setState(() {
          isTrying = false;
          hasUploaded = false;
        });
      } else {
        setState(() {
          isTrying = false;
          hasUploaded = true;
        });
      }
    } catch (e) {
      setState(() {
        isTrying = false;
        hasUploaded = false;
      });
    }
  }

  showImage() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ImageDetailView(
                  image: file,
                  time: widget.msgObj.time.toString(),
                )));
  }

  FutureOr processMyImage() async {
    if ((widget.msgObj.filePath != null) &
        (await File(widget.msgObj.filePath).exists())) {
      File _file = File(widget.msgObj.filePath);
      if (_file != null) {
        // return file;
        if (mounted) {
          setState(() {
            file = _file;
            processed = true;
          });
        }
      }
    } else {
      setState(() {
        processed = false;
      });
    }

    // var ext = widget.msgObj.ext;
    // var img64 = widget.msgObj.base64string;
    // Directory appDir = await getApplicationDocumentsDirectory();
    // String path =
    //     appDir.path + '/images/' + widget.msgObj.id.toString() + '.$ext';
    // bool isPresent = await File(path).exists();
    // if (!isPresent) {
    //   if (ext == null) {
    //     return;
    //   }

    //   print(ext);
    //   var bytes = base64Decode(img64);
    //   print(bytes);

    //   File(appDir.path + '/images/' + widget.msgObj.id.toString() + '.$ext')
    //       .createSync(recursive: true);
    //   print(appDir.path + '/images/' + widget.msgObj.id.toString() + '.$ext');

    //   File fle = File(path);
    //   await fle.writeAsBytes(bytes);
    //   print("writing done successfully to " + fle.path);
    //   return fle;
    // }
    // print("already exists");
    // return File(path);
  }

  processHerImage() async {
    var ext = widget.msgObj.filePath.split('.').last;
    String appDir = await storageLocation();
    String mediaName =
        '$appDir/images/${widget.msgObj.time.millisecondsSinceEpoch.toString()}.$ext';
    if (await Permission.storage.request().isGranted) {
      if (widget.msgObj.hasSeen != true) {
        var url = 'http://$localhost${widget.msgObj.filePath}';
        print(url);
        setState(() {
          isTrying = true;
        });
        var response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          File _file = File(mediaName);
          await _file.create(recursive: true);
          await _file.writeAsBytes(response.bodyBytes);
          setState(() {
            isTrying = false;
            hasDownloaded = true;
            fileExists = true;
            file = _file;
          });
          widget.msgObj.hasSeen = true;
        } else {
          setState(() {
            isTrying = false;
            hasDownloaded = false;
            fileExists = false;
          });
        }
      } else {
        print(mediaName);
        print("hello");
        if (await _isExistsInStorage(mediaName)) {
          File file2 = File(mediaName);
          setState(() {
            hasDownloaded = true;
            fileExists = true;
            file = file2;
          });
        } else {
          setState(() {
            hasDownloaded = true;
            fileExists = false;
          });
        }
      }
    }
  }

  Future<bool> _isExistsInStorage(String fileName) async {
    return await File(fileName).exists();
  }

  String getTime() => intl.DateFormat('hh:mm').format(widget.msgObj.time);

  BoxDecoration _getDecoration() {
    return BoxDecoration(
        borderRadius: BorderRadius.circular(30),
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

  Positioned timeAndStatus() => Positioned(
        bottom: 18.0,
        right: 18.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: EdgeInsets.all(5),
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
                          color: Colors.white,
                        )
                      : Container(),
                ],
              ),
            ),
          ),
        ),
      );
  GestureDetector hisImage() => GestureDetector(
        onTap: (fileExists ?? false) ? showImage : () {},
        child: Hero(
          tag: (fileExists ?? false) ? file.path : "",
          child: Container(
            margin: EdgeInsets.all(5),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                children: [
                  (hasDownloaded ?? false)
                      ? (fileExists ?? false)
                          ? Container(
                              width: 250,
                              height: 250,

                              // decoration: _getDecoration(),
                              decoration: BoxDecoration(
                                  // borderRadius: BorderRadius.only(
                                  //   topLeft: Radius.circular(30),
                                  //   topRight: Radius.circular(30),
                                  //   bottomRight: Radius.circular(30),
                                  //   bottomLeft: Radius.circular(30),
                                  // ),
                                  image: DecorationImage(
                                      image: FileImage(file),
                                      fit: BoxFit.cover)),
                            )
                          : Container(
                              width: 250,
                              height: 250,
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.image_not_supported_outlined),
                                    Text(
                                      "File is missing",
                                      textAlign: TextAlign.center,
                                    )
                                  ],
                                ),
                              ))
                      : isTrying
                          ? Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(.3),
                              ),
                              child: Center(
                                  child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.black),
                                strokeWidth: 2,
                              )),
                            )
                          : Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(.3),
                              ),
                              child: Center(
                                child: Container(
                                  height: 58,
                                  child: Column(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.download_rounded),
                                        onPressed: processHerImage,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                  hasUploaded == false
                      ? (file != null)
                          ? isTrying
                              ? Container(
                                  height: 250,
                                  width: 250,
                                  color: Colors.black.withOpacity(.2),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.black),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 250,
                                  height: 250,
                                  decoration: BoxDecoration(
                                      // color: Colors.black.withOpacity(.3),

                                      ),
                                  child: Center(
                                    child: TextButton(
                                      child: Text(
                                        "Retry",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      onPressed: trySendingImageAgain,
                                    ),
                                  ),
                                )
                          : Container()
                      : Container(),
                  timeAndStatus()
                ],
              ),
            ),
          ),
        ),
      );

  GestureDetector myImage() => GestureDetector(
        onTap: processed ? showImage : () {},
        child: Hero(
          tag: widget.msgObj.time.toString(),
          child: Container(
            margin: EdgeInsets.all(5),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                children: [
                  processed
                      ? Container(
                          width: 250,
                          height: 250,

                          // decoration: _getDecoration(),
                          decoration: BoxDecoration(
                              // borderRadius: BorderRadius.only(
                              //   topLeft: Radius.circular(30),
                              //   topRight: Radius.circular(30),
                              //   bottomRight: Radius.circular(30),
                              //   bottomLeft: Radius.circular(30),
                              // ),
                              image: DecorationImage(
                                  image: FileImage(file), fit: BoxFit.cover)),
                        )
                      : Container(
                          height: 250,
                          width: 250,
                          decoration: _getDecoration(),
                          child: Center(child: Text("File not found!")),
                        ),
                  (hasUploaded == false)
                      ? (isTrying
                          ? Container(
                              height: 250,
                              width: 250,
                              color: Colors.black.withOpacity(.2),
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.black),
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                  // color: Colors.black.withOpacity(.3),

                                  ),
                              child: Center(
                                child: TextButton(
                                  child: Text(
                                    "Retry",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onPressed: trySendingImageAgain,
                                ),
                              ),
                            ))
                      : Container(),
                  timeAndStatus()
                ],
              ),
            ),
          ),
        ),
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
        child: cloudContent(),
      );
  cloudContent() => Row(
        mainAxisAlignment: (this.widget.msgObj.isMe == true)
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [widget.msgObj.isMe == true ? myImage() : hisImage()],
      );

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
                    widget.outerSetState();
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

class ImageDetailView extends StatelessWidget {
  final File image;
  final String time;

  ImageDetailView({this.image, this.time});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            )),
        extendBodyBehindAppBar: true,
        body: Center(
          child: Hero(
            tag: this.time,
            child: InteractiveViewer(
              constrained: true,
              maxScale: 1.5,
              child: Image.file(image, fit: BoxFit.contain),
            ),
          ),
        ));
  }
}
