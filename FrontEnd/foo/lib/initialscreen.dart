import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:flutter/material.dart';
import 'package:foo/auth/register.dart';
import 'package:foo/landing_page.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class Renderer extends StatefulWidget {
  @override
  _RendererState createState() => _RendererState();
}

class _RendererState extends State<Renderer> {
  Timer timer;
  var prefs;
  // bool isConnected = true;

  @override
  void initState() {
    get_prefs();
    super.initState();
    
    // timer = Timer.periodic(
        // Duration(seconds: 2), (Timer t) => _checkConnectionStatus());
  }

  void get_prefs() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
  setState((){
    prefs=prefs;
  });
  }
  // void _checkConnectionStatus() async {
  //   bool result = await DataConnectionChecker().hasConnection;

  //   if (result == true) {
  //     setState(() {
  //       isConnected = true;
  //     });
  //   } else {
  //     setState(() {
  //       isConnected = false;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return prefs.containesKey("loggedIn") ? RegisterView() : LandingPage();
  }
}

class NoConnectionView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text("No network access",
              style: TextStyle(color: Colors.black, fontSize: 25)),
        ));
  }
}
