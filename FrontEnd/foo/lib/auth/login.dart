import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_cred.dart';
import 'elevatedgradientbutton.dart';
import 'logintextfield.dart';
import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  FocusNode focusMail;
  FocusNode focusPassword;
  FocusNode focusSubmit;

  @override
  void initState() {
    super.initState();
    focusMail = FocusNode();
    focusPassword = FocusNode();
    focusSubmit = FocusNode();
  }

  @override
  void dispose() {
    focusMail.dispose();
    focusPassword.dispose();
    focusSubmit.dispose();
    super.dispose();
  }

  void _authenticate() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    print(email + password);
    var url = Uri.http(localhost, "api/login");
    var response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      print(data);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      data.forEach((key, value) {
        if ((key == "uprn") | (key == "id")) {
          prefs.setInt(key, value);
        } else if (key == "dobVerified") {
        } else {
          prefs.setString(key, value);
        }
      });
      prefs.setBool('loggedIn', true);
      Navigator.pushNamed(context, '/landingPage');
    }
  }

  bool hidePassword = true;

  void _toggleHidePassword() {
    setState(() {
      hidePassword = !hidePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Container(
            padding: EdgeInsets.fromLTRB(30, 40, 30, 20),
            child: SingleChildScrollView(
                child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * .85),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(
                                  "Welcome,",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(
                                  height: 7,
                                ),
                                Text(
                                  "Sign in to continue!",
                                  style: TextStyle(
                                    color: Color.fromRGBO(170, 185, 202, 1),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 60),
                                Field(
                                  focusField: focusMail,
                                  nextFocusField: focusPassword,
                                  labelText: "Email",
                                  isObscure: false,
                                  controller: _emailController,
                                  toggleHidePassword: () {},
                                ),
                                SizedBox(height: 15),
                                Field(
                                  focusField: focusPassword,
                                  nextFocusField: focusSubmit,
                                  labelText: "Password",
                                  isObscure: hidePassword,
                                  controller: _passwordController,
                                  toggleHidePassword: _toggleHidePassword,
                                ),
                                SizedBox(
                                  height: 8,
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    "Forgot password?",
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                SizedBox(
                                  height: 40,
                                ),
                                ElevatedGradientButton(
                                  text: "Login",
                                  onPressed: _authenticate,
                                ),
                              ])),
                          Align(
                            child: GestureDetector(
                                child: RichText(
                                    text: TextSpan(
                                        text: "Im a new user.",
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500),
                                        children: [
                                      TextSpan(
                                          text: "Sign up",
                                          style: TextStyle(
                                              color: Color.fromRGBO(
                                                  250, 57, 142, 1),
                                              fontWeight: FontWeight.w700))
                                    ])),
                                onTap: () {
                                  Navigator.pushNamed(context, '/register');
                                }),
                          )
                        ]))),
          ),
        ));
  }
}
