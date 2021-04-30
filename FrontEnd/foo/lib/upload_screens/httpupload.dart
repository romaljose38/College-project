import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:foo/test_cred.dart';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class UploadToServerButton extends StatelessWidget {
  final String type;
  final String caption;
  final File file;

  String username;
  SharedPreferences prefs;

  UploadToServerButton({
    this.type,
    this.caption,
    this.file,
  });

  Future<void> _upload() async {
    prefs = await SharedPreferences.getInstance();
    username = prefs.getString('username');
    var uri =
        Uri.http(localhost, '/api/upload'); //This web address has to be changed
    var request = http.MultipartRequest('POST', uri)
      ..fields['username'] = username
      ..fields['type'] = type
      ..fields['caption'] = caption
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
      ));
    var response = await request.send();
    if (response.statusCode == 200) print('Uploaded!');
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: Text("Upload"),
      onPressed: _upload,
    );
  }
}
