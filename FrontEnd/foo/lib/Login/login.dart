import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
          body: SafeArea(
                      child: Container(
                        padding: EdgeInsets.fromLTRB(30, 20, 30, 20),
        decoration: BoxDecoration(
            color: Colors.amberAccent,
        ),
        child:Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Welcome"),
                                Text("Sign in to continue"),
                                TextField(
                                            maxLines: 2,
                                            decoration: InputDecoration(
                                              labelText: 'Full Name',
                                              border: OutlineInputBorder(),          
                                            )
                                  ),
                              ],
                            ),
              ),
              Text("hai")],
        )
      ),
          ),
    );
  }
}