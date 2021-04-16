import 'package:flutter/material.dart';
import 'elevatedgradientbuttonlogin.dart';
import 'logintextfield.dart';


class LoginScreen extends StatelessWidget {

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _authenticate() async{
    final email = _emailController.text;
    final password = _passwordController.text;
    print(email + password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      backgroundColor: Colors.white,
          body: SafeArea(
          
          child: Container(
            padding: EdgeInsets.fromLTRB(30, 40, 30, 20),
            child:SingleChildScrollView(
                 child:ConstrainedBox(
                   constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .85),
                   child:Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Expanded(
                                    child:Column(
                                      children:[
                                      Text("Welcome," , style: TextStyle(
                                                color:Colors.black,
                                                fontSize: 25,
                                                fontWeight: FontWeight.bold,
                                                ),),
                                                SizedBox(height:7,),
                                      Text("Sign in to continue!", style: TextStyle(
                                              color:Color.fromRGBO(170,185,202,1),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 18,
                                      ),),
                                      SizedBox(height:60),                                      
                                      Field(labelText: "Email",isObscure: false,controller: _emailController,),
                                      SizedBox(height: 15),
                                      Field(labelText: "Password",isObscure: true,controller: _passwordController,),
                                      SizedBox(height: 8,),
                                      Align(
                                        alignment:Alignment.centerRight,
                                        child: Text("Forgot password?",style: TextStyle(color: Colors.black,fontSize:13,fontWeight: FontWeight.w600),),),
                                      SizedBox(height: 40,),
                                      ElevatedGradientButton(text: "Login",onPressed:_authenticate ,),
                                      ])),
                                      Align(child: Text("Im a new user. Sign up",style: TextStyle(color: Colors.black,fontWeight: FontWeight.w500),))],
              )
                 )
            )
            ),
          ),
    );
  }
}