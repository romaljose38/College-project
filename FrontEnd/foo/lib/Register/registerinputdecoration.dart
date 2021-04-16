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
    suffix: (labeltext == "Password")
        ? InkWell(
            onTap: () {
              isToggleView();
            },
            child: Icon(
              hidePassword ? Icons.visibility : Icons.visibility_off,
              color: Colors.black38,
            ),
          )
        : Text(''),
  );
}
