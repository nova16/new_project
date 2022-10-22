import 'dart:developer';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'doc_list.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dio/dio.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

// void main() => runApp(const MyApp());

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       home: AddDocument(),
//     );
//   }
// }

class DocPage extends StatefulWidget {
  const DocPage({super.key});

  @override
  State<DocPage> createState() => _DocPageState();
}

class _DocPageState extends State<DocPage> {
  String category = "";
  String name_category = "";
  String full_name = "";
  String id_number = "";
  String unid_user = "";
  String unid_employee = "";

  final ScrollController _scrollController = ScrollController();

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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    getPref();

    // log("Build COmplete");
    WidgetsBinding.instance.addPostFrameCallback((_) => dataDoc("", ""));
    _scrollController.addListener(() {
      // log("scroll $_scrollController");
      // log("scroll max ${_scrollController.position.pixels} ${_scrollController.position.maxScrollExtent}");
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        //   widget.loadData("", "","");

        EasyDebounce.debounce(
            'load-more', // <-- An ID for this particular debouncer
            const Duration(milliseconds: 300), // <-- The debounce duration
            () {
          // log("load more ${this.lastDate}");
          dataDoc(queryDoc, authDoc, lastDate);
        } // <-- The target method
            );
      } else {
        EasyDebounce.cancel('load-more');
      }
    });
    super.initState();
  }

  TextEditingController labelDoc = TextEditingController();
  TextEditingController strDoc = TextEditingController();
  TextEditingController strSearch = TextEditingController();
  String? nameDoc = "";
  String searchDoc = "";
  bool isUpdate = false;
  bool uploadDocument = false;

  //param to take image using Image Picker
  XFile? image;
  // List _images = [];
  final ImagePicker picker = ImagePicker();

  //param to send doc data
  var file;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  //function get data from db
  int page = 1;
  int pageTotal = 1;
  String? querySearch;
  String? queryDoc;
  String? authDoc;
  bool isLoading = false;
  String? lastDate = "";
  Future<List>? listDoc;
  List tListDoc = [];

  // Future<List> getDocument(query, auth, [ld = "", reload = false]) async {
  Future<List> getDocument([reload = false]) async {
    setState(() {
      isLoading = true;
    });

    // ignore: prefer_typing_uninitialized_variables
    // final response;
    // ignore: prefer_typing_uninitialized_variables
    final res;

    Map<String, dynamic> qs = {};
    if (authDoc.toString().isNotEmpty) {
      qs['unid'] = authDoc.toString();
    }
    if (queryDoc.toString().isNotEmpty) {
      qs['label'] = queryDoc.toString();
    }
    if (lastDate != "") {
      qs["lastDate"] = lastDate;
    }

    if (reload != false) {
      qs['limit'] = -1;
    }

    log("qparam ${qs.toString()}");
    log("is qs empty ? ${qs.isEmpty.toString()}");
    String now = DateTime.now().microsecondsSinceEpoch.toString();
    // if (qs.isNotEmpty) {
    res = await Dio().get("https://kpu-cimahi.com/api/document/list",
        queryParameters: qs);
    // } else {
    //   res = await Dio().get("http://192.168.1.4/api_kpu/api/document/list");
    // }
    // log("RES ${res.toString()}");
    var dataDoc = res.data;
    List? tmpDoc = tListDoc;
    if (dataDoc['data'].isNotEmpty) {
      log("RETURN ADDED");
      List tmpDocGet = dataDoc['data'];
      if (lastDate != "" && reload == false) {
        log("COMBINE RES");
        tmpDoc = tmpDoc + tmpDocGet;
      } else {
        log("ORIGINAL RES");
        tmpDoc = tmpDocGet;
      }
      tListDoc = tmpDoc;
      lastDate = tmpDoc.last['create_time'];
    } else {
      log("RETURN ORIGINAL");
      tListDoc = tmpDoc;
      if (tmpDoc.isNotEmpty) {
        lastDate = tmpDoc.last['create_time'];
      }
      // log(tmpDoc.toString())
    }
    setState(() {
      isLoading = false;
    });
    return tmpDoc;

    // return dataDoc['data'];
  }

  void dataDoc(querySearch, authData, [ld = "", reload = false]) {
    log("params $querySearch + $authData + $ld + $reload");

    queryDoc = querySearch.toString();
    authDoc = authData.toString();
    lastDate = ld;
    // Future<List>? tmpListDoc;

    // if (lastDate == "") {
    //   listDoc = getDocument();
    // } else {
    //   List? tmpDoc = await listDoc;
    //   List? tmpDocGet = await getDocument();
    //   if (tmpDoc != null) {
    //     tmpDoc = tmpDoc + tmpDocGet;
    //     log("LG $tmpDoc");
    //     listDoc = tmpDoc as Future<List>?;
    //     // tmpDoc = tmpDoc.addAll(getDocument());
    //   }
    // }

    // var tlistDoc = await getDocument();
    // log("LDD $tlistDoc");

    setState(() {
      // log("LOAD DATA");
      listDoc = getDocument(reload);
    });
  }

  void editDoc(context, unid, unid_author, labelDoc, fileName, [type = '']) {
    // var fName = fileName.toString().substring(
    //       8,
    //     );
    // var fName = fileName.toString().split('/').last;
    // log("Cek substring result:" + fName.toString());
    // setState(() {
    showAlert(
        context: context,
        unid: unid,
        label: labelDoc,
        fileName: fileName,
        type: type);
    log("Method Edit $fileName");
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Data Document", style: TextStyle(color: Colors.white)),
      ),
      body: Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: strSearch,
                textAlign: TextAlign.left,
                onChanged: (value) {
                  EasyDebounce.debounce(
                      'my-search', // <-- An ID for this particular debouncer
                      const Duration(
                          milliseconds: 500), // <-- The debounce duration
                      () => dataDoc(strSearch.text, "") // <-- The target method
                      );
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  hintText: 'Search : Name Document',
                  fillColor: Colors.white70,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        querySearch = strSearch.text;
                        String auth = "";
                        dataDoc(querySearch, auth);
                      },
                      icon: const Icon(Icons.file_copy_sharp,
                          color: Colors.white),
                      label: const Text("All Document",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        textStyle: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5.0),
                  ),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        querySearch = strSearch.text;
                        String auth = unid_employee;
                        dataDoc(querySearch, auth);
                      },
                      icon: const Icon(Icons.file_download_done,
                          color: Colors.white),
                      label: const Text("My Document",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        textStyle: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                controller: _scrollController,
                child: FutureBuilder(
                    future: listDoc,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) print(snapshot.error);

                      return snapshot.hasData
                          ? ItemListDoc(
                              documentList: snapshot.data!,
                              loadData: dataDoc,
                              editData: editDoc,
                              search: queryDoc as String,
                              owner: authDoc as String,
                              contextMain: context,
                            )
                          : const Center(child: CircularProgressIndicator());
                    }),
              ),
            ),
            isLoading
                ? const LinearProgressIndicator(
                    // value: 10,
                    semanticsLabel: 'Linear progress indicator',
                  )
                : SizedBox.shrink()
          ],
        ),
      ),
    );
  }

//Dialog File Option
  void showAlertOLD(
      {required BuildContext context,
      String? unid = "",
      String? label = "",
      String? fileName = ""}) {
    setState(() {
      // if (label != "")
      labelDoc.text = label.toString();
      nameDoc = "";
      if (unid != "") {
        isUpdate = true;
        if (fileName != "") {
          nameDoc = fileName;
        }
        log("SET FILE NULL");
        file = false;
      } else {
        log("SET FILE NULL");
        isUpdate = false;
        file = false;
      }
    });
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) => Material(
                type: MaterialType.transparency,
                child: Container(
                  // A simplified version of dialog.
                  width: double.infinity,
                  height: double.infinity,
                  margin: const EdgeInsets.only(
                      left: 20.0, right: 25.0, top: 25.0, bottom: 25.0),
                  color: Colors.white,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Container(
                                // These values are based on trial & error method
                                alignment: Alignment.centerRight,
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
                            ),
                          ],
                        ),
                        const Text(
                          "Form Upload",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                        ),
                        const SizedBox(
                          width: 100,
                          height: 100,
                          child: Image(
                              image:
                                  AssetImage("assets/images/icon-cloud.png")),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: TextField(
                            controller: labelDoc,
                            textAlign: TextAlign.left,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              hintText: 'Nama Dokumen',
                              fillColor: Colors.white70,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Row(
                              // mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Expanded(
                                  child: RawMaterialButton(
                                    onPressed: () {},
                                    elevation: 2.0,
                                    fillColor: Colors.amber,
                                    padding: const EdgeInsets.all(15.0),
                                    shape: const CircleBorder(),
                                    child: IconButton(
                                      icon: const Icon(Icons.file_present),
                                      onPressed: () {
                                        selectDocument(context, setState);
                                      },
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: RawMaterialButton(
                                    onPressed: () {},
                                    elevation: 2.0,
                                    fillColor: Colors.lightBlue,
                                    padding: const EdgeInsets.all(15.0),
                                    shape: const CircleBorder(),
                                    child: IconButton(
                                      icon: const Icon(Icons.photo),
                                      onPressed: () {
                                        takeImage(ImageSource.gallery, context,
                                            setState);
                                      },
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: RawMaterialButton(
                                    onPressed: () {},
                                    elevation: 2.0,
                                    fillColor: Colors.cyanAccent,
                                    padding: const EdgeInsets.all(15.0),
                                    shape: const CircleBorder(),
                                    child: IconButton(
                                      icon: const Icon(Icons.camera_alt),
                                      onPressed: () {
                                        takeImage(ImageSource.camera, context,
                                            setState);
                                      },
                                    ),
                                  ),
                                ),
                              ]),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            isUpdate == true
                                ? "Tidak Perlu Melampirkan File Jika Hanya Ingin Mengubah Label"
                                : nameDoc.toString(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 40),
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () =>
                                  {sendDocument(context, unid, setState)},
                              style: ElevatedButton.styleFrom(
                                  shape: const StadiumBorder(),
                                  minimumSize: const Size(double.infinity, 50)),
                              child: const Text("Upload Dokumen"),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
    );
  }

  void showAlert(
      {required BuildContext context,
      String? unid = "",
      String? label = "",
      String? fileName = "",
      String? type = ''}) {
    setState(() {
      // if (label != "")
      labelDoc.text = label.toString();
      nameDoc = "";
      if (unid != "") {
        isUpdate = true;
        if (fileName != "") {
          nameDoc = fileName;
        }
        log("SET FILE NULL");
        file = false;
      } else {
        log("SET FILE NULL");
        isUpdate = false;
        file = false;
      }
    });
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) => Material(
                type: MaterialType.transparency,
                child: Container(
                  // A simplified version of dialog.
                  width: double.infinity,
                  height: double.infinity,
                  margin: const EdgeInsets.only(
                      left: 20.0, right: 25.0, top: 25.0, bottom: 25.0),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      uploadDocument == true
                          ? const LinearProgressIndicator()
                          : const SizedBox.shrink(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              "Form Upload",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Container(
                              // These values are based on trial & error method
                              alignment: Alignment.centerRight,
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
                          ),
                        ],
                      ),

                      const SizedBox(
                        width: 50,
                        height: 50,
                        child: Image(
                            image: AssetImage("assets/images/icon-cloud.png")),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        child: TextField(
                          controller: labelDoc,
                          textAlign: TextAlign.left,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            hintText: 'Nama Dokumen',
                            fillColor: Colors.white70,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                            // mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Expanded(
                                child: RawMaterialButton(
                                  onPressed: () {},
                                  elevation: 2.0,
                                  fillColor: Colors.amber,
                                  padding: const EdgeInsets.all(15.0),
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    icon: const Icon(Icons.file_present),
                                    onPressed: () {
                                      selectDocument(context, setState);
                                    },
                                  ),
                                ),
                              ),
                              Expanded(
                                child: RawMaterialButton(
                                  onPressed: () {},
                                  elevation: 2.0,
                                  fillColor: Colors.lightBlue,
                                  padding: const EdgeInsets.all(15.0),
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    icon: const Icon(Icons.photo),
                                    onPressed: () {
                                      takeImage(ImageSource.gallery, context,
                                          setState);
                                    },
                                  ),
                                ),
                              ),
                              Expanded(
                                child: RawMaterialButton(
                                  onPressed: () {},
                                  elevation: 2.0,
                                  fillColor: Colors.cyanAccent,
                                  padding: const EdgeInsets.all(15.0),
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    icon: const Icon(Icons.camera_alt),
                                    onPressed: () {
                                      takeImage(ImageSource.camera, context,
                                          setState);
                                    },
                                  ),
                                ),
                              ),
                            ]),
                      ),

                      Expanded(
                        child: LayoutBuilder(builder: (context, constraints) {
                          log("FILE IS $file namedoc is $nameDoc");
                          if (isUpdate == true &&
                              type == 'image' &&
                              file == false) {
                            return Image.network(
                              nameDoc.toString(),
                              fit: BoxFit.contain,
                              loadingBuilder: (BuildContext context,
                                  Widget child,
                                  ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            );
                          } else if (isUpdate == true &&
                              type == 'pdf' &&
                              file == false) {
                            if (nameDoc.toString() == "") {
                              return const SizedBox.shrink();
                            } else {
                              return SfPdfViewer.network(nameDoc.toString());
                            }
                            ;
                          } else if (file == false) {
                            return const SizedBox.shrink();
                          } else if (file is FilePickerResult) {
                            var path = file.files.single.path;
                            return FractionallySizedBox(
                                heightFactor: 1,
                                child:
                                    PDFView(filePath: path, enableSwipe: true));
                          } else {
                            var path = file.path;
                            return Image.file(File(path));
                          }
                        }),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 40),
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              {sendDocument(context, unid, setState)},
                          style: ElevatedButton.styleFrom(
                              shape: const StadiumBorder(),
                              minimumSize: const Size(double.infinity, 50)),
                          child: const Text("Upload Dokumen"),
                        ),
                      ),
                      // Padding(
                      //   padding: const EdgeInsets.all(20.0),
                      //   child: Text(
                      //     isUpdate == true
                      //         ? "Tidak Perlu Melampirkan File Jika Hanya Ingin Mengubah Label"
                      //         : nameDoc.toString(),
                      //     style: const TextStyle(
                      //         fontWeight: FontWeight.bold, fontSize: 14),
                      //   ),
                      // ),
                      // Align(
                      //   alignment: Alignment.bottomCenter,
                      //   child: Container(
                      //     margin: const EdgeInsets.symmetric(
                      //         horizontal: 20, vertical: 40),
                      //     width: double.infinity,
                      //     child: ElevatedButton(
                      //       onPressed: () => {sendDocument(context, unid)},
                      //       style: ElevatedButton.styleFrom(
                      //           shape: const StadiumBorder(),
                      //           minimumSize: const Size(double.infinity, 50)),
                      //       child: const Text("Upload Dokumen"),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              )),
    );
  }

