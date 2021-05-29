import 'dart:async';
import 'dart:convert';

import 'package:flappy_search_bar/flappy_search_bar.dart';
import 'package:flappy_search_bar/search_bar_style.dart';
import 'package:flutter/material.dart';
import 'package:foo/profile/profile_test.dart';
import 'package:foo/test_cred.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SearchScreen extends StatelessWidget {
  Future<List> getUserList() async {
    var prefs = await SharedPreferences.getInstance();
    try {
      var resp = await http.get(Uri.http(localhost, 'api/people_you_may_know',
          {"id": prefs.getInt('id').toString()}));

      if (resp.statusCode == 200) {
        var respJson = jsonDecode(resp.body);
        List<UserTest> returList = [];
        respJson.forEach((e) {
          print(e);
          returList.add(UserTest(
              name: e["username"],
              id: e['id'],
              fname: e['f name'],
              lname: e['l_name']));
        });
        print(returList);
        return returList;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  peopleYouMayKnow() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(left: 20, top: 8, bottom: 8),
            child: Text("People you may know",
                style: GoogleFonts.lato(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: FutureBuilder(
                future: getUserList(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    var userList = snapshot.data;
                    return ListView.builder(
                        itemCount: userList.length,
                        itemBuilder: (context, index) {
                          return SearchTile(
                            user: userList[index],
                          );
                        });
                  }
                  return Center(
                      child: CircularProgressIndicator(
                    strokeWidth: 1,
                  ));
                }),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: SearchBar<UserTest>(
            loader: const Center(
                child: CircularProgressIndicator(
              strokeWidth: 1,
              backgroundColor: Colors.purple,
            )),
            searchBarPadding: EdgeInsets.symmetric(horizontal: 15),
            placeHolder: peopleYouMayKnow(),
            minimumChars: 1,
            onSearch: search,
            searchBarStyle: SearchBarStyle(),
            onError: (err) {
              print(err);
              return Container();
            },
            onItemFound: (UserTest user, int index) {
              return SearchTile(user: user);
            },
          ),
        ),
      ),
    );
  }
}

class UserTest {
  final String name;
  final String lname;
  final String fname;
  final int id;
  UserTest({this.name, this.id, this.lname, this.fname});
}

Future<List<UserTest>> search(String search) async {
  print(search);
  var resp =
      await http.get(Uri.http(localhost, '/api/users', {'name': search}));
  var respJson = jsonDecode(resp.body);
  print(respJson);

  List<UserTest> returList = [];
  respJson.forEach((e) {
    print(e);
    returList.add(UserTest(
        name: e["username"],
        id: e['id'],
        fname: e['f name'],
        lname: e['l_name']));
  });
  print(returList);
  return returList;
}

class SearchTile extends StatelessWidget {
  final UserTest user;

  SearchTile({this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            print(user.id);
            Navigator.push(
              context,
              PageRouteBuilder(
                  pageBuilder: (context, animation, secondAnimation) {
                return Profile(userId: user.id);
              }, transitionsBuilder: (context, animation, secAnimation, child) {
                return SlideTransition(
                  position:
                      Tween<Offset>(begin: Offset(1, 0), end: Offset(0, 0))
                          .animate(animation),
                  child: child,
                );
              }
                  // transitionsBuilder: (context,animation,)
                  ),
            );
          },
          child: Container(
            width: MediaQuery.of(context).size.width * .95,
            // margin: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              // borderRadius: BorderRadius.circular(20),
              // boxShadow: [
              //   BoxShadow(
              //     color: Palette.lavender,
              //     offset: Offset(0, 0),
              //     blurRadius: 7,
              //     spreadRadius: 1,
              //   )
              // ]
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  child: ClipOval(
                    child: Image(
                      height: 60.0,
                      width: 60.0,
                      image: AssetImage('assets/images/user4.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(
                  width: 15,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(this.user.name ?? "",
                        style: GoogleFonts.raleway(
                            fontWeight: FontWeight.w600, fontSize: 17)),
                    SizedBox(height: 6),
                    Text(this.user.fname ?? "", style: TextStyle(fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ),
        Divider(),
      ],
    );
  }
}
