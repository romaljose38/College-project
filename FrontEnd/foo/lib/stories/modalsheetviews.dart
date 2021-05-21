import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

class ModalSheetContent extends StatefulWidget {
  @override
  _ModalSheetContentState createState() => _ModalSheetContentState();
}

class _ModalSheetContentState extends State<ModalSheetContent> {
  bool _seenUsers = true;
  PageController _pageController;

  @override
  initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(horizontal: 15.0),
      height: 400,
      // color: Colors.red,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 60,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 30.0),
                    child: Text(
                      _seenUsers ? "Views" : "Comments",
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  Spacer(),
                  IconButton(
                      icon: Icon(Icons.message,
                          color: _seenUsers ? Colors.grey : Colors.green),
                      onPressed: () {
                        if (_seenUsers == true) {
                          _pageController.nextPage(
                              duration: Duration(milliseconds: 500),
                              curve: Curves.easeIn);
                        } else {
                          _pageController.previousPage(
                              duration: Duration(milliseconds: 500),
                              curve: Curves.easeIn);
                        }
                        setState(() {
                          _seenUsers = !_seenUsers;
                        });
                      }),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: null,
                  ),
                  SizedBox(width: 20),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                  controller: _pageController,
                  physics: NeverScrollableScrollPhysics(),
                  children: [seenUsersListView(), repliedUsersListView()]),
              // child:
              //     _seenUsers ? seenUsersListView() : repliedUsersListView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget seenUsersListView() {
    return ListView.builder(
      itemCount: 25,
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(
                'https://image.cnbcfm.com/api/v1/image/105753692-1550781987450gettyimages-628353178.jpeg?v=1550782124'),
          ),
          title: Text('Emma Stone'),
          subtitle: Text('7 minutes ago'),
        );
      },
    );
  }

  Widget repliedUsersListView() {
    return ListView.builder(
      itemCount: 25,
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(
                'https://image.cnbcfm.com/api/v1/image/105753692-1550781987450gettyimages-628353178.jpeg?v=1550782124'),
          ),
          title: Text('Emma Stone'),
          subtitle: Text('Cool mahn!'),
        );
      },
    );
  }
}

class ReplyModalSheet extends StatefulWidget {
  @override
  _ReplyModalSheetState createState() => _ReplyModalSheetState();
}

class _ReplyModalSheetState extends State<ReplyModalSheet> {
  TextEditingController _textController;

  @override
  initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15),
      color: Colors.transparent,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(
            Radius.circular(30.0),
            // topLeft: Radius.circular(30.0),
            // topRight: Radius.circular(30.0),
          ),
        ),
        child: Row(
          children: [
            Expanded(
                child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintStyle: GoogleFonts.sourceSansPro(),
                hintText: "Reply",
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.only(
                    left: 20, right: 8.0, top: 5.0, bottom: 8.0),
              ),
            )),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: null,
            ),
          ],
        ),
      ),
    );
  }
}
