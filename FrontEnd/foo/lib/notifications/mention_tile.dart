import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:foo/models.dart';
import 'package:foo/screens/comment_screen.dart';
import 'package:foo/test_cred.dart';
import 'package:timeago/timeago.dart' as timeago;

class MentionTile extends StatelessWidget {
  final Notifications notification;
  MentionTile({this.notification});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            PageRouteBuilder(pageBuilder: (context, animation, secAnimation) {
              return CommentScreen(
                postId: notification.postId,
                heroIndex: notification.postId,
              );
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
          margin: EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              // Spacer(flex: 1),
              CircleAvatar(
                child: ClipOval(
                  child: Image(
                    height: 60.0,
                    width: 60.0,
                    image: CachedNetworkImageProvider(
                        'http://$localhost' + (notification?.userDpUrl ?? "")),
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
                      text: this.notification.userName,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text: " mentioned you in a comment.",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
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
