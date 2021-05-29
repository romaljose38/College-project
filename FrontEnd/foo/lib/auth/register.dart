import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'elevatedgradientbutton.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'registertextformfield.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import 'package:foo/test_cred.dart';

import 'dart:io';

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
  bool _isUploading = false;
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> registerData = {
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
    var url = Uri.http(localhost, "api/register");
    var response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: userJson,
    );

    if (response.statusCode == 400) {
      var jsonResponse = convert.jsonDecode(response.body);
      print(jsonResponse);
    } else if (response.statusCode == 200) {
      var data = convert.jsonDecode(response.body);
      print(data);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      data.forEach((key, value) {
        if ((key == "uprn") | (key == "id")) {
          prefs.setInt(key, value);
        } else {
          prefs.setString(key, value);
        }
      });
      // prefs.setBool('loggedIn', true);
      // Navigator.pushNamed(context, '/landingPage');
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => CalendarBackground()),
      );
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

      // Navigator.push(
      //   context,
      //   MaterialPageRoute(builder: (context) => CalendarBackground()),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Container(
        margin: EdgeInsets.fromLTRB(30, 40, 30, 20),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88),
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
                    // Row(
                    //   children: [
                    //     Expanded(
                    //       //First Name
                    //       child: FormTextField(
                    //         focusField: focusFirstName,
                    //         nextFocusField: focusLastName,
                    //         fieldName: 'f_name',
                    //         labeltext: 'First Name',
                    //         passwordHidden: false,
                    //         whenSaved: _whenSaved,
                    //       ),
                    //     ),
                    //     SizedBox(width: 15),
                    //     Expanded(
                    //       //Second Name
                    //       child: FormTextField(
                    //         focusField: focusLastName,
                    //         nextFocusField: focusUsername,
                    //         fieldName: 'l_name',
                    //         labeltext: 'Last Name',
                    //         passwordHidden: false,
                    //         whenSaved: _whenSaved,
                    //       ),
                    //     ),
                    //   ],
                    // ),
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
                    _isUploading
                        ? CircularProgressIndicator()
                        : ElevatedGradientButton(
                            text: "Submit",
                            onPressed: () {
                              setState(() {
                                _isUploading = true;
                              });
                              _submitHandle();
                            },
                            focusNode: focusSubmit,
                          ),
                  ])),
              Align(
                child: GestureDetector(
                    child: RichText(
                        text: TextSpan(
                            // text: "Already have an account?.",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500),
                            children: [
                          TextSpan(
                              text: "Log in",
                              style: TextStyle(
                                  color: Color.fromRGBO(250, 57, 142, 1),
                                  fontWeight: FontWeight.w700))
                        ])),
                    onTap: () {
                      Navigator.pushNamed(context, '/login');
                    }),
              )
            ]),
          ),
        ),
      ),
    );
  }
}

// class FormCheck extends StatelessWidget {
//   final String userJson;
//   FormCheck({Key key, @required this.userJson}) : super(key: key);
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Foo Register'),
//       ),
//       body: Column(
//         children: [
//           Text("$userJson"),
//         ],
//       ),
//     );
//   }
// }

/*
suffix: InkWell(
          onTap: _isTogglePassword,
          child: Icon(
            _passwordHidden ? Icons.visibility : Icons.visibility_off,
          ),
        ),
*/

class CalendarBackground extends StatefulWidget {
  @override
  _CalendarBackgroundState createState() => _CalendarBackgroundState();
}

class _CalendarBackgroundState extends State<CalendarBackground> {
  SharedPreferences _prefs;
  File imageFile;
  FixedExtentScrollController _dateController;
  FixedExtentScrollController _monthController;
  FixedExtentScrollController _yearController;
  int date = 1, month = 1, year = 2000;

  Map months = {
    1: 'Jan',
    2: 'Feb',
    3: 'Mar',
    4: 'Apr',
    5: 'May',
    6: 'Jun',
    7: 'Jul',
    8: 'Aug',
    9: 'Sept',
    10: 'Oct',
    11: 'Nov',
    12: 'Dec',
  };

  @override
  void initState() {
    super.initState();
    _dateController = FixedExtentScrollController();
    _monthController = FixedExtentScrollController();
    _yearController = FixedExtentScrollController();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _submitHandler() {
    _prefs.setBool('loggedIn', true);
    Navigator.pushNamed(context, '/landingPage');
  }

  Future<void> _setProfilePic() async {
    if (await Permission.storage.request().isGranted) {
      FilePickerResult result =
          await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null) {
        // imageFile = File(result.files.single.path);
        ImageCropper.cropImage(
          sourcePath: result.files.single.path,
          aspectRatioPresets: [CropAspectRatioPreset.square],
          androidUiSettings: AndroidUiSettings(
            toolbarTitle: 'Crop',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: true,
          ),
        ).then((result) {
          setState(() {
            imageFile = result;
          });
        });
      }
    }
  }

  // final cropKey = GlobalKey<CropState>();

  // Future<File> _cropImage() async {
  //   final scale = cropKey.currentState.scale;
  //   final area = cropKey.currentState.area;
  //   if (area == null) {
  //     // cannot crop, widget is not setup
  //     return null;
  //   }

  //   // scale up to use maximum possible number of pixels
  //   // this will sample image in higher resolution to make cropped image larger
  //   final sample = await ImageCrop.sampleImage(
  //     file: imageFile,
  //     preferredSize: (2000 / scale).round(),
  //   );

