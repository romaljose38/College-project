import 'package:flutter/material.dart';

//ignore: must_be_immutable
class Field extends StatefulWidget {
  final String labelText;
  final TextEditingController controller;
  final FocusNode focusField;
  final FocusNode nextFocusField;
  bool isObscure;
  Function toggleHidePassword;
  var errorText;
  Function errorChange;

  Field(
      {this.labelText,
      this.controller,
      this.focusField,
      this.nextFocusField,
      this.isObscure,
      this.errorChange,
      this.toggleHidePassword,
      this.errorText});

  @override
  _FieldState createState() => _FieldState();
}

class _FieldState extends State<Field> {
  String hasErr;

  @override
  void initState() {
    super.initState();
    hasErr = widget.errorText;
  }

  @override
  Widget build(BuildContext context) {
    print("rebuilding");
    return TextField(
      focusNode: widget.focusField,
      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
      controller: this.widget.controller,
      obscureText: this.widget.isObscure,
      maxLines: 1,
      onChanged: (val) {
        // setState(() {
        //   this.widget.errorText = null;
        // });
        widget.errorChange(widget.labelText);
      },
      decoration: InputDecoration(
        errorText: this.widget.errorText,
        labelText: this.widget.labelText,
        labelStyle: TextStyle(
            color: Color.fromRGBO(176, 183, 194, 1),
            fontSize: 15,
            fontWeight: FontWeight.w400),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(width: 1, color: Colors.black),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(width: 1, color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(width: 1, color: Color.fromRGBO(250, 87, 142, .7)),
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
        suffix: (widget.labelText == "Password")
            ? GestureDetector(
                onTap: () {
                  this.widget.toggleHidePassword();
                },
                child: this.widget.isObscure
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
        widget.focusField.unfocus();
        FocusScope.of(context).requestFocus(widget.nextFocusField);
      },
    );
  }
}
