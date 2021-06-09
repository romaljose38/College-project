import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:foo/models.dart';
import 'package:foo/notifications/friend_request_tile.dart';
import 'package:foo/notifications/mention_tile.dart';
import 'package:foo/profile/profile_test.dart';
import 'package:foo/test_cred.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  void initState() {
    super.initState();
    removePrefs();
  }

  Future<void> removePrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("hasNotif", false);
  }

  Future<String> getDp() async {
    var dir = await getApplicationDocumentsDirectory();
    return dir.path + "/images/dp/dp.jpg";
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.only(top: 30),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // IconButton(
                  //     icon: Icon(Icons.arrow_back, size: 18),
                  //     onPressed: () {
                  //       // return _showModal(context);
                  //     }),
                  // Spacer(),
                  Container(
                    margin: EdgeInsets.only(right: 5),
                    width: 50,
                    height: 50,
                    child: Stack(children: [
                      FutureBuilder(
                          future: getDp(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              return Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: FileImage(
                                      File(snapshot.data),
                                    ),
                                  ),
                                ),
                              );
                              // return CircleAvatar(
                              //   child: ClipOval(
                              //     child: Image(
                              //       height: 60.0,
                              //       width: 60.0,
                              //       image: FileImage(File(snapshot.data)),
                              //       fit: BoxFit.cover,
                              //     ),
                              //   ),
                              // );
                            }
                            return SizedBox(
                              height: 50,
                              width: 50,
                              child: CircularProgressIndicator(
                                backgroundColor: Colors.purple,
                              ),
                            );
                          }),
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
                            notifications.sort((a, b) =>
                                b.timeCreated.compareTo(a.timeCreated));
                          }
                          return ListView.builder(
                            physics: BouncingScrollPhysics(),
                            itemCount: notifications.length ?? 0,
                            itemBuilder: (context, index) {
                              if (notifications[index].type ==
                                  NotificationType.friendRequest) {
                                return Tile(
                                  size: size,
                                  notification: notifications[index],
                                );
                              } else if (notifications[index].type ==
                                  NotificationType.mention) {
                                return MentionTile(
                                  size: size,
                                  notification: notifications[index],
                                );
                              } else if (notifications[index].type ==
                                  NotificationType.postLike) {
                                return PostLikeTile(
                                  size: size,
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

class PostLikeTile extends StatelessWidget {
  final Notifications notification;
  final Size size;
  PostLikeTile({this.notification, this.size});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            PageRouteBuilder(pageBuilder: (context, animation, secAnimation) {
              return Profile(userId: notification.userId);
            }, transitionsBuilder: (context, animation, secAnimation, child) {
              return SlideTransition(
                child: child,
                position: Tween<Offset>(
                  begin: Offset(1, 0),
                  end: Offset(0, 0),
                ).animate(animation),
              );
            }));
      },
      child: Container(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 40),
          margin: EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              // Spacer(flex: 1),
              Container(
                height: 50,
                width: 50,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(27),
                  child: CachedNetworkImage(
                      imageUrl: 'http://' + localhost + notification.userDpUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, a, s) =>
                          Image.asset('assets/images/dp/dp.jpg')),
                ),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: size.width - 110,
                    child: RichText(
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        text: this.notification.userName,
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(
                            text: " has liked your post.",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    timeago.format(this.notification.timeCreated),
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
