import 'package:flutter/material.dart';
import 'package:foo/settings/account_settings.dart';
import 'package:foo/settings/delete_account.dart';
import 'package:foo/settings/password_confirm.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';

class Settings extends StatelessWidget {
  actionButtons(context) => Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(Icons.clear, color: Colors.black),
                )),
          ),
        ],
      );

  editProfile(context) => GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(pageBuilder: (contxt, animation, secAnimation) {
              return EditProfile();
            }, transitionsBuilder: (ctx, animation, secAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(begin: Offset(1, 0), end: Offset(0, 0))
                    .animate(animation),
                child: child,
              );
            }),
          );
        },
        child: ListTile(
          title: Text(
            "Pranav P",
            style: GoogleFonts.raleway(
                fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
          ),
          subtitle: Text(
            "Personal info",
            style: GoogleFonts.raleway(
                fontSize: 11, fontWeight: FontWeight.w400, color: Colors.grey),
          ),
          leading: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child:
                    Icon(Icons.person, size: 27, color: Colors.grey.shade500),
              )),
          trailing: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(Icons.arrow_forward, color: Colors.black),
              )),
        ),
      );

  deleteMyAccount(context) => GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(pageBuilder: (contxt, animation, secAnimation) {
              return DeleteConfirm();
            }, transitionsBuilder: (ctx, animation, secAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(begin: Offset(1, 0), end: Offset(0, 0))
                    .animate(animation),
                child: child,
              );
            }),
          );
        },
        child: ListTile(
          title: Text(
            "Delete my account",
            style: GoogleFonts.raleway(
                fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black),
          ),
          leading: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Icon(Icons.delete_forever_rounded,
                    size: 27, color: Colors.red),
              )),
          trailing: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(Icons.arrow_forward, color: Colors.black),
              )),
        ),
      );

  contactUs() => ListTile(
        title: Text(
          "Contact us",
          style: GoogleFonts.raleway(
              fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black),
        ),
        leading: Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Icon(Ionicons.help_circle_outline,
                  size: 27, color: Colors.blue),
            )),
        trailing: Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(Icons.arrow_forward, color: Colors.black),
            )),
      );

  termsAndConditions(context) => ListTile(
        title: Text(
          "Terms and licenses",
          style: GoogleFonts.raleway(
              fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black),
        ),
        leading: GestureDetector(
          onTap: () => showAboutDialog(context: context),
          child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Icon(Ionicons.reader_outline,
                    size: 27, color: Colors.greenAccent),
              )),
        ),
        trailing: Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(Icons.arrow_forward, color: Colors.black),
            )),
      );

  changePassword(context) => GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(pageBuilder: (contxt, animation, secAnimation) {
              return PasswordConfirm();
            }, transitionsBuilder: (ctx, animation, secAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(begin: Offset(1, 0), end: Offset(0, 0))
                    .animate(animation),
                child: child,
              );
            }),
          );
        },
        child: ListTile(
          title: Text(
            "Change password",
            style: GoogleFonts.raleway(
                fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black),
          ),
          leading: GestureDetector(
            onTap: () => showAboutDialog(context: context),
            child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child:
                      Icon(Ionicons.key_outline, size: 27, color: Colors.green),
                )),
          ),
          trailing: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(Icons.arrow_forward, color: Colors.black),
              )),
        ),
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
                child: Text("Settings",
                    style: GoogleFonts.raleway(
                        letterSpacing: .1,
                        fontSize: 30,
                        color: Colors.black,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Account",
                    style: GoogleFonts.raleway(
                        letterSpacing: .1,
                        fontSize: 17,
                        color: Colors.black,
                        fontWeight: FontWeight.w500)),
              ),
            ),
            SizedBox(height: 10),
            editProfile(context),
            SizedBox(height: 4),
            changePassword(context),
            SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Settings",
                    style: GoogleFonts.raleway(
                        letterSpacing: .1,
                        fontSize: 17,
                        color: Colors.black,
                        fontWeight: FontWeight.w500)),
              ),
            ),
            SizedBox(height: 15),
            deleteMyAccount(context),
            SizedBox(height: 10),
            termsAndConditions(context),
            SizedBox(height: 10),
            contactUs(),
          ],
        ),
      )),
    ));
  }
}
