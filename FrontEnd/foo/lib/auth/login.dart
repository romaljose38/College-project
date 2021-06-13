import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foo/custom_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_cred.dart';
import 'elevatedgradientbutton.dart';
import 'logintextfield.dart';
import 'package:http/http.dart' as http;
import 'package:foo/auth/register.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  AnimationController _animationController;

  FocusNode focusMail;
  FocusNode focusPassword;
  FocusNode focusSubmit;

  bool _buttonPressed = false;

  String emailErr;
  String passErr;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 100));
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

  changeErr(val) {
    if (val == "Email") {
      setState(() {
        emailErr = null;
      });
    } else if (val == "Password") {
      setState(() {
        passErr = null;
      });
    }
  }

  void _authenticate() async {
    focusMail.unfocus();
    focusPassword.unfocus();
    await SystemChannels.textInput.invokeMethod('TextInput.hide');
    CustomOverlay _overlay = CustomOverlay(
        context: context, animationController: _animationController);

    final email = _emailController.text;
    final password = _passwordController.text;

    if (email == "" && password == "") {
      setState(() {
        emailErr = "This field cannot be empty";
        passErr = "This field cannot be empty";
      });
      return;
    }
    if (email == "") {
      setState(() {
        emailErr = "This field cannot be empty";
      });
      return;
    }
    if (password == "") {
      setState(() {
        passErr = "This field cannot be empty";
      });
      return;
    }
    setState(() {
      _buttonPressed = true;
    });

    print(email + password);
    var url = Uri.http(localhost, "api/login");

    try {
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
        bool dobVerified;
        print(data);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        data.forEach((key, value) {
          if ((key == "uprn") | (key == "id")) {
            prefs.setInt(key, value);
          } else if (key == "dobVerified") {
            dobVerified = data[key];
          } else if (key == "username") {
            prefs.setString("username", value);
            prefs.setString("username_alias", value);
          } else if (key == "general_last_seen") {
            prefs.setBool('general_hide_last_seen', value);
          } else if (key == "mood") {
            prefs.setInt("curMood", value);
          } else if (key == "last_seen_hidden") {
            for (String user in value) {
              prefs.setBool("am_i_hiding_last_seen_from_$user", true);
            }
          } else {
            prefs.setString(key, value);
          }
        });
        setState(() {
          _buttonPressed = false;
        });
        if (dobVerified == true) {
          prefs.setBool('loggedIn', true);
          Navigator.pushNamed(context, '/landingPage');
        } else {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => CalendarBackground()));
        }
      } else {
        setState(() {
          emailErr = "";
          passErr = "";

          _buttonPressed = false;
        });
        _overlay.show("Invalid credentials", duration: 3);
      }
    } catch (e) {
      setState(() {
        _buttonPressed = false;
      });
      _overlay.show(
          "Something went wrong.\nPlease check your network connection and try again.",
          duration: 3);
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
                                  errorText: emailErr,
                                  errorChange: changeErr,
                                  toggleHidePassword: () {},
                                ),
                                SizedBox(height: 15),
                                Field(
                                  focusField: focusPassword,
                                  nextFocusField: focusSubmit,
                                  labelText: "Password",
                                  isObscure: hidePassword,
                                  errorText: passErr,
                                  errorChange: changeErr,
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
                                _buttonPressed == false
                                    ? ElevatedGradientButton(
                                        text: "Login",
                                        onPressed: _authenticate,
                                      )
                                    : Center(
                                        child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation(
                                            Colors.purple),
                                        strokeWidth: 2,
                                      )),
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
