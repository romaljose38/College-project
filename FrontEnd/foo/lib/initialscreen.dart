import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:flutter/material.dart';
import 'package:foo/auth/register.dart';
import 'dart:async';

class Renderer extends StatefulWidget {
  @override
  _RendererState createState() => _RendererState();
}

class _RendererState extends State<Renderer> {
  Timer timer;
  bool isConnected = true;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(
        Duration(seconds: 2), (Timer t) => _checkConnectionStatus());
  }

  void _checkConnectionStatus() async {
    bool result = await DataConnectionChecker().hasConnection;

    if (result == true) {
      setState(() {
        isConnected = true;
      });
      print('YAY! Free cute dog pics!');
    } else {
      setState(() {
        isConnected = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isConnected ? RegisterView() : NoConnectionView();
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
