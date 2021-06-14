import 'package:flutter/material.dart';

InputDecoration decorationField(String labeltext, Function isToggleView,
    {bool hidePassword = false}) {
  return InputDecoration(
    labelText: labeltext,
    labelStyle: TextStyle(
        color: Color.fromRGBO(176, 183, 194, 1),
        fontSize: 15,
        fontWeight: FontWeight.w400),
    disabledBorder: OutlineInputBorder(
      borderSide: BorderSide(width: 1, color: Colors.black),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide:
          BorderSide(width: 1, color: Color.fromRGBO(131, 146, 166, .5)),
    ),
    border: OutlineInputBorder(
      borderSide: BorderSide(
        width: 1,
        color: Colors.black,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(width: 1, color: Color.fromRGBO(250, 87, 142, .7)),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(width: 1, color: Colors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(width: 1, color: Color.fromRGBO(250, 87, 142, .7)),
    ),
    suffix: (labeltext == "Password")
        ? GestureDetector(
            onTap: () {
              isToggleView();
            },
            child: hidePassword
                ? RichText(
                    text: TextSpan(
                        text: "Show",
                        style: TextStyle(
                            color: Colors.black45,
                            fontSize: 12,
                            fontWeight: FontWeight.w400)))
                : RichText(
                    text: TextSpan(
                        text: "Hide",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w400))),
          )
        : Text(''),
  );
}
