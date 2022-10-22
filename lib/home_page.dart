//import 'package:kpuproject/views/listview_pages.dart';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:d_view/d_view.dart';
import 'dart:async';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dio/dio.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:progress_loading_button/progress_loading_button.dart';
import 'doc_list.dart';
import 'login_page.dart';
import 'setting_page.dart';
import 'doc_page.dart';
import 'dart:io';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String category = "";
  String name_category = "";
  String full_name = "";
  String id_number = "";
  String unid_user = "";
  String unid_employee = "";
  String employee_photo = "";

  final ScrollController _scrollController = ScrollController();

  TextEditingController labelDoc = TextEditingController();
  TextEditingController strDoc = TextEditingController();
  TextEditingController strSearch = TextEditingController();
  String? nameDoc = "";
  String searchDoc = "";
  bool isUpdate = false;

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
  bool uploadFoto = false;
  bool uploadDocument = false;

  // Future<List> getDocument(query, auth, [ld = "", reload = false]) async {
  Future<List> getDocument() async {
    log("LOad Data home");
    setState(() {
      isLoading = true;
    });

    // ignore: prefer_typing_uninitialized_variables
    // final response;
    // ignore: prefer_typing_uninitialized_variables
    final res;

    Map<String, dynamic> qs = {};
    // if (authDoc.toString().isNotEmpty) {
    //   qs['unid'] = authDoc.toString();
    // }
    // if (queryDoc.toString().isNotEmpty) {
    //   qs['label'] = queryDoc.toString();
    // }
    // if (lastDate != "") {
    //   qs["lastDate"] = lastDate;
    // }

    qs['limit'] = 5;

    log("qparam ${qs.toString()}");
    log("is qs empty ? ${qs.isEmpty.toString()}");
    String now = DateTime.now().microsecondsSinceEpoch.toString();
    // if (qs.isNotEmpty) {
    res = await Dio()
        .get("https://kpu-cimahi.com/api/document/list", queryParameters: qs);
    // } else {
    //   res = await Dio().get("http://192.168.1.4/api_kpu/api/document/list");
    // }
    log("RES ${res.toString()}");
    var dataDoc = res.data;
    List? tmpDoc = tListDoc;
    if (dataDoc['data'].isNotEmpty) {
      log("RETURN ADDED");
      List tmpDocGet = dataDoc['data'];
      log("ORIGINAL RES");
      tmpDoc = tmpDocGet;
      tListDoc = tmpDoc;
      lastDate = tmpDoc.last['create_time'];
    } else {
      log("RETURN ORIGINAL");
      List tmpDocGet = dataDoc['data'];
      tmpDoc = tmpDocGet;
      // log(tmpDoc.toString())
    }
    setState(() {
      isLoading = false;
    });
    return tmpDoc;
    // return dataDoc['data'];
  }

  void dataDoc(
      [String dummy1 = "",
      String dummy2 = "",
      String dummy3 = "",
      bool dumy3 = true]) {
    // log("params $querySearch + $authData + $ld + $reload");

    // queryDoc = querySearch.toString();
    // authDoc = authData.toString();
    // lastDate = ld;
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
      listDoc = getDocument();
    });
  }

  getPref() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    var islogin = pref.getBool("is_login");
    if (islogin != null && islogin == true) {
      setState(() {
        category = pref.getString("category")!;
        full_name = pref.getString("full_name")!;
        employee_photo = pref.getString('photo')!;
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

  logOut() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      preferences.remove("is_login");
      preferences.remove("category");
    });

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => const LoginPage(),
      ),
      (route) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
        "Logout Successfuly",
        style: TextStyle(fontSize: 16),
      )),
    );
  }

  @override
  void initState() {
    getPref();
    WidgetsBinding.instance.addPostFrameCallback((_) => dataDoc());
    log("HOme Page INIT");
    super.initState();
  }

  @override
  dispose() {
    super.dispose();
  }

  void editDoc(context, unid, unid_author, labelDoc, fileName) {
    // var fName = fileName.toString().substring(
    //       8,
    //     );
    var fName = fileName.toString().split('/').last;
    // log("Cek substring result:" + fName.toString());
    // setState(() {
    showAlert(context: context, unid: unid, label: labelDoc, fileName: fName);
    log("Method Edit $fileName");
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: () => logOut(),
            icon: const Icon(Icons.logout),
            color: Colors.red,
          ),
        ],
      ),
      backgroundColor: const Color(0xffe6e6e6),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            profileCard(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: DView.textTitle('Main Menu'),
            ),
            menuUtama(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: DView.textTitle('Document Update'),
            ),
            const SizedBox(height: 4),
            FutureBuilder(
                future: listDoc,
                builder: (context, snapshot) {
                  if (snapshot.hasError) print(snapshot.error);

                  return snapshot.hasData
                      ? ItemListDoc(
                          documentList: snapshot.data!,
                          loadData: dataDoc,
                          editData: editDoc,
                          search: "",
                          owner: "",
                          contextMain: context,
                          editable: false,
                        )
                      : const Center(child: CircularProgressIndicator());
                }),
          ],
        ),
      ),
    );
  }

  Container profileCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const Text(
                        "Selamat Datang!",
                        textAlign: TextAlign.start,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.normal,
                          fontSize: 16,
                          color: Color(0xff8c8989),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                        child: Text(
                          full_name,
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.clip,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.normal,
                            fontSize: 18,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),
                      Text(
                        id_number,
                        textAlign: TextAlign.start,
                        overflow: TextOverflow.clip,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.normal,
                          fontSize: 14,
                          color: Color(0xff8c8989),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 50,
                  width: 50,
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      InkWell(
                        onTap: () {
                          showChangeProfile();
                        },
                        child: Container(
                            height: 70,
                            width: 70,
                            clipBehavior: Clip.antiAlias,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            // child: Image.network(
                            //     "https://pbs.twimg.com/profile_images/799071539731664896/Wq_PplI7_400x400.jpg",
                            //     fit: BoxFit.cover),
                            child: (employee_photo == "")
                                ? Image.network(
                                    "https://kpu-cimahi.com/uploads/profile/doraemon.png",
                                    fit: BoxFit.cover)
                                : Image.network(employee_photo,
                                    fit: BoxFit.cover)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // sudah di perbaiki click on card container
  Container menuUtama() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            physics: const ClampingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            children: [
              InkWell(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const SettingPage()));
                },
                child: Container(
                  margin: const EdgeInsets.all(0),
                  padding: const EdgeInsets.all(0),
                  decoration: BoxDecoration(
                    color: const Color(0xffffffff),
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.all(0),
                        padding: const EdgeInsets.all(0),
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Color(0xff5f75e6),
                          shape: BoxShape.circle,
                        ),
                        child: const ImageIcon(
                          AssetImage("assets/images/icon-setting.png"),
                          size: 30,
                          color: Color(0xffffffff),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(0, 16, 0, 0),
                        child: Text(
                          "Setting",
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            fontSize: 16,
                            color: Color(0xff000000),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  showAlert(context: context);
                },
                child: Container(
                  margin: const EdgeInsets.all(0),
                  padding: const EdgeInsets.all(0),
                  decoration: BoxDecoration(
                    color: const Color(0xffffffff),
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.all(0),
                        padding: const EdgeInsets.all(0),
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Color(0xffe260b7),
                          shape: BoxShape.circle,
                        ),
                        child: const ImageIcon(
                          AssetImage("assets/images/icon-upload.png"),
                          size: 30,
                          color: Color(0xffffffff),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(0, 16, 0, 0),
                        child: Text(
                          "Upload",
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            fontSize: 16,
                            color: Color(0xff000000),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(
                          builder: (context) => const DocPage()))
                      .then((data) => dataDoc());
                },
                child: Container(
                  margin: const EdgeInsets.all(0),
                  padding: const EdgeInsets.all(0),
                  decoration: BoxDecoration(
                    color: const Color(0xffffffff),
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.all(0),
                        padding: const EdgeInsets.all(0),
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Color(0xffee9d30),
                          shape: BoxShape.circle,
                        ),
                        child: const ImageIcon(
                          AssetImage("assets/images/icon-list.png"),
                          size: 30,
                          color: Color(0xffffffff),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(0, 16, 0, 0),
                        child: Text(
                          "Files",
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            fontSize: 16,
                            color: Color(0xff000000),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Container mainMenu() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            physics: const ClampingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            children: [
              Container(
                margin: const EdgeInsets.all(0),
                padding: const EdgeInsets.all(0),
                decoration: BoxDecoration(
                  color: const Color(0xffffffff),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.all(0),
                      padding: const EdgeInsets.all(0),
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Color(0xff5f75e6),
                        shape: BoxShape.circle,
                      ),
                      child: InkWell(
                        onTap: () {
                          //Get.to(() => const SettingPage())?.then((value) {});
                        },
                        child: const ImageIcon(
                          AssetImage("assets/images/icon-setting.png"),
                          size: 30,
                          color: Color(0xffffffff),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(0, 16, 0, 0),
                      child: Text(
                        "Setting",
                        textAlign: TextAlign.start,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.normal,
                          fontSize: 16,
                          color: Color(0xff000000),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(0),
                padding: const EdgeInsets.all(0),
                decoration: BoxDecoration(
                  color: const Color(0xffffffff),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.all(0),
                      padding: const EdgeInsets.all(0),
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Color(0xffe260b7),
                        shape: BoxShape.circle,
                      ),
                      child: InkWell(
                        onTap: () {
                          // Get.to(() => const EmployeePage())?.then((value) {
                          //   //cDashboard.setEmployee();
                          // });
                        },
                        child: const ImageIcon(
                          AssetImage("assets/images/icon-upload.png"),
                          size: 30,
                          color: Color(0xffffffff),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(0, 16, 0, 0),
                      child: Text(
                        "Upload",
                        textAlign: TextAlign.start,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.normal,
                          fontSize: 16,
                          color: Color(0xff000000),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(0),
                padding: const EdgeInsets.all(0),
                decoration: BoxDecoration(
                  color: const Color(0xffffffff),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.all(0),
                      padding: const EdgeInsets.all(0),
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Color(0xffee9d30),
                        shape: BoxShape.circle,
                      ),
                      child: InkWell(
                        onTap: () {
                          // Get.to(() => const DocPage())?.then((value) {
                          //   //cDashboard.setEmployee();
                          // });
                        },
                        child: const ImageIcon(
                          AssetImage("assets/images/icon-list.png"),
                          size: 30,
                          color: Color(0xffffffff),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(0, 16, 0, 0),
                      child: Text(
                        "Files",
                        textAlign: TextAlign.start,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.normal,
                          fontSize: 16,
                          color: Color(0xff000000),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //Dialog File Option
  void showAlert(
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
                          log("FILE IS $file");
                          if (file == false) {
                            log("FILE IS NONNE");
                            return const SizedBox.shrink();
                          } else if (file is FilePickerResult) {
                            var path = file.files.single.path;
                            log('pdfupdate $path');
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

  void showChangeProfile() {
    // setState(() {});
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setState) => Material(
                  type: MaterialType.transparency,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    margin: const EdgeInsets.only(
                        left: 20.0, right: 25.0, top: 25.0, bottom: 25.0),
                    child: FractionallySizedBox(
                      widthFactor: 0.8,
                      heightFactor: 0.5,
                      child: Container(
                          color: Colors.white,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              (uploadFoto == true)
                                  ? const LinearProgressIndicator()
                                  : const SizedBox.shrink(),
                              Expanded(
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.all(10),
                                  child: (employee_photo == "")
                                      ? Image.network(
                                          "https://kpu-cimahi.com/uploads/profile/doraemon.png",
                                          fit: BoxFit.contain,
                                          loadingBuilder: (BuildContext context,
                                              Widget child,
                                              ImageChunkEvent?
                                                  loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                    : null,
                                              ),
                                            );
                                          },
                                        )
                                      : Image.network(
                                          employee_photo,
                                          fit: BoxFit.contain,
                                          loadingBuilder: (BuildContext context,
                                              Widget child,
                                              ImageChunkEvent?
                                                  loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                    : null,
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ),
                              Container(
                                padding:
                                    const EdgeInsets.only(bottom: 10, top: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    RawMaterialButton(
                                      onPressed: () {},
                                      elevation: 2.0,
                                      fillColor: Colors.orangeAccent,
                                      padding: const EdgeInsets.all(5.0),
                                      shape: const CircleBorder(),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.photo,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          takeFoto(ImageSource.gallery, context,
                                              setState);
                                        },
                                      ),
                                    ),
                                    RawMaterialButton(
                                      onPressed: () {},
                                      elevation: 2.0,
                                      fillColor: Colors.lightBlue,
                                      padding: const EdgeInsets.all(5.0),
                                      shape: const CircleBorder(),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          takeFoto(ImageSource.camera, context,
                                              setState);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // ElevatedButton(
                              // onPressed: () {},
                              // child: Text("Ubah Foto Profil")),
                            ],
                          )),
                    ),
                  )));
        });
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

  Future takeFoto(ImageSource media, context, insetState) async {
    file = await picker.pickImage(source: media, maxHeight: 400);
    if (file != null) {
      // final tempDir = await getTemporaryDirectory();
      // final path = tempDir.path;

      // setNameFile(setState, file.path.split('/').last);
      // setState(() {
      //   nameDoc = file.path.split('/').last;
      //   //   log("setstate" + file.toString());
      // });
      // showAlert(context:context);
      insetState(() {
        uploadFoto = true;
      });
      sendFoto(context, file.path, insetState);
    } else {}
    log("cek file image:$file");
  }

  void sendFoto(context, path, insetState) async {
    nameDoc = path.split('/').last;
    var dataMap = {"unid": unid_employee, "foto": path};
    var dataForm = FormData.fromMap({
      "unid": unid_employee,
      "foto": await MultipartFile.fromFile(path, filename: nameDoc)
    });
    log("$dataMap $nameDoc $dataForm");
    log("send foto");
    try {
      var res = await Dio().post(
        'https://kpu-cimahi.com/api/employee/updatefoto/',
        data: dataForm,
        onSendProgress: (int sent, int total) {
          print('$sent $total');
        },
      );
      log("$res");
      var rdata = res.data;
      if (rdata['status'] == 200) {
        String now = DateTime.now().microsecondsSinceEpoch.toString();
        SharedPreferences pref = await SharedPreferences.getInstance();
        await pref.setString("photo", rdata['path'] + "?" + now.toString());

        insetState(() {
          employee_photo = rdata['path'] + "?" + now.toString();
          uploadFoto = false;
        });

        setState(() {
          employee_photo = rdata['path'] + "?" + now.toString();
          uploadFoto = false;
        });

        // Navigator.of(context, rootNavigator: true).pop();
        Fluttertoast.showToast(
            msg: "Update Profil Foto Berhasil",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.TOP);
      } else {
        Fluttertoast.showToast(
            msg: rdata['errors'],
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.TOP);
      }
    } catch (e) {
      print(e);
    }
  }

  selectDocument(context, insetState) async {
    PlatformFile fileDoc;
    String nameFile = "";
    var tmpFile;
    var oldFile = file;
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
      tmpFile = oldFile;
      // User canceled the picker
    }
    log("cek file: $nameFile");
    setState(() {
      // file = selectedfile!.toString();
      file = tmpFile;
      nameDoc = nameFile.toString();
      // showAlert(context:context);
    });
    insetState(() {
      // file = selectedfile!.toString();
      file = tmpFile;
      nameDoc = nameFile.toString();
      // showAlert(context:context);
    });
  }

//Send Document to DB
  void sendDocument(context, unid, insetState) async {
    String strLabelDoc = labelDoc.text;
    var unid_author = unid_employee;
    final uri = Uri.parse("https://kpu-cimahi.com/api/document/upload");

    var request = http.MultipartRequest('POST', uri);

    setState(() {
      uploadDocument = true;
    });
    insetState(() {
      uploadDocument = true;
    });
    log("SEND FILE $file");

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
          dataDoc();
        }
        // if (message[]
      });
    }).catchError((e) {
      print(e);
    });
  }
}
