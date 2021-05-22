import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomOverlay {
  BuildContext context;
  AnimationController animationController;
  OverlayEntry _entry;
  Animation _animation;

  CustomOverlay({context, animationController}) {
    this.context = context;

    this.animationController = animationController;
    _initiate();
  }

  _showOverlay(text) {
    OverlayState overlayState = Overlay.of(this.context);
    _entry = OverlayEntry(builder: (context) {
      return Stack(alignment: Alignment.center, children: [
        Positioned(
          bottom: MediaQuery.of(context).size.height * .26,
          child: Material(
            type: MaterialType.transparency,
            child: FadeTransition(
              opacity: this._animation,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                  text,
                  style: GoogleFonts.lato(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ]);
    });

    animationController
        .forward()
        .whenComplete(() => overlayState.insert(_entry));
    Timer(Duration(seconds: 2), () => _entry.remove());
  }

  _initiate() {
    this._animation =
        Tween<double>(begin: 0, end: 1).animate(this.animationController);
  }

  show(String text) {
    _showOverlay(text);
  }
}
