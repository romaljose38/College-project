import 'package:flutter/material.dart';
import 'package:foo/custom_overlay.dart';
import 'package:foo/models.dart';
import 'package:foo/test_cred.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:timeago/timeago.dart' as timeago;

class Tile extends StatefulWidget {
  final Notifications notification;

  Tile({this.notification});

  @override
  _TileState createState() => _TileState();
}

class _TileState extends State<Tile> with SingleTickerProviderStateMixin {
  OverlayEntry overlayEntry;
  bool hasAccepted;
  AnimationController _animationController;
  Animation _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  @override
  void dispose() {
    super.dispose();
    _animationController.dispose();
  }

  void showOverlay() {
    OverlayState overlayState = Overlay.of(context);
    overlayEntry = OverlayEntry(builder: (context) {
      return FadeTransition(
        opacity: _animation,
        child: Scaffold(
          backgroundColor: Colors.black.withOpacity(.2),
          body: Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.purple,
              strokeWidth: 1,
            ),
          ),
        ),
      );
    });

    _animationController
        .forward()
        .whenComplete(() => overlayState.insert(overlayEntry));
  }

  Future<bool> handleRequest(String action) async {
    var resp = await http.get(Uri.http(localhost, '/api/handle_request',
        {'id': widget.notification.notifId.toString(), 'action': action}));
    if (resp.statusCode == 200) {
      Box notifsBox = Hive.box("Notifications");
      Notifications currentNotification =
          notifsBox.get(widget.notification.timeCreated.toString());
      currentNotification.hasAccepted = true;
      currentNotification.save();
      _animationController.reverse().whenComplete(() => overlayEntry.remove());
      return true;
    }
    return false;
  }

  AlertDialog acceptDialog(context) => AlertDialog(
          title: Text("Please confirm"),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text("Do you want to accept this request?"),
          actions: [
            TextButton(
                child: Text("Yes"),
                onPressed: () async {
                  hasAccepted = true;

                  Navigator.pop(context);
                }),
            TextButton(
                child: Text("No"),
                onPressed: () {
                  Navigator.pop(context);
                }),
          ]);

  AlertDialog rejectDialog(context) => AlertDialog(
          title: Text("Please confirm"),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text("Do you want to delete this request?"),
          actions: [
            TextButton(
                child: Text("Yes"),
                onPressed: () async {
                  hasAccepted = false;

                  Navigator.pop(context);
                }),
            TextButton(
                child: Text("No"),
                onPressed: () {
                  Navigator.pop(context);
                }),
          ]);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      onDismissed: (DismissDirection direction) {
        print(direction.index);
      },
      confirmDismiss: (DismissDirection direction) async {
        if (direction == DismissDirection.startToEnd) {
          await showDialog(
              context: context, builder: (context) => acceptDialog(context));
        } else if (direction == DismissDirection.endToStart) {
          await showDialog(
              context: context, builder: (context) => rejectDialog(context));
          await handleRequest("reject");
        }
        CustomOverlay customOverlay = CustomOverlay(
            context: context, animationController: _animationController);
        bool status;
        if (hasAccepted == true) {
          showOverlay();
          status = await handleRequest("accept");
          if (!status) {
            customOverlay.show(
                "Some error has occurred.\n Please check your network connectivity and try again later.");
          }
          return Future.value(false);
        } else if (hasAccepted == false) {
          showOverlay();
          status = await handleRequest("reject");
          if (!status) {
            customOverlay.show(
                "Some error has occurred.\n Please check your network connectivity and try again later.");
          }
          return Future.value(false);
        }
        return Future.value(true);
      },
      // direction: DismissDirection.startToEnd,
      // background: Container(color: Colors.black),
      // secondaryBackground: Container(color: Colors.yellow),
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
                  text: "You have a friend request from ",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w300,
                  ),
                  children: [
                    TextSpan(
                      text: this.widget.notification.userName,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 5),
              Text(
                timeago.format(this.widget.notification.timeCreated),
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
