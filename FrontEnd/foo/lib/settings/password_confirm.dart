import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:foo/custom_overlay.dart';
import 'package:foo/test_cred.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'dart:math' show pi;
import 'package:http/http.dart' show post;
import 'package:shared_preferences/shared_preferences.dart';

class PasswordConfirm extends StatefulWidget {
  @override
  _PasswordConfirmState createState() => _PasswordConfirmState();
}

class _PasswordConfirmState extends State<PasswordConfirm>
    with SingleTickerProviderStateMixin {
  TextEditingController _passwordController = TextEditingController();
  PageController _pageController = PageController();
  AnimationController _controller;
  TextEditingController _newPasswordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();

  var curPasswordErr;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
  }

  check_password() async {
    CustomOverlay overlay =
        CustomOverlay(context: context, animationController: _controller);
    var prefs = await SharedPreferences.getInstance();
    try {
      var response = await post(Uri.http(localhost, '/api/check_password'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode({
            'password': _passwordController.text,
            'id': prefs.getInt('id').toString(),
          }));
      if (response.statusCode == 200) {
        print("password correct");
        _pageController.animateToPage(1,
            duration: Duration(milliseconds: 100), curve: Curves.easeIn);
      } else if (response.statusCode == 417) {
        print("password incorrect");
        setState(() {
          curPasswordErr = "Incorrect";
        });
        overlay.show("Password incorrect.\n Please enter correct password.");
      } else {
        print("error");
      }
    } catch (e) {}
  }

  change_password() async {
    CustomOverlay overlay =
        CustomOverlay(context: context, animationController: _controller);
    var prefs = await SharedPreferences.getInstance();
    try {
      var response = await post(Uri.http(localhost, '/api/change_password'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode({
            'password': _newPasswordController.text,
            'id': prefs.getInt('id').toString(),
          }));
      if (response.statusCode == 200) {
        overlay.show("Password reset successfully.");
        Navigator.pop(context);
      } else if (response.statusCode == 417) {
        print("password incorrect");

        overlay.show("Password incorrect.\n Please enter correct password.");
      } else {
        print("error");
      }
    } catch (e) {}
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
              child: keyIcon(),
            ),
            Container(
              height: size.height - (size.height * .24) - 170,
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  Column(children: [
                    SizedBox(height: size.height * .17),
                    Align(
                        alignment: Alignment.center,
                        child: Text("Confirm your account",
                            style: GoogleFonts.raleway(
                              fontSize: 17,
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
                        controller: _passwordController,
                        obscureText: true,
                        onChanged: (val) {
                          setState(() {
                            curPasswordErr = null;
                          });
                        },
                        textAlign: TextAlign.center,
                        cursorColor: Colors.black,
                        cursorWidth: .3,
                        style: GoogleFonts.lato(color: Colors.black),
                        decoration: InputDecoration(
                          errorText: curPasswordErr,
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
                      onPressed: check_password,
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
                  ]),
                  Column(children: [
                    SizedBox(height: size.height * .14),
                    Align(
                        alignment: Alignment.center,
                        child: Text("Change Password",
                            style: GoogleFonts.raleway(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ))),
                    SizedBox(height: size.height * .04),
                    Container(
                      width: 200,
                      child: TextField(
                        // maxLines: 8,
                        controller: _newPasswordController,
                        obscureText: true,
                        textAlign: TextAlign.center,
                        cursorColor: Colors.black,
                        cursorWidth: .3,
                        style: GoogleFonts.lato(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: "New password",
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
                    SizedBox(height: size.height * .04),
                    Container(
                      width: 200,
                      child: TextField(
                        // maxLines: 8,
                        controller: _confirmPasswordController,
                        obscureText: true,
                        textAlign: TextAlign.center,
                        cursorColor: Colors.black,
                        cursorWidth: .3,
                        style: GoogleFonts.lato(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: "Confirm password",
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
                      onPressed: change_password,
                      child: Container(
                          width: 150,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Center(
                              child: Text("Change password",
                                  style: GoogleFonts.raleway(
                                      letterSpacing: 1.04,
                                      fontSize: 13,
                                      color: Colors.white)))),
                    )
                  ]),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

keyIcon() => Container(
      height: 120,
      width: 100,
      child: Stack(children: [
        Align(
          alignment: Alignment.centerRight,
          child: Transform(
            alignment: Alignment.center,
            child: Icon(Ionicons.key_outline, color: Colors.grey, size: 60),
            transform: Matrix4.identity()
              ..rotateZ(((2 * pi) / 3) + .3)
              ..scale(1.2),
          ),
        ),
        Positioned(
          left: 5,
          bottom: 0,
          child: Transform(
            alignment: Alignment.center,
            child: Icon(Ionicons.key_outline, color: Colors.grey, size: 60),
            transform: Matrix4.identity()
              ..rotateZ(((2 * pi) / 3))
              ..scale(1.2),
          ),
        ),
      ]),
    );
