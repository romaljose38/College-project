import 'package:flutter/material.dart';

class ElevatedGradientButton extends StatelessWidget {
  final String text;
  final double width;
  final double height;
  final Function onPressed;

  ElevatedGradientButton({
    Key key,
    @required this.text,
    this.width = double.infinity,
    this.height = 40.0,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 50.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
                                colors:[Color.fromRGBO(250, 57, 142, 1),Color.fromRGBO(253,167,142,1)],
                                begin:Alignment.centerLeft,
                                end: Alignment.centerRight
                              ),  
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
            onTap: onPressed,
            child: Center(
              child: Text(this.text),
            )),
      ),
    );
  }
}