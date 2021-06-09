import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:foo/screens/search_screen.dart';
import 'package:foo/test_cred.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class LikesListScreen extends StatefulWidget {
  final int postId;

  LikesListScreen({this.postId});

  @override
  _LikesListScreenState createState() => _LikesListScreenState();
}

class _LikesListScreenState extends State<LikesListScreen> {
  bool hasFetched = false;
  List friendsList = [];

  @override
  void initState() {
    super.initState();
    getLikesList();
  }

  Future<void> getLikesList() async {
    try {
      var resp = await http.get(Uri.http(
          localhost, '/api/likes_list', {"post_id": widget.postId.toString()}));

      if (resp.statusCode == 200) {
        var respJson = jsonDecode(resp.body);
        print(respJson);

        respJson.forEach((e) {
          print(e);
          friendsList.add(UserTest(
              name: e["username"],
              id: e['id'],
              fname: e['f_name'],
              dp: 'http://' + localhost + e['dp'],
              lname: e['l_name']));
        });
        setState(() {
          hasFetched = true;
        });
      } else {
        print("response 400");
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Something went wrong.")));
    }
  }

  Widget heading() => SliverToBoxAdapter(
        child: Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.fromLTRB(20, 30, 10, 25),
            child: Row(children: [
              Text(
                "Likes",
                style: GoogleFonts.lato(
                  color: Color.fromRGBO(60, 82, 111, 1),
                  fontWeight: FontWeight.w600,
                  fontSize: 30,
                ),
              ),
            ])),
      );

  Widget progressIndicator() => SliverFillRemaining(
        child: Container(
          child: Center(
            child: SizedBox(
              height: 40,
              width: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.green),
              ),
            ),
          ),
        ),
      );

  Widget friendsListWidget() => SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return SearchTile(
              user: friendsList[index],
            );
          },
          childCount: friendsList.length,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.only(top: 30),
          child: CustomScrollView(physics: BouncingScrollPhysics(), slivers: [
            heading(),
            hasFetched ? friendsListWidget() : progressIndicator()
          ]),
        ));
  }
}
