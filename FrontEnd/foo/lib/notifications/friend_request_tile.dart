import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:foo/custom_overlay.dart';
import 'package:foo/models.dart';
import 'package:foo/profile/profile_test.dart';
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
  Widget child;
  int test = 0;

  @override
  void initState() {
    super.initState();
    if (widget.notification.hasAccepted != null) {
      hasAccepted = widget.notification.hasAccepted;
      child = static();
    } else {
      child = dismissible();
    }
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
          notifsBox.get(widget.notification.notifId);
      currentNotification.hasAccepted = true;
      currentNotification.save();

      _animationController.reverse().whenComplete(() => overlayEntry.remove());
      return true;
    }
    _animationController.reverse().whenComplete(() => overlayEntry.remove());
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
  dismissible() => Dismissible(
        background: Container(
            margin: EdgeInsets.symmetric(vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                    child: Icon(Icons.clear, color: Colors.red),
                    margin: EdgeInsets.only(left: 15)),
                Container(
                    child: Icon(Icons.check, color: Colors.green),
                    margin: EdgeInsets.only(right: 15))
              ],
            )),
        onDismissed: (DismissDirection direction) {
          print(direction.index);
        },
        confirmDismiss: hasAccepted ?? false
            ? (_) => Future.value(false)
            : (DismissDirection direction) async {
                if (direction == DismissDirection.startToEnd) {
                  await showDialog(
                      context: context,
                      builder: (context) => acceptDialog(context));
                } else if (direction == DismissDirection.endToStart) {
                  await showDialog(
                      context: context,
                      builder: (context) => rejectDialog(context));
                }
                CustomOverlay customOverlay = CustomOverlay(
                    context: context,
                    animationController: _animationController);
                bool status;
                if (hasAccepted == true) {
                  showOverlay();
                  status = await handleRequest("accept");
                  if (!status) {
                    customOverlay.show(
                        "Some error has occurred.\n Please check your network connectivity and try again later.");
                    return Future.value(false);
                  }
                  return Future.value(false);
                } else if (hasAccepted == false) {
                  showOverlay();
                  status = await handleRequest("reject");
                  if (!status) {
                    customOverlay.show(
                        "Some error has occurred.\n Please check your network connectivity and try again later.");
                    return Future.value(false);
                  }
                  widget.notification.delete();
                  return Future.value(true);
                }
                return Future.value(false);
              },
        // direction: DismissDirection.startToEnd,
        // background: Container(color: Colors.black),
        // secondaryBackground: Container(color: Colors.yellow),
        key: ValueKey(widget.notification.notifId),
        child: Container(
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
                        imageUrl: 'http://' +
                            localhost +
                            widget.notification.userDpUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, a, s) =>
                            Image.asset('assets/images/dp/dp.jpg')),
                  ),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: hasAccepted ?? false
                            ? "You are now friends with "
                            : "You have a friend request from ",
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

  static() => Container(
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
                  imageUrl:
                      'http://' + localhost + widget.notification.userDpUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, a, s) =>
                      Image.asset('assets/images/dp/dp.jpg')),
            ),
          ),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  text: "You are now friends with ",
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
      ));

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () async {
          var val = await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => Profile(userId: widget.notification.userId)));
          print(val);
          if (val == "accepted") {
            setState(() {
              hasAccepted = true;
              child = static();
            });
          } else if (val == "rejected") {
            setState(() {
              child = Container();
            });
          }
          // Navigator.restorablePushReplacement(
          //     context, te(context, widget.notification));
          // MaterialPageRoute(
          //     builder: (_) => Profile(userId: widget.notification.userId)),
          // );

          // ()=>PageRouteBuilder(pageBuilder: (context, animation, secAnimation) {
          //   return Profile(
          //     userId: widget.notification.userId,
          //   );
          // }, transitionsBuilder: (context, animation, secAnimation, child) {
          //   return SlideTransition(
          //       position:
          //           Tween<Offset>(begin: Offset(1, 0), end: Offset(0, 0))
          //               .animate(animation),
          //       child: child);
          // }));
        },
        child: child ?? Container());
  }
}
