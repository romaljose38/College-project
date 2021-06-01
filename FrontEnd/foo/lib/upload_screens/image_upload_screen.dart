import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foo/landing_page.dart';
import 'package:foo/screens/feed_icons.dart';
import 'package:foo/screens/models/post_model.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foo/custom_overlay.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../test_cred.dart';

class ImageUploadScreen extends StatefulWidget {
  final File mediaInserted;
  ImageUploadScreen({this.mediaInserted});

  @override
  _ImageUploadScreenState createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  Animation _animation;
  TextEditingController captionController;
  bool uploading = false;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 100));
    _animation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    captionController = TextEditingController();
  }

  @override
  void dispose() {
    _animationController.dispose();
    captionController.dispose();
    super.dispose();
  }

  Future<void> _upload(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('username');
    var uri =
        Uri.http(localhost, '/api/upload'); //This web address has to be changed
    var request = http.MultipartRequest('POST', uri)
      ..fields['username'] = username
      ..fields['type'] = 'img'
      ..fields['caption'] = captionController.text
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        widget.mediaInserted.path,
      ));
    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        print('Uploaded');
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => LandingPage()));
      }
    } catch (e) {
      print(e);
      CustomOverlay overlay = CustomOverlay(
          context: context, animationController: _animationController);
      overlay.show("Sorry. Upload Failed.\n Please try again later.");
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(20.0),
        child: Container(
          padding: EdgeInsets.only(top: 30.0, left: 4.0),
          color: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
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
                  height: size.height * .4,
                  width: size.width,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(0, 1, 25, 1),
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(70),
                    ),
                  ))),
          Positioned(
            top: size.height * .4,
            child: Container(
              height: size.height * .6,
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
              padding: const EdgeInsets.only(top: 100),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                        width: size.width * 0.9,
                        height: size.width * 0.9,
                        margin:
                            //EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                            EdgeInsets.only(
                                top: 40, bottom: 10, left: 20, right: 20),
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
                            ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                    height: size.height * 0.7,
                                    width: size.height * 0.7,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        image: DecorationImage(
                                          image:
                                              FileImage(widget.mediaInserted),
                                          fit: BoxFit.cover,
                                        ))
                                    // decoration: hasImage
                                    //     ? backgroundImage()
                                    //     : backgroundColor(),
                                    // child: Center(
                                    //   child: IconButton(
                                    //       icon: Icon(Icons.play_arrow),
                                    //       color: Colors.white,
                                    //       iconSize: 80,
                                    //       onPressed: () {
                                    //         Navigator.of(context).push(
                                    //             MaterialPageRoute(
                                    //                 builder: (context) =>
                                    //                     VideoPlayerProvider(
                                    //                       videoFile: widget
                                    //                           .mediaInserted,
                                    //                     )));
                                    //       }),
                                    // ),
                                    )),
                            // Align(
                            //   alignment: Alignment.topRight,
                            //   child: ClipRRect(
                            //     borderRadius: BorderRadius.circular(30),
                            //     child: GestureDetector(
                            //       onTap: showOverlay,
                            //       child: Container(
                            //         height: 35,
                            //         width: 40,
                            //         color: Colors.black.withOpacity(0.2),
                            //         child: BackdropFilter(
                            //           child: Icon(Icons.edit,
                            //               size: 18, color: Colors.white),
                            //           filter: ImageFilter.blur(
                            //             sigmaX: 2.0,
                            //             sigmaY: 2.0,
                            //           ),
                            //         ),
                            //       ),
                            //     ),
                            //   ),
                            // ),
                          ],
                        )),
                    SizedBox(height: 20),
                    // Container(
                    //   margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    //   child: Row(
                    //     children: [
                    //       Expanded(
                    //         child: Container(
                    //           padding: EdgeInsets.only(left: 4),
                    //           child: Text(
                    //             "Blurred background",
                    //             style: GoogleFonts.lato(
                    //               fontSize: 13,
                    //               color: Color.fromRGBO(6, 8, 53, 1),
                    //               fontWeight: FontWeight.w600,
                    //             ),
                    //           ),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    SizedBox(height: 20),
                    Container(
                      height: 45,
                      width: MediaQuery.of(context).size.width * 0.9,
                      decoration: BoxDecoration(
                        // borderRadius: BorderRadius.only(
                        //   topLeft: Radius.circular(10),
                        //   bottomLeft: Radius.circular(10),
                        // ),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        border: Border.all(
                          width: 0.2,
                          color: Colors.black.withOpacity(.3),
                        ),
                      ),
                      child: TextField(
                        controller: captionController,
                        decoration: InputDecoration(
                          hintText: "Add a caption",
                          hintStyle: GoogleFonts.lato(
                              fontSize: 12, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(5),
                        ),
                        cursorColor: Colors.green,
                        cursorWidth: 1,
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
              onPressed: () => _upload(context),
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

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     body: SingleChildScrollView(
  //       child: Container(
  //         child: Column(
  //           children: [
  //             Container(
  //               margin: EdgeInsets.all(10),
  //               child: Stack(
  //                 alignment: Alignment.center,
  //                 children: [
  //                   ClipRRect(
  //                     borderRadius: BorderRadius.circular(25),
  //                     child: ImageFiltered(
  //                       imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
  //                       child: Container(
  //                         padding: EdgeInsets.only(top: 10.0),
  //                         width: double.infinity,
  //                         height: 465.0,
  //                         decoration: BoxDecoration(
  //                             color: Colors.white,
  //                             // borderRadius: BorderRadius.only(bottomLeft: Radius.circular(25),bottomRight: Radius.circular(25)),
  //                             image: DecorationImage(
  //                               //image: AssetImage(posts[0].imageUrl),
  //                               image: FileImage(widget.mediaInserted),
  //                               fit: BoxFit.cover,
  //                             )),
  //                       ),
  //                     ),
  //                   ),
  //                   Container(
  //                     padding: EdgeInsets.only(top: 10.0),
  //                     width: double.infinity,
  //                     height: 471.0,
  //                     decoration: BoxDecoration(
  //                       color: Colors.transparent,
  //                       borderRadius: BorderRadius.circular(25.0),
  //                     ),
  //                     child: Column(
  //                       children: <Widget>[
  //                         Padding(
  //                           padding: EdgeInsets.symmetric(vertical: 10.0),
  //                           child: Column(
  //                             children: <Widget>[
  //                               Row(
  //                                 mainAxisAlignment:
  //                                     MainAxisAlignment.spaceBetween,
  //                                 children: <Widget>[
  //                                   IconButton(
  //                                     icon: Icon(Icons.arrow_back),
  //                                     iconSize: 20.0,
  //                                     color: Colors.white,
  //                                     onPressed: () => Navigator.pop(context),
  //                                   ),
  //                                   Container(
  //                                     width: 30.0,
  //                                     height: 30.0,
  //                                     decoration: BoxDecoration(
  //                                       shape: BoxShape.circle,
  //                                       boxShadow: [
  //                                         BoxShadow(
  //                                           color: Colors.black45,
  //                                           offset: Offset(0, 2),
  //                                           blurRadius: 6.0,
  //                                         ),
  //                                       ],
  //                                     ),
  //                                     child: CircleAvatar(
  //                                       child: ClipOval(
  //                                         child: Image(
  //                                           height: 50.0,
  //                                           width: 50.0,
  //                                           image: AssetImage(stories[0]),
  //                                           fit: BoxFit.cover,
  //                                         ),
  //                                       ),
  //                                     ),
  //                                   ),
  //                                   IconButton(
  //                                     icon: Icon(Feed.colon),
  //                                     color: Colors.white,
  //                                     onPressed: () => print('More'),
  //                                   ),
  //                                 ],
  //                               ),
  //                               InkWell(
  //                                 onDoubleTap: () => print('Like post'),
  //                                 child: Container(
  //                                   height: 330,
  //                                   decoration: BoxDecoration(
  //                                     color: Colors.white.withOpacity(.2),
  //                                     borderRadius: BorderRadius.circular(25),
  //                                   ),
  //                                   width: double.infinity,
  //                                   margin: EdgeInsets.fromLTRB(18, 10, 18, 5),
  //                                   child: AspectRatio(
  //                                     aspectRatio: 4 / 5,
  //                                     child: Container(
  //                                       decoration: BoxDecoration(
  //                                         borderRadius:
  //                                             BorderRadius.circular(25.0),
  //                                         boxShadow: [
  //                                           BoxShadow(
  //                                             color: Colors.black45,
  //                                             offset: Offset(0, 3),
  //                                             blurRadius: 8.0,
  //                                           ),
  //                                         ],
  //                                         image: DecorationImage(
  //                                           image:
  //                                               FileImage(widget.mediaInserted),
  //                                           //AssetImage(posts[0].imageUrl),
  //                                           fit: BoxFit.contain,
  //                                         ),
  //                                       ),
  //                                     ),
  //                                   ),
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             SizedBox(
  //               height: 20,
  //             ),
  //             Padding(
  //               padding:
  //                   const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
  //               child: Container(
  //                 decoration: BoxDecoration(
  //                   border: Border.all(color: Colors.black26, width: 1),
  //                   borderRadius: BorderRadius.circular(10),
  //                 ),
  //                 child: TextField(
  //                   controller: captionController,
  //                   maxLength: 30,
  //                   maxLengthEnforcement: MaxLengthEnforcement.enforced,
  //                   decoration: InputDecoration(
  //                     hintText: "Caption",
  //                     contentPadding: EdgeInsets.fromLTRB(10, 5, 5, 5),
  //                     border: InputBorder.none,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //             uploading
  //                 ? Padding(
  //                     padding: const EdgeInsets.all(20.0),
  //                     child: CircularProgressIndicator(
  //                       strokeWidth: 1,
  //                     ))
  //                 : Container(),
  //             ElevatedButton(
  //               child: Text("Upload"),
  //               onPressed: () {
  //                 setState(() {
  //                   uploading = true;
  //                 });
  //                 return _upload(context);
  //               },
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
