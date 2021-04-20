import 'package:flutter/material.dart';
import 'package:foo/colour_palette.dart';

class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.lavender,
      body: Center(child: Text("hello"),),
    );
  }
}