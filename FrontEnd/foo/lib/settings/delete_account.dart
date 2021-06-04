import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:foo/auth/login.dart';
import 'package:foo/custom_overlay.dart';
import 'package:foo/test_cred.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:ionicons/ionicons.dart';
import 'dart:math' show pi;
import 'package:http/http.dart' show post;
import 'package:shared_preferences/shared_preferences.dart';

class DeleteConfirm extends StatefulWidget {
  @override
  _DeleteConfirmState createState() => _DeleteConfirmState();
}

class _DeleteConfirmState extends State<DeleteConfirm>
    with SingleTickerProviderStateMixin {
  TextEditingController _passwordController = TextEditingController();
  FocusNode _focusNode = FocusNode();
  AnimationController _controller;
  SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
  }

  wipeEveryThing() async {
    Hive.box('Threads').clear();
    Hive.box('Feed').clear();
    Hive.box('Notifications').clear();
    Hive.box('MyStories').clear();
    await prefs.clear();
  }

  deleteAccount() async {
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    }

    CustomOverlay overlay =
        CustomOverlay(context: context, animationController: _controller);
    //
    bool shouldDelete = false;

    //
    await showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text("Are you sure?"),
            actions: [
              TextButton(
                  onPressed: () {
                    shouldDelete = true;
                    Navigator.pop(ctx);
                  },
                  child: Text("Yes")),
              TextButton(
                  onPressed: () {
                    shouldDelete = false;
                    Navigator.pop(ctx);
                  },
                  child: Text("No")),
            ],
          );
        });
    //

    if (shouldDelete) {
      prefs = await SharedPreferences.getInstance();
      try {
        var response = await post(Uri.http(localhost, '/api/delete_account'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode({
              'password': _passwordController.text,
              'id': prefs.getInt('id').toString(),
            }));
        _focusNode.unfocus();
        if (response.statusCode == 200) {
          await wipeEveryThing();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (Route<dynamic> route) => false,
          );
        } else if (response.statusCode == 417) {
          print("password incorrect");

          overlay.show("Password incorrect.\n Please enter correct password.");
          print("not showing");
        } else {
          print("error");
        }
      } catch (e) {}
    }
  }

  actionButtons() => GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(Icons.arrow_back, color: Colors.black),
            )),
      );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        // physics: NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: size.height * .1),
            Align(
              alignment: Alignment.center,
              child: actionButtons(),
            ),
            SizedBox(height: size.height * .14),
            Align(
              alignment: Alignment.center,
              child: deleteIcon(),
            ),
            Column(children: [
              SizedBox(height: size.height * .13),
              Align(
                  alignment: Alignment.center,
                  child: Text("Are you sure?",
                      style: GoogleFonts.raleway(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ))),
              SizedBox(height: 9),
              Align(
                  alignment: Alignment.center,
                  child: Text("This action cannot be undone.",
                      style: GoogleFonts.raleway(
                        fontSize: 15,
                        color: Colors.red.withOpacity(.6),
                        fontWeight: FontWeight.w600,
                      ))),
              SizedBox(height: size.height * .04),
              // Text(
              //   "Enter your current password",
              //   style: GoogleFonts.raleway(
              //       fontSize: 13,
              //       color: Colors.grey.shade500,
              //       fontWeight: FontWeight.w500),
              // ),
              Container(
                width: 200,
                child: TextField(
                  // maxLines: 8,
                  focusNode: _focusNode,
                  controller: _passwordController,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  cursorColor: Colors.black,
                  cursorWidth: .3,
                  style: GoogleFonts.lato(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: "Enter your current password",
                    hintStyle: GoogleFonts.raleway(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500),
                    isDense: true,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.grey.withOpacity(.4), width: .6),
                    ),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.grey.withOpacity(.4), width: .6),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.grey.withOpacity(.4), width: .8),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: deleteAccount,
                child: Container(
                    width: 100,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Center(
                        child: Text("Confirm",
                            style: GoogleFonts.raleway(
                                letterSpacing: 1.04,
                                fontSize: 13,
                                color: Colors.white)))),
              )
            ])
          ],
        ),
      ),
    );
  }
}

deleteIcon() => Container(
      height: 120,
      width: 100,
      child: Align(
        alignment: Alignment.center,
        child: Icon(Ionicons.warning_outline, color: Colors.red, size: 60),
      ),
    );