//Take Image and Send Image
  Future takeImage(ImageSource media, context, setState) async {
    file = await picker.pickImage(source: media, maxHeight: 600);
    if (file != null) {
      // final tempDir = await getTemporaryDirectory();
      // final path = tempDir.path;

      // setNameFile(setState, file.path.split('/').last);
      setState(() {
        nameDoc = file.path.split('/').last;
        //   log("setstate" + file.toString());
      });
      // showAlert(context:context);
    } else {
      file = false;
    }
    log("cek file image:$file");
  }

  selectDocument(context, insetState) async {
    PlatformFile fileDoc;
    String nameFile = "";
    var tmpFile;
    var oldFile = file ?? false;
    setState(() {
      file = false;
    });
    insetState(() {
      file = false;
    });
    tmpFile = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    log("cek file pdf baru: $file");

    if (tmpFile != null) {
      fileDoc = tmpFile.files.first;
      nameFile = fileDoc.name;
      log("cek nama file $nameFile");
    } else {
      log("SetFile $oldFile");
      tmpFile = oldFile;
      // User canceled the picker
    }
    log("cek file: $nameFile");
    setState(() {
      // file = selectedfile!.toString();
      file = tmpFile;
      if (tmpFile != false) {
        nameDoc = "";
      }
    });
    insetState(() {
      // file = selectedfile!.toString();
      file = tmpFile;
      if (tmpFile != false) {
        nameDoc = "";
      }
      // showAlert(context:context);
    });
  }

