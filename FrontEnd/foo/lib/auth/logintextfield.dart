import 'package:flutter/material.dart';

//ignore: must_be_immutable
class Field extends StatelessWidget {
  final String labelText;
  final TextEditingController controller;
  final FocusNode focusField;
  final FocusNode nextFocusField;
  bool isObscure;
  Function toggleHidePassword;

  Field(
      {this.labelText,
      this.controller,
      this.focusField,
      this.nextFocusField,
      this.isObscure,
      this.toggleHidePassword});

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: focusField,
      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
      controller: this.controller,
      obscureText: this.isObscure,
      maxLines: 1,
      decoration: InputDecoration(
        labelText: this.labelText,
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
          borderSide:
              BorderSide(width: 1, color: Color.fromRGBO(250, 87, 142, .7)),
        ),
        suffix: (labelText == "Password")
            ? GestureDetector(
                onTap: () {
                  this.toggleHidePassword();
                },
                child: this.isObscure
                    ? RichText(
                        text: TextSpan(
                            text: "Show",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w400)))
                    : RichText(
                        text: TextSpan(
                            text: "Hide",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w400))),
              )
            : Text(''),
      ),
      onEditingComplete: () {
        focusField.unfocus();
        FocusScope.of(context).requestFocus(nextFocusField);
      },
    );
  }
}
