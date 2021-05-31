import 'package:flutter/material.dart';
import 'package:foo/models.dart';
import 'package:foo/notifications/friend_request_tile.dart';
import 'package:foo/notifications/mention_tile.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class NotificationScreen extends StatelessWidget {
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
                    "Notifications",
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
                      padding: EdgeInsets.only(left: 40, top: 30),

                      child: ValueListenableBuilder(
                        valueListenable: Hive.box("Notifications").listenable(),
                        builder: (context, box, index) {
                          List notifications = box.values.toList() ?? [];
                          print(notifications);
                          if (notifications.length > 1) {
                            // notifications.sort((a,b)=>a.)
                          }
                          return ListView.builder(
                            itemCount: notifications.length ?? 0,
                            itemBuilder: (context, index) {
                              if (notifications[index].type ==
                                  NotificationType.friendRequest) {
                                return Tile(
                                  notification: notifications[index],
                                );
                              } else if (notifications[index].type ==
                                  NotificationType.mention) {
                                return MentionTile(
                                  notification: notifications[index],
                                );
                              }
                              return Container();
                            },
                          );
                        },
                      ),
                      // child: ListView(
                      //   children: [
                      //     // Divider(),
                      //     Tile(),
                      //   ],
                      // ),
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
