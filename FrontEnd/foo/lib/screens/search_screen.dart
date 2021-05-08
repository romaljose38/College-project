import 'dart:convert';

import 'package:flappy_search_bar/flappy_search_bar.dart';
import 'package:flappy_search_bar/search_bar_style.dart';
import 'package:flutter/material.dart';
import 'package:foo/test_cred.dart';
import 'package:http/http.dart' as http;

class SearchScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SearchBar<UserTest>(
            minimumChars: 1,
            onSearch: search,
            searchBarStyle: SearchBarStyle(),
            onError: (err) {
              print(err);
              return Container();
            },
            onItemFound: (UserTest user, int index) {
              return ListTile(
                title: Text(user.name),
              );
            },
          ),
        ),
      ),
    );
  }
}

class UserTest {
  final String name;
  UserTest({this.name});
}

Future<List<UserTest>> search(String search) async {
  print(search);
  var resp =
      await http.get(Uri.http(localhost, '/api/users', {'name': search}));
  var respJson = jsonDecode(resp.body)['resp'];
  var list = jsonDecode(respJson);
  List<UserTest> returList = [];
  list.forEach((e) {
    print(e);
    returList.add(UserTest(name: e["fields"]["username"]));
  });
  print(returList);
  return returList;
}
