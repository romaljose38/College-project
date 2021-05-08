import 'package:flutter/material.dart';
import 'package:foo/notifications/friend_request_tile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
// import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart' as pathProvider;

class NotificationScreen extends StatelessWidget {
  // _showModal(BuildContext context) {
  //   showCustomModalBottomSheet(
  //       context: context,
  //       containerWidget: (context, animation, child) {
  //         return child;
  //       },
  //       backgroundColor: Colors.transparent,
  //       builder: (context) {
  //         return Scaffold(
  //           backgroundColor: Colors.transparent,
  //           body: Container(
  //             alignment: Alignment.center,
  //             child: ClipRRect(
  //               borderRadius: BorderRadius.circular(25),
  //               // color: Colors.transparent,
  //               child: Container(
  //                   width: MediaQuery.of(context).size.width * .9,
  //                   height: MediaQuery.of(context).size.height * .9,
  //                   decoration: BoxDecoration(
  //                     color: Colors.white,
  //                     borderRadius: BorderRadius.circular(25),
  //                   ),
  //                   child: Column(
  //                     children: [
  //                       Align(
  //                         alignment: Alignment.centerLeft,
  //                         child: Padding(
  //                           padding: EdgeInsets.fromLTRB(20, 7, 10, 20),
  //                           child: Text(
  //                             "Conversations",
  //                             style: TextStyle(
  //                               fontSize: 25,
  //                               fontWeight: FontWeight.w700,
  //                               letterSpacing: .05,
  //                             ),
  //                           ),
  //                         ),
  //                       ),
  //                       Expanded(
  //                         child: Container(
  //                           margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
  //                           decoration: BoxDecoration(
  //                             color: Colors.white,
  //                             borderRadius: BorderRadius.only(
  //                               topLeft: Radius.circular(50),
  //                             ),
  //                             boxShadow: [
  //                               BoxShadow(
  //                                 color: Colors.black.withOpacity(.1),
  //                                 offset: Offset(-1, -1),
  //                                 blurRadius: 5,
  //                               ),
  //                             ],
  //                           ),
  //                           child: ClipRRect(
  //                             borderRadius: BorderRadius.only(
  //                               topLeft: Radius.circular(50),
  //                             ),
  //                             child: Container(
  //                               padding: EdgeInsets.only(left: 40, top: 20),
  //                               child: ListView(
  //                                 children: [
  //                                   // Divider(),
  //                                   Tile(),
  //                                 ],
  //                               ),
  //                             ),
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   )),
  //             ),
  //           ),
  //         );
  //       });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white.withOpacity(.6),
        body: Padding(
          padding: const EdgeInsets.only(top: 30),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                      icon: Icon(Icons.arrow_back, size: 18),
                      onPressed: () {
                        // return _showModal(context);
                      }),
                  Spacer(),
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Stack(children: [
                      CircleAvatar(
                        child: ClipOval(
                          child: Image(
                            height: 60.0,
                            width: 60.0,
                            image: AssetImage("assets/images/user0.png"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 19,
                        top: 5,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                              color: Colors.purpleAccent,
                              borderRadius: BorderRadius.circular(50)),
                        ),
                      ),
                    ]),
                  ),
                  SizedBox(width: 20)
                ],
              ),
              // SizedBox(height: 30),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 7, 10, 20),
                  child: Text(
                    "Conversations",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .05,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.1),
                        offset: Offset(-1, -1),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                    ),
                    child: Container(
                      padding: EdgeInsets.only(left: 40, top: 20),
                      child: ListView(
                        children: [
                          // Divider(),
                          Tile(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
        // body: ValueListenableBuilder(
        //     valueListenable: Hive.box("Notifications").listenable(),
        //     builder: (context, box, index) {
        //       List notifications = box.values.toList() ?? [];
        //       if (notifications.length > 1) {
        //         // notifications.sort((a,b)=>a.)
        //       }
        //       return ListView.builder(
        //         itemCount: notifications.length ?? 0,
        //         itemBuilder: (context, index) {
        //           return FriendRequestTile(
        //             notification: notifications[index],
        //           );
        //         },
        //       );
        //     }),
        );
  }
}

class Tile extends StatelessWidget {
  // GlobalKey key;
  @override
  Widget build(BuildContext context) {
    return Dismissible(
      direction: DismissDirection.startToEnd,
      key: Key('test'),
      child: Container(
          child: Row(
        children: [
          // Spacer(flex: 1),
          CircleAvatar(
            child: ClipOval(
              child: Image(
                height: 60.0,
                width: 60.0,
                image: AssetImage("assets/images/user4.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  text: "Pranav ",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    TextSpan(
                      text: "started following you. ",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w300,
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: 5),
              Text(
                "5 min ago",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          // Spacer(flex: 2),
        ],
      )),
    );
  }
}
