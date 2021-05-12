import 'dart:convert';

import 'package:flappy_search_bar/flappy_search_bar.dart';
import 'package:flappy_search_bar/search_bar_style.dart';
import 'package:flutter/material.dart';
import 'package:foo/colour_palette.dart';
import 'package:foo/profile/profile_test.dart';
import 'package:foo/test_cred.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class SearchScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SearchBar<UserTest>(
            loader: const Center(
                child: CircularProgressIndicator(
              strokeWidth: 1,
              backgroundColor: Colors.purple,
            )),
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
  final String l_name;
  final String f_name;
  final int id;
  UserTest({this.name, this.id, this.l_name, this.f_name});
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
        f_name: e['f_name'],
        l_name: e['l_name']));
  });
  print(returList);
  return returList;
}

class SearchTile extends StatelessWidget {
  UserTest user;

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
                    Text(this.user.name,
                        style: GoogleFonts.raleway(
                            fontWeight: FontWeight.w600, fontSize: 17)),
                    SizedBox(height: 6),
                    Text(this.user.f_name, style: TextStyle(fontSize: 13)),
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
