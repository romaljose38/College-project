import 'package:flutter/material.dart';

class Field extends StatelessWidget {

  final String labelText;
  final bool isObscure;

  Field({this.labelText,this.isObscure});

  @override
  Widget build(BuildContext context) {
    return TextField(
                      obscureText: this.isObscure,
                      maxLines: 1,
                      decoration: InputDecoration(
                          labelText: this.labelText,
                          labelStyle: TextStyle(color: Color.fromRGBO(176, 183, 194, 1),fontSize: 15,fontWeight: FontWeight.w400),
                          disabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(width:1,color:Colors.black),
                            ), 
                            enabledBorder:OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(width:1,color:Color.fromRGBO(131, 146, 166, .5)),
                            ),
                          border: OutlineInputBorder(
                              borderSide: BorderSide(width:1,color:Colors.black,),
                          ),   
                          focusedBorder:   OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(width:1,color:Color.fromRGBO(250, 87, 142, .7)),
                            ),     
                      )
              );
  }
}