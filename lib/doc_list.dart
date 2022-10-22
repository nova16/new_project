import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'dart:async';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

class ItemListDoc extends StatefulWidget {
  final List documentList;
  final Function loadData;
  final Function editData;
  final BuildContext contextMain;
  final String search;
  final String owner;
  final bool editable;
  final bool deleteable;

  // final Function() showForm;
  const ItemListDoc(
      {super.key,
      required this.documentList,
      required this.loadData,
      required this.editData,
      required this.contextMain,
      required this.search,
      required this.owner,
      bool? editable,
      bool? deleteable})
      : this.editable = editable ?? true,
        this.deleteable = deleteable ?? true;

  @override
  State<ItemListDoc> createState() => _ItemListDocState();
}

class _ItemListDocState extends State<ItemListDoc> {
  String? lastDate = "";
  String category = "";
  String name_category = "";
  String full_name = "";
  String id_number = "";
  String unid_user = "";
  String unid_employee = "";

  getPref() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    var islogin = pref.getBool("is_login");
    if (islogin != null && islogin == true) {
      setState(() {
        category = pref.getString("category")!;
        full_name = pref.getString("full_name")!;
        // id_number = pref.getString("id_number")!;
        unid_user = pref.getString("unid_user")!;
        unid_employee = pref.getString("unid_employee")!;
      });
    } else {
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => const LoginPage(),
        ),
        (route) => false,
      );
    }
  }

  @override
  void initState() {
    getPref();

    // log("Build COmplete");

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool isLoading = false;
    Future _loadData() async {
      // perform fetching data delay
      await new Future.delayed(new Duration(seconds: 2));

      print("load more");
      // update data and loading status
      setState(() {
        widget.loadData("", "", "");
        // print('items: '+ items.toString());
        isLoading = false;
      });
    }

    if (widget.documentList.isEmpty) {
      return const Center(child: Text("Empty ..."));
    } else {
      return Column(
        children: <Widget>[
          ListView.builder(
            // scrollDirection: Axis.vertical,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount:
                widget.documentList.isEmpty ? 0 : widget.documentList.length,
            itemBuilder: (context, i) {
              return Container(
                padding: const EdgeInsets.all(2.0),
                child: GestureDetector(
                  child: Card(
                    child: ListTile(
                      title: Text(widget.documentList[i]['label']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // ignore: prefer_interpolation_to_compose_strings
                          Text("Author: " + widget.documentList[i]['name']),
                          // ignore: prefer_interpolation_to_compose_strings
                          Text("Create Time: " +
                              widget.documentList[i]['formatedDate']),
                        ],
                      ),
                      leading: widget.documentList[i]['type'] == "pdf"
                          ? IconButton(
                              icon: const Icon(
                                Icons.picture_as_pdf,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                log(widget.documentList[i]['fullPath']);
                                viewPdf(
                                    widget.contextMain,
                                    widget.documentList[i]['unid'],
                                    widget.documentList[i]['fullPath'],
                                    widget.documentList[i]['file'],
                                    widget.documentList[i]
                                        ['unid_author_employee'],
                                    widget.documentList[i]['label'],
                                    unid_employee);
                              },
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.photo_library_outlined,
                                color: Colors.blue,
                              ),
                              onPressed: () {
                                viewImage(
                                    widget.contextMain,
                                    widget.documentList[i]['unid'],
                                    widget.documentList[i]['fullPath'],
                                    widget.documentList[i]['file'],
                                    widget.documentList[i]
                                        ['unid_author_employee'],
                                    widget.documentList[i]['label'],
                                    unid_employee);
                              },
                            ),
                      trailing: widget.documentList[i]
                                      ['unid_author_employee'] ==
                                  unid_employee &&
                              widget.deleteable == true
                          ? IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => {
                                    deleteOption(
                                        context,
                                        widget.documentList[i]['label'],
                                        widget.documentList[i]['unid'],
                                        unid_employee),
                                  })
                          : null,
                    ),
                  ),
                  onTap: () => {
                    widget.documentList[i]['type'] == "pdf"
                        ? viewPdf(
                            widget.contextMain,
                            widget.documentList[i]['unid'],
                            widget.documentList[i]['fullPath'],
                            widget.documentList[i]['file'],
                            widget.documentList[i]['unid_author_employee'],
                            widget.documentList[i]['label'],
                            unid_employee)
                        : viewImage(
                            widget.contextMain,
                            widget.documentList[i]['unid'],
                            widget.documentList[i]['fullPath'],
                            widget.documentList[i]['file'],
                            widget.documentList[i]['unid_author_employee'],
                            widget.documentList[i]['label'],
                            unid_employee),
                  },
                ),
              );
            },
          ),
        ],
      );
    }
  }

  //show delete option
  void deleteOption(BuildContext context, label, unid, unid_author) {
    Widget ButtonOK = ElevatedButton(
        onPressed: () {
          deleteDocument(unid, unid_author, label);
          // Navigator.pop(context);
        },
        child: Text("Delete"));
    Widget ButtonCancel = ElevatedButton(
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
        },
        child: Text("No"));

    AlertDialog alertImage = AlertDialog(
      title: Text("Delete"),
      //content: EditableText(controller: controller, focusNode: focusNode, style: style, cursorColor: cursorColor, backgroundCursorColor: backgroundCursorColor),
      content: Text("${"Are you sure want to delete these items " + label}?"),
      actions: [ButtonOK, ButtonCancel],
    );

    showDialog(
        context: context,
        builder: (BuildContext context) {
          // return StatefulBuilder(
          // builder: (context, setState) {
          return alertImage;
          // });
        });
  }

  void deleteDocument(unid, unid_author, label) async {
    String idDoc = unid.toString();
    String idAuth = unid_author.toString();

    final uri = Uri.parse("https://kpu-cimahi.com/api/document/remove");

    var request = http.MultipartRequest('POST', uri);

    request.fields["unid"] = idDoc;
    request.fields["author"] = idAuth;

    await request.send().then((result) {
      http.Response.fromStream(result).then((response) {
        Map<String, dynamic> message = jsonDecode(response.body);

        if (message['status'] == 200) {
          Fluttertoast.showToast(
              msg: "$label berhasil dihapus!",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM);
          widget.loadData(widget.search, widget.owner, "", true);
          Navigator.of(context, rootNavigator: true).pop();
          setState(() {});
        }
      });
    }).catchError((e) {
      print(e);
    });
  }

  void viewPdf(
      contextMain, unid, fullpath, file, unid_author, label, auth_session) {
    // setState(() {});
    showDialog(
        context: context,
        builder: (_) {
          return Material(
              type: MaterialType.transparency,
              child: Container(
                  // A simplified version of dialog.
                  width: double.infinity,
                  height: double.infinity,
                  margin: const EdgeInsets.only(
                      left: 20.0, right: 25.0, top: 25.0, bottom: 25.0),
                  color: Colors.white,
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            unid_author.toString() == auth_session.toString() &&
                                    widget.editable == true
                                ? ElevatedButton(
                                    onPressed: () => {
                                      widget.editData(contextMain, unid,
                                          unid_author, label, fullpath, 'pdf')
                                    },
                                    child: const Text("Edit",
                                        style: TextStyle(color: Colors.white)),
                                  )
                                : const SizedBox.shrink(),
                            InkWell(
                              onTap: () {
                                Navigator.of(context, rootNavigator: true)
                                    .pop();
                              },
                              child: const Icon(
                                Icons.close,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Padding(
                      //   padding: EdgeInsets.all(16.0),
                      //   child: Container(
                      //     // These values are based on trial & error method
                      //     alignment: Alignment.centerRight,
                      //     child: InkWell(
                      //       onTap: () {
                      //         Navigator.of(context, rootNavigator: true)
                      //             .pop();
                      //       },
                      //       child: const Icon(
                      //         Icons.close,
                      //         color: Colors.black,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      // Align(
                      //   alignment: Alignment.bottomCenter,
                      //   child: Container(
                      //       margin: const EdgeInsets.symmetric(
                      //           horizontal: 20, vertical: 10),
                      //       width: double.infinity,
                      //       child: unid_author.toString() ==
                      //               auth_session.toString()
                      //           ? ElevatedButton(
                      //               onPressed: () => {
                      //                 widget.editData(contextMain, unid,
                      //                     unid_author, label, file)
                      //               },
                      //               style: ElevatedButton.styleFrom(
                      //                   shape: const StadiumBorder(),
                      //                   minimumSize:
                      //                       const Size(double.infinity, 50)),
                      //               child: const Text("Edit Dokumen"),
                      //             )
                      //           : null),
                      // ),
                      // ignore: sized_box_for_whitespace
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: Text("Label : $label"),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          // height: 450,
                          width: double.infinity,
                          child: Padding(
                            padding: EdgeInsets.only(left: 5, right: 5),
                            child: SfPdfViewer.network(fullpath),
                            // pageLayoutMode: PdfPageLayoutMode.single),
                            // child: PDFViewer(document: document.toString()),
                          ),
                        ),
                      ),
                    ],
                  )));
        });
  }

  void viewImage(
      contextMain, unid, fullpath, file, unid_author, label, auth_session) {
    // setState(() {})
    showDialog(
        context: context,
        builder: (_) {
          return Material(
              type: MaterialType.transparency,
              child: Container(
                  // A simplified version of dialog.
                  width: double.infinity,
                  height: double.infinity,
                  margin: const EdgeInsets.only(
                      left: 20.0, right: 25.0, top: 25.0, bottom: 25.0),
                  color: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          unid_author.toString() == auth_session.toString() &&
                                  widget.editable == true
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: ElevatedButton(
                                    onPressed: () => {
                                      widget.editData(contextMain, unid,
                                          unid_author, label, fullpath, 'image')
                                    },
                                    // style: ElevatedButton.styleFrom(
                                    //     shape: StadiumBorder(),
                                    //     minimumSize: Size(double.infinity, 50)),
                                    child: Text("Edit Photo"),
                                  ),
                                )
                              : SizedBox.shrink(),
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context, rootNavigator: true)
                                    .pop();
                              },
                              child: const Icon(
                                Icons.close,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Container(
                      //   padding: const EdgeInsets.all(16.0),
                      //   child: Container(
                      //     // These values are based on trial & error method
                      //     alignment: Alignment.centerRight,
                      //     child: InkWell(
                      //       onTap: () {
                      //         Navigator.of(context, rootNavigator: true)
                      //             .pop();
                      //       },
                      //       child: const Icon(
                      //         Icons.close,
                      //         color: Colors.black,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      // Container(
                      //   alignment: Alignment.bottomCenter,
                      //   child: Container(
                      //     margin: const EdgeInsets.symmetric(
                      //         horizontal: 20, vertical: 10),
                      //     width: double.infinity,
                      //     child: unid_author.toString() ==
                      //             auth_session.toString()
                      //         ? ElevatedButton(
                      //             onPressed: () => {
                      //               widget.editData(contextMain, unid,
                      //                   unid_author, label, file)
                      //             },
                      //             style: ElevatedButton.styleFrom(
                      //                 shape: StadiumBorder(),
                      //                 minimumSize: Size(double.infinity, 50)),
                      //             child: Text("Edit Photo"),
                      //           )
                      //         : null,
                      //   ),
                      // ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: Text("Label : $label"),
                        ),
                      ),
                      Expanded(
                          child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        physics: ScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          // child: Image.network(fullpath.toString()),
                          child: Image.network(
                            fullpath.toString(),
                            fit: BoxFit.contain,
                            loadingBuilder: (BuildContext context, Widget child,
                                ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      )),
                    ],
                  )));
        });
  }
}
