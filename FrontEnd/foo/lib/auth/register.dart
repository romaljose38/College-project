import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'elevatedgradientbutton.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

import 'registertextformfield.dart';
//import 'registerinputdecoration.dart';

class RegisterView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: RegisterForm()),
    );
  }
}

class RegisterForm extends StatefulWidget {
  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> registerData = {
    'f_name': null,
    'l_name': null,
    'username': null,
    'email': null,
    'uprn': null,
    'password': null,
    'token': null,
  };

  //Firebase messaging initialization
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  //Here we'll store our device token
  Future<void> saveToken() async {
    registerData['token'] = await messaging.getToken();
  }

  String userJson; //JSON file to be POSTed

  //Initialising the FocusNodes
  FocusNode focusFirstName;
  FocusNode focusLastName;
  FocusNode focusUsername;
  FocusNode focusEmail;
  FocusNode focusUprn;
  FocusNode focusPassword;
  FocusNode focusConfirmPassword;
  FocusNode focusSubmit;

  @override
  void initState() {
    super.initState();
    // We need some focus nodes to move to the next textfield when hitting enter on the keyboard
    focusFirstName = FocusNode();
    focusLastName = FocusNode();
    focusUsername = FocusNode();
    focusEmail = FocusNode();
    focusUprn = FocusNode();
    focusPassword = FocusNode();
    focusSubmit = FocusNode();
    //State.initState() must be a void method without an 'async' keyword
    //So we'll call the messaging.getToken() by nesting an async function call
    saveToken();
  }

  @override
  void dispose() {
    focusFirstName.dispose();
    focusLastName.dispose();
    focusUsername.dispose();
    focusEmail.dispose();
    focusPassword.dispose();
    focusSubmit.dispose();
    super.dispose();
  }

  //Now we create two variables to toggle the obscureText property
  //One for `password` and the other for `Confirm password`
  bool _passwordHidden = true;

  //Now we write functions to toggle obscureText property of the above given variables
  void _isTogglePassword() {
    setState(() {
      _passwordHidden = !_passwordHidden;
    });
  }

  void _whenSaved(value, fieldName) {
    registerData[fieldName] = value;
  }

  //This function handles the http post request to the server
  Future<void> httpPostRegisterData() async {
    var url = Uri.http("192.168.1.38:8000", "/api/register");
    var response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: userJson,
    );

    if (response.statusCode == 400) {
      //var jsonResponse = convert.jsonDecode(response.body);
      print("Error in some field. Check again!");
    }
    else if(response.statusCode == 200){
      var data = convert.jsonDecode(response.body);
      print(data);
    }
    print(response);
  }

  //OnSubmit
  void _submitHandle() {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      //To encode the Map object to JSON file
      userJson = convert.jsonEncode(registerData);

      //To submit the http POST
      httpPostRegisterData();

      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => FormCheck(
                  userJson: userJson,
                )),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Container(
        padding: EdgeInsets.fromLTRB(30, 40, 30, 20),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * .85),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                Text(
                  "Welcome",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 7,
                ),
                Text(
                  "Register to continue!",
                  style: TextStyle(
                    color: Color.fromRGBO(170, 185, 202, 1),
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 60),
                Row(
                  children: [
                    Expanded(
                      //First Name
                      child: FormTextField(
                        focusField: focusFirstName,
                        nextFocusField: focusLastName,
                        fieldName: 'f_name',
                        labeltext: 'First Name',
                        passwordHidden: false,
                        whenSaved: _whenSaved,
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      //Second Name
                      child: FormTextField(
                        focusField: focusLastName,
                        nextFocusField: focusUsername,
                        fieldName: 'l_name',
                        labeltext: 'Last Name',
                        passwordHidden: false,
                        whenSaved: _whenSaved,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                //Username
                FormTextField(
                  focusField: focusUsername,
                  nextFocusField: focusEmail,
                  fieldName: 'username',
                  labeltext: 'Username',
                  passwordHidden: false,
                  whenSaved: _whenSaved,
                ),
                SizedBox(height: 15),
                //Email
                FormTextField(
                  focusField: focusEmail,
                  nextFocusField: focusUprn,
                  fieldName: 'email',
                  labeltext: 'Email ID',
                  passwordHidden: false,
                  whenSaved: _whenSaved,
                ),
                SizedBox(height: 15),
                //UPRN
                FormTextField(
                  focusField: focusUprn,
                  nextFocusField: focusPassword,
                  fieldName: 'uprn',
                  labeltext: 'UPRN',
                  passwordHidden: false,
                  whenSaved: _whenSaved,
                ),
                SizedBox(height: 15),
                //Password
                FormTextField(
                  focusField: focusPassword,
                  nextFocusField: focusSubmit,
                  fieldName: 'password',
                  labeltext: 'Password',
                  passwordHidden: _passwordHidden,
                  whenSaved: _whenSaved,
                  isToggledView: _isTogglePassword,
                ),
                SizedBox(height: 60),
                ElevatedGradientButton(
                  text: "Submit",
                  onPressed: _submitHandle,
                  focusNode: focusSubmit,
                ),
              ])),
             Align(child: 
                                      GestureDetector(
                                                  child: RichText(
                                                          text:TextSpan(
                                                            text:"Already have an account?.",
                                                          style:TextStyle(color: Colors.black,fontWeight: FontWeight.w500),
                                                          children:[
                                                            TextSpan(text:"Log in",style: TextStyle(color: Color.fromRGBO(250, 57, 142, 1),fontWeight: FontWeight.w700))
                                                            ])),
                                                onTap:(){ Navigator.pushNamed(context,'/login');}
                                      ),
              )
            ]),
          ),
        ),
      ),
    );
  }
}

class FormCheck extends StatelessWidget {
  final String userJson;
  FormCheck({Key key, @required this.userJson}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Foo Register'),
      ),
      body: Column(
        children: [
          Text("$userJson"),
        ],
      ),
    );
  }
}

/*
suffix: InkWell(
          onTap: _isTogglePassword,
          child: Icon(
            _passwordHidden ? Icons.visibility : Icons.visibility_off,
          ),
        ),
*/
