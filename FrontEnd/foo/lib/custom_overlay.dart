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

  _showOverlay(text, duration) {
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
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(this.context).size.width * .7),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
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
    Timer(
        Duration(seconds: duration),
        () =>
            animationController.reverse().whenComplete(() => _entry.remove()));
  }

  _initiate() {
    this._animation =
        Tween<double>(begin: 0, end: 1).animate(this.animationController);
  }

  show(String text, {int duration = 2}) {
    _showOverlay(text, duration);
  }
}