  //   final file = await ImageCrop.cropImage(
  //     file: sample,
  //     area: area,
  //   );

  //   sample.delete();

  //   debugPrint('$file');

  //   return file;
  // }

  // void _buildCroppingImage() {
  //   _setProfilePic().then((_) {
  //     return Overlay.of(context).insert(
  //       OverlayEntry(
  //         builder: (context) => Column(
  //           children: <Widget>[
  //             Expanded(
  //               child: Crop.file(imageFile, key: cropKey),
  //             ),
  //             Container(
  //               padding: const EdgeInsets.only(top: 20.0),
  //               alignment: AlignmentDirectional.center,
  //               child: Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceAround,
  //                 children: <Widget>[
  //                   TextButton(
  //                     child: Text(
  //                       'Crop Image',
  //                       style: Theme.of(context)
  //                           .textTheme
  //                           .button
  //                           .copyWith(color: Colors.white),
  //                     ),
  //                     onPressed: () async {
  //                       returnFile = await _cropImage();
  //                     },
  //                   ),
  //                 ],
  //               ),
  //             )
  //           ],
  //         ),
  //       ),
  //     );
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    TextStyle style() => GoogleFonts.titilliumWeb(
          color: Colors.black,
          fontSize: 20.0,
          fontWeight: FontWeight.w400,
        );

    return Scaffold(
      // backgroundColor: Color.fromARGB(255, 120, 129, 213),
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * .7),
          padding: EdgeInsets.fromLTRB(0, 50, 0, 10),
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                GestureDetector(
                  onTap: () {
                    _setProfilePic();
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: imageFile == null
                            ? BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                    color: Colors.grey.shade400, width: 1),

                                // color: Colors.grey.shade100,
                              )
                            : BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                    color: Colors.grey.shade400, width: 1),
                                image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: FileImage(imageFile)),
                              ),
                        child: Center(
                          child: imageFile == null
                              ? Icon(Icons.person_add_alt_1,
                                  size: 50, color: Colors.black)
                              : Container(),
                        ),
                      ),
                      // Positioned(
                      //   child: Container(
                      //     height: 8,
                      //     width: 8,
                      //     child: Icon(Icons.add),
                      //   ),
                      // )
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          // color: Colors.black.withOpacity(.3),
                        ),
                        child: Center(
                            // child: Text("Change photo"),
                            ),
                      )
                    ],
                  ),
                )
              ]),
              SizedBox(height: 50),
              Text(
                "When is your birthday?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      height: 80,
                      width: 50,
                      margin: EdgeInsets.all(5),
                      child: ListWheelScrollView(
                          controller: _dateController,
                          itemExtent: 30,
                          children: [
                            for (int i = 1; i <= 31; i++)
                              Text(
                                '$i',
                                style: style(),
                              ),
                          ],
                          overAndUnderCenterOpacity: 0.5,
                          useMagnifier: true,
                          diameterRatio: 1.5,
                          offAxisFraction: .5,
                          physics: BouncingScrollPhysics(),
                          onSelectedItemChanged: (data) {
                            date = data + 1;
                            print('$date/$month/$year');
                          })),
                  Container(
                      height: 80,
                      width: 50,
                      margin: EdgeInsets.all(5),
                      child: ListWheelScrollView(
                          controller: _monthController,
                          itemExtent: 30,
                          children: [
                            for (int i = 1; i <= 12; i++)
                              Text(
                                months[i],
                                textAlign: TextAlign.left,
                                textDirection: TextDirection.ltr,
                                style: style(),
                              ),
                          ],
                          overAndUnderCenterOpacity: 0.5,
                          useMagnifier: true,
                          diameterRatio: 1.5,
                          offAxisFraction: .5,
                          physics: BouncingScrollPhysics(),
                          onSelectedItemChanged: (data) {
                            month = data + 1;
                            print('$date/$month/$year');
                          })),
                  Container(
                      height: 80,
                      width: 50,
                      margin: EdgeInsets.all(5),
                      child: ListWheelScrollView(
                          controller: _yearController,
                          itemExtent: 30,
                          children: [
                            for (int i = 1980; i <= 2021; i++)
                              Text(
                                '$i',
                                style: style(),
                              ),
                          ],
                          overAndUnderCenterOpacity: 0.5,
                          useMagnifier: true,
                          diameterRatio: 1.5,
                          offAxisFraction: .5,
                          physics: BouncingScrollPhysics(),
                          onSelectedItemChanged: (data) {
                            year = data + 1980; //to increment the index by 1980
                            print('$date/$month/$year');
                          }))
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(10.0),
                    child: FormTextField(
                      fieldName: 'f_name',
                      labeltext: 'First Name',
                      passwordHidden: false,
                      whenSaved: null,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(10.0),
                    child: FormTextField(
                      fieldName: 'l_name',
                      labeltext: 'Last Name',
                      passwordHidden: false,
                      whenSaved: null,
                    ),
                  ),
                ],
              ),
              // CalendarDatePicker(
              //   initialDate: DateTime.utc(2001, 1, 9),
              //   firstDate: DateTime.utc(1995, 1, 1),
              //   lastDate: DateTime.utc(2020, 12, 12),
              //   onDateChanged: (value) => print(value),
              // ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 70,
        width: MediaQuery.of(context).size.width,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _submitHandler,
              child: Text(
                "Next",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              ),
            )
          ],
        ),
      ),
    );
  }
}
