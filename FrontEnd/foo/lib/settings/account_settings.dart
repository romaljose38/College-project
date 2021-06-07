import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:foo/custom_overlay.dart';
import 'package:foo/test_cred.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:ionicons/ionicons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EditProfile extends StatefulWidget {
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile>
    with SingleTickerProviderStateMixin {
  SharedPreferences _prefs;
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _aboutController = TextEditingController();
  AnimationController _controller;
  File imageFile;

  bool absorbing = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 100));
    setinit();
  }

  setPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  setinit() async {
    await setPrefs();
    _usernameController.text = _prefs.getString("username");
    Directory dir = await getApplicationDocumentsDirectory();
    _aboutController.text = _prefs.getString("about") ?? "";
    setState(() {
      imageFile = File(dir.path + '/images/dp/dp.jpg');
    });
  }

  Future<File> testCompressAndGetFile(File file) async {
    String targetPath = (await getApplicationDocumentsDirectory()).path +
        '/images/dp/dp_new.jpg'; //'/storage/emulated/0/foo/profile_pic/dp.jpg';
    await Permission.storage.request();
    try {
      File(targetPath).createSync(recursive: true);
      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 80,
      );
      print(file.lengthSync());
      print(result.lengthSync());

      return result;
    } catch (e) {
      print(e);
    }
  }

  Future<File> getImageFileFromAssets() async {
    String path = 'images/dp/dp.jpg';
    final byteData = await rootBundle.load('assets/$path');

    File('${(await getApplicationDocumentsDirectory()).path}/images/dp/dp_new.jpg')
        .createSync(recursive: true);
    final file = File(
        '${(await getApplicationDocumentsDirectory()).path}/images/dp/dp_new.jpg');
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

    return file;
  }

  void _submitHandler() async {
    setState(() {
      absorbing = true;
    });
    int userId = _prefs.getInt('id');
    String oldFilePath =
        (await getApplicationDocumentsDirectory()).path + '/images/dp/dp.jpg';
    File file;
    try {
      if (imageFile != null) {
        file = await testCompressAndGetFile(imageFile);
      } else {
        file = await getImageFileFromAssets();
      }
      File(oldFilePath).createSync();
      File oldFile = File(oldFilePath);
      oldFile.deleteSync();
      file.renameSync(oldFilePath);
      file = File(oldFilePath);
    } catch (e) {
      print("Photo insertion failed");
      file.deleteSync();
    }
    CustomOverlay overlay =
        CustomOverlay(context: context, animationController: _controller);
    print(file.path);

    print(userId);
    var url = Uri.http(localhost, '/api/update_details');
    var request = http.MultipartRequest('POST', url)
      ..fields['id'] = userId.toString()
      ..fields['about'] = _aboutController.text
      ..fields['username'] = _usernameController.text
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        await CachedNetworkImage.evictFromCache(
            'http://' + localhost + '/media/user_$userId/profile/dp.jpg');
        _prefs.setString('about', _aboutController.text);
        _prefs.setString('username_alias', _usernameController.text);
        setState(() {
          absorbing = false;
        });
        overlay.show("Profile update successfully");
        FileImage(file).evict();
      } else {
        setState(() {
          absorbing = false;
        });
        overlay.show("Something went wrong. \n Try again later");

        print("Invalid upload credentials");
      }
    } catch (e) {
      print(e);
      setState(() {
        absorbing = false;
      });
      overlay.show("Something went wrong. \n Try again later");
    }
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

  removeImage() {
    setState(() {
      imageFile = null;
    });
  }

  actionButtons(context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(Icons.clear, color: Colors.black),
                )),
          ),
          GestureDetector(
            onTap: _submitHandler, //absorbing ? null : _submitHandler,
            child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.lightBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: absorbing
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              backgroundColor: Colors.purple),
                        )
                      : Icon(Icons.check, color: Colors.white),
                )),
          )
        ],
      );

  imageRow() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Photo",
                style: GoogleFonts.raleway(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500),
              ),
              Spacer(),
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        Container(
                          height: 75,
                          width: 75,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                              child: (imageFile != null)
                                  ? Image.file(imageFile, fit: BoxFit.cover)
                                  // : Image.file(File(curPath))
                                  : Image.asset("assets/images/dp/dp.jpg",
                                      fit: BoxFit.cover)),
                        ),
                        Positioned(
                            top: 5,
                            right: 5,
                            child: GestureDetector(
                              onTap: removeImage,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withOpacity(.4)),
                                child: Center(
                                  child: Icon(Icons.clear,
                                      size: 13, color: Colors.white),
                                ),
                              ),
                            ))
                      ],
                    ),
                  ),
                  TextButton(
                      child: Text("Upload Image",
                          style: GoogleFonts.raleway(fontSize: 13)),
                      onPressed: _setProfilePic),
                ],
              ),
              Spacer(),
            ]),
      );

  nameRow() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 80,
                child: Text(
                  "Username",
                  style: GoogleFonts.raleway(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500),
                ),
              ),
              Spacer(),
              Container(
                width: 200,
                child: TextField(
                  controller: _usernameController,
                  cursorColor: Colors.black,
                  cursorWidth: .3,
                  style: GoogleFonts.lato(color: Colors.black),
                  decoration: InputDecoration(
                    isDense: true,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.grey.withOpacity(.4), width: .6),
                    ),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.grey.withOpacity(.4), width: .6),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.grey.withOpacity(.4), width: .8),
                    ),
                  ),
                ),
              ),
              Spacer(),
            ]),
      );

  aboutRow() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 80,
                child: Text(
                  "About",
                  style: GoogleFonts.raleway(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500),
                ),
              ),
              Spacer(),
              Container(
                width: 200,
                child: TextField(
                  // maxLines: 8,
                  controller: _aboutController,
                  cursorColor: Colors.black,
                  cursorWidth: .3,
                  style: GoogleFonts.lato(color: Colors.black),
                  decoration: InputDecoration(
                    isDense: true,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.grey.withOpacity(.4), width: .6),
                    ),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.grey.withOpacity(.4), width: .6),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.grey.withOpacity(.4), width: .8),
                    ),
                  ),
                ),
              ),
              Spacer(),
            ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: AbsorbPointer(
      absorbing: absorbing,
      child: Padding(
        padding: EdgeInsets.fromLTRB(15, 40, 15, 0),
        child: Container(
            child: SingleChildScrollView(
          child: Column(
            children: [
              actionButtons(context),
              SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.only(left: 15),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Account",
                      style: GoogleFonts.raleway(
                          letterSpacing: .1,
                          fontSize: 30,
                          color: Colors.black,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              SizedBox(height: 40),
              imageRow(),
              SizedBox(height: 30),
              nameRow(),
              SizedBox(height: 30),
              aboutRow(),
            ],
          ),
        )),
      ),
    ));
  }
}
