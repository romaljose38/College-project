import 'package:flutter/material.dart';
import 'package:foo/notifications/friend_request_tile.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as pathProvider;

class NotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white.withOpacity(.6),
      body: ValueListenableBuilder(
          valueListenable: Hive.box("Notifications").listenable(),
          builder: (context, box, index) {
            List notifications = box.values.toList() ?? [];
            if (notifications.length > 1) {
              // notifications.sort((a,b)=>a.)
            }
            return ListView.builder(
              itemCount: notifications.length ?? 0,
              itemBuilder: (context, index) {
                return FriendRequestTile(
                  notification: notifications[index],
                );
              },
            );
          }),
    );
  }
}
