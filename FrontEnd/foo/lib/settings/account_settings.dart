import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';

class EditProfile extends StatelessWidget {
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
          Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.lightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(Icons.check, color: Colors.white),
              ))
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
                  Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Icon(Icons.person,
                            size: 40, color: Colors.grey.shade500),
                      )),
                  TextButton(
                      child: Text("Upload Image",
                          style: GoogleFonts.raleway(fontSize: 13)),
                      onPressed: () {}),
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
        body: Padding(
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
    ));
  }
}