//Send Document to DB
  void sendDocument(context, unid, insetState) async {
    String strLabelDoc = labelDoc.text;
    var unid_author = unid_employee;
    final uri = Uri.parse("https://kpu-cimahi.com/api/document/upload");

    var request = http.MultipartRequest('POST', uri);

    log("SEND FILE $file");
    setState(() {
      uploadDocument = true;
    });
    insetState(() {
      uploadDocument = true;
    });

    if (file == null || file == false) {
    } else {
      var path;
      if (file is FilePickerResult) {
        path = file.files.single.path;
      } else {
        path = file.path;
      }
      log("ini path nya$path");

      var path_position = await http.MultipartFile.fromPath("userfile", path);
      request.files.add(path_position);
    }
    request.fields["author"] = unid_author;
    request.fields["label"] = strLabelDoc;

    log("REQ $request");
    print("REQf  ${request.fields}");

    // log('cek path:' + path_position.toString());
    // log('cek request:' + request.toString());
    if (unid != "") {
      request.fields["unid"] = unid;
    }

    await request.send().then((result) {
      http.Response.fromStream(result).then((response) {
        setState(() {
          uploadDocument = false;
        });
        insetState(() {
          uploadDocument = false;
        });
        Map<String, dynamic> message = jsonDecode(response.body);
        //  log(message.toString());
        log('cek:${response.body}');

        if (message['status'] == 400) {
          Fluttertoast.showToast(
              msg: message['message'] + "!! \n " + message['errors'],
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.TOP);
        } else {
          Fluttertoast.showToast(
              msg: "Data berhasil disimpan!",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM);
          // labelDoc.text = "";
          Navigator.of(context, rootNavigator: true).pop();
          if (isUpdate == true) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          dataDoc(queryDoc, authDoc, lastDate, true);
        }
        // if (message[]
      });
    }).catchError((e) {
      print(e);
    });
  }
}
