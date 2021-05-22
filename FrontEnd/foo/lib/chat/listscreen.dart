import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'chattile.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: SafeArea(
        //     child: Scaffold(
        //   backgroundColor: Color.fromRGBO(226, 235, 243, 1),
        //   body: Padding(
        //     padding: const EdgeInsets.all(8.0),
        //     child: CustomScrollView(
        //       slivers: [
        //         SliverAppBar(
        //           brightness: Brightness.dark,
        //           expandedHeight: 150,
        //           floating: true,
        //           backgroundColor: Colors.transparent,
        //           leading: Icon(
        //             Icons.arrow_back,
        //             color: Colors.black,
        //           ),
        //           flexibleSpace: FlexibleSpaceBar(
        //             background: Align(
        //               alignment: Alignment.centerLeft,
        //               child: Padding(
        //                 padding: const EdgeInsets.only(left: 30),
        //                 child: Text("Conversation",
        //                     style: TextStyle(
        //                         color: Color.fromRGBO(60, 82, 111, 1),
        //                         fontWeight: FontWeight.w700,
        //                         fontSize: 25)),
        //               ),
        //             ),
        //           ),
        //         ),
        //         // SliverToBoxAdapter(
        //         // child:
        //         ValueListenableBuilder(
        //             valueListenable: Hive.box("Threads").listenable(),
        //             builder: (context, box, widget) {
        //               print(box.values.toList());
        //               List threads = box.values.toList();
        //               if (threads.length >= 1) {
        //                 threads.sort((a, b) {
        //                   return b.lastAccessed.compareTo(a.lastAccessed);
        //                 });
        //               }

        //               return SliverList(
        //                 delegate: SliverChildBuilderDelegate(
        //                   (context, index) {
        //                     return ChatTile(
        //                         // controller:widget.controller,
        //                         thread: threads[index]);
        //                   },
        //                   childCount: threads == null ? 0 : threads.length,
        //                 ),
        //               );
        //             }),
        //         // ),
        //       ],
        //     ),
        //   ),
        // )
        child: Scaffold(
          backgroundColor: Colors.white,
          extendBodyBehindAppBar: true,

          body: Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                padding: EdgeInsets.fromLTRB(20, 30, 10, 30),
                child: Row(
                  children: [
                    Text(
                      "Chat",
                      style: GoogleFonts.lato(
                        color: Color.fromRGBO(60, 82, 111, 1),
                        fontWeight: FontWeight.w600,
                        fontSize: 30,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ValueListenableBuilder(
                    valueListenable: Hive.box("Threads").listenable(),
                    builder: (context, box, widget) {
                      print(box.values.toList());

                      List threads = box.values.toList() ?? [];

                      if (threads.length >= 1) {
                        threads.sort((a, b) {
                          return b.lastAccessed.compareTo(a.lastAccessed);
                        });
                      }
                      print(threads);
                      return ListView.builder(
                          itemCount: threads.length,
                          itemBuilder: (context, index) {
                            print(index);
                            print(threads[index]);
                            return ChatTile(thread: threads[index]);
                          });
                    }),
              ),
            ],
          ),

          //     )),
        ),
      ),
    );
  }
}
