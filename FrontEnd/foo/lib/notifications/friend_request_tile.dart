import 'package:flutter/material.dart';
import 'package:foo/models.dart';
import 'package:foo/test_cred.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FriendRequestTile extends StatefulWidget {
  final Notifications notification;
  FriendRequestTile({Key key, this.notification}) : super(key: key);

  @override
  _FriendRequestTileState createState() => _FriendRequestTileState();
}

class _FriendRequestTileState extends State<FriendRequestTile> {
  int friendId;
  SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    friendId = widget.notification.userId;
    setPrefs();
  }

  Future<void> setPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> handleRequest(String action) async {
    var resp = await http.get(Uri.http(localhost, '/api/accept_request', {
      'username': _prefs.getString("username"),
      'frndId': friendId.toString(),
      'action': action
    }));
    if (resp.statusCode == 200) {
      Box notifsBox = Hive.box("Notifications");
      Notifications currentNotification =
          notifsBox.get(widget.notification.timeCreated.toString());
      currentNotification.hasAccepted = true;
      currentNotification.save();
    }
  }

  Widget request() => Container(
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "${widget.notification.userName} send you a friend request",
                textAlign: TextAlign.left,
              ),
            ),
            // SizedBox(height: 6),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    return handleRequest("accept");
                  },
                  child: Text("Accept"),
                ),
                TextButton(
                  onPressed: () {
                    return handleRequest("reject");
                  },
                  child: Text("Reject"),
                ),
              ],
            )
          ],
        ),
      );

  Widget requestAccepted() => Container(
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "You are now friends with ${widget.notification.userName}",
                textAlign: TextAlign.left,
              ),
            ),
            // SizedBox(height: 6),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      // color: Color.fromRGBO(150, 15, 100, .1)),
      child: (widget.notification.hasAccepted ?? false)
          ? requestAccepted()
          : request(),
    );
  }
}
