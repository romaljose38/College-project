import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:foo/models.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart' as intl;

class MediaCloud extends StatelessWidget {
  final ChatMessage msgObj;

  MediaCloud({this.msgObj});

  FutureOr convertEncodedString() async {
    if ((msgObj.isMe == true) & (msgObj.filePath != null)) {
      File file = File(msgObj.filePath);
      if (file != null) {
        return file;
      }
    } else {
      var ext = msgObj.ext;
      var img64 = msgObj.base64string;
      Directory appDir = await getApplicationDocumentsDirectory();
      String path = appDir.path + '/images/' + msgObj.id.toString() + '.$ext';
      bool isPresent = await File(path).exists();
      if (!isPresent) {
        if (ext == null) {
          return;
        }

        print(ext);
        var bytes = base64Decode(img64);
        print(bytes);

        File(appDir.path + '/images/' + msgObj.id.toString() + '.$ext')
            .createSync(recursive: true);
        print(appDir.path + '/images/' + msgObj.id.toString() + '.$ext');

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
    print(this.msgObj.isMe);
    print(this.msgObj.haveReachedServer);
    print(this.msgObj.haveReceived);

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
                    if (msgObj.msgType == "img") {
                      if (snapshot.connectionState == ConnectionState.done) {
                        print('snapshot data is here ');
                        print(snapshot.data);
                        Widget child;
                        if (snapshot.data == "does not exist") {
                          child = Center(
                              child: Text("File does not exist",
                                  style: TextStyle(color: Colors.white)));
                        } else {
                          child = Image.file(
                            snapshot.data,
                            // color:Colors.white.withOpacity(.2),
                            fit: BoxFit.contain,
                          );
                        }
                        return Container(
                          padding: EdgeInsets.fromLTRB(5, 5, 5, 15),
                          margin: EdgeInsets.all(5),
                          width: 250,
                          height: 260,
                          decoration: _getDecoration(),
                          child: AspectRatio(aspectRatio: 4 / 5, child: child),
                        );
                      }
                    }
                    return Container(
                      margin: EdgeInsets.all(5),
                      padding: EdgeInsets.fromLTRB(5, 5, 5, 25),
                      height: 260,
                      width: 250,
                      decoration: _getDecoration(),
                      child: Center(
                          child: CircularProgressIndicator(
                        backgroundColor: Colors.black,
                      )),
                    );
                  },
                ),
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
