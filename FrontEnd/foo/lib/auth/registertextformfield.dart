import 'package:flutter/material.dart';
import 'registerinputdecoration.dart';
import 'dart:core';

class ErrorField {
  static String usernameError;
  static String emailError;
  static String uprnError;
  static String passwordError;
  static String tokenError;

  static Map<String, bool> notHadFocus = {
    'username': false,
    'email': false,
    'uprn': false,
    'password': false,
  };
}

//ignore: must_be_immutable
class FormTextField extends StatelessWidget {
  final FocusNode focusField;
  final FocusNode nextFocusField;
  final String fieldName;
  final String labeltext;
  bool passwordHidden;
  Function whenSaved;
  Function onChanged;
  Function doValidate;
  Function isToggledView = () => null;

  FormTextField(
      {this.focusField,
      this.nextFocusField,
      this.fieldName,
      this.labeltext,
      this.passwordHidden,
      this.whenSaved,
      this.onChanged,
      this.doValidate,
      this.isToggledView});

  String validate(value, fieldName, labelText) {
    RegExp myExp = RegExp(r"^[a-zA-Z0-9_@]*$");
    if (value.indexOf(' ') >= 0) return "Spaces are not allowed";
    if ((value == null || value.isEmpty) && ErrorField.notHadFocus[fieldName])
      return "Enter your $labelText";
    switch (fieldName) {
      case 'username':
        {
          if (ErrorField.usernameError != null) {
            return ErrorField.usernameError;
          }
          if (!myExp.hasMatch(value)) {
            return "Only _ @ and alphanumerics are allowed";
          }
          return null;
        }
        break;
      case 'email':
        {
          if (ErrorField.emailError != null) {
            return ErrorField.emailError;
          }
          return null;
        }
        break;
      case 'uprn':
        {
          if (ErrorField.uprnError != null) {
            return ErrorField.uprnError;
          }
          if (num.tryParse(value) == null && ErrorField.notHadFocus[fieldName])
            return "Your UPRN should only contain numbers";
          return null;
        }
        break;

      case 'password':
        {
          if (ErrorField.passwordError != null) {
            return ErrorField.passwordError;
          }
          return null;
        }
        break;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (focusField.hasFocus == false) {
          print(fieldName);
          doValidate();
        } else {
          Future.delayed(Duration(milliseconds: 1), () {
            ErrorField.notHadFocus[fieldName] = true;
          });
        }
      },
      child: TextFormField(
        focusNode: focusField,
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
        onChanged: (value) {
          onChanged(value, fieldName);
        },
        onSaved: (String value) {
          whenSaved(value, fieldName);
        },
        onFieldSubmitted: (value) {
          focusField.unfocus();
          FocusScope.of(context).requestFocus(nextFocusField);
        },
        // validator
        validator: (value) {
          return validate(value, fieldName, labeltext);
        },
        obscureText: passwordHidden,
        decoration: (fieldName == "password")
            ? decorationField("Password", isToggledView,
                hidePassword: passwordHidden)
            : decorationField(labeltext, () {}),
      ),
    );
  }
}
