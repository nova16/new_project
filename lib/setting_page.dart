import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  String category = "";
  String name_category = "";
  String full_name = "";

  var txtEditEmail = TextEditingController();

  getPref() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    var islogin = pref.getBool("is_login");
    if (islogin != null && islogin == true) {
      setState(() {
        category = pref.getString("category")!;
        full_name = pref.getString("full_name")!;
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
    super.initState();
  }

  @override
  dispose() {
    super.dispose();
  }

  checkcategory() {
    if (category == 1) {
      // penghentian perintah
      return "Administrator";
    } else {
      return "Karyawan";
      // fungsi memanggil dirinya sendiri
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Setting"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              "Selamat Datang",
              style: TextStyle(fontSize: 18.0),
            ),
            Text("Nama Lengkap : " + full_name,
                style: const TextStyle(fontSize: 24.0)),
            Text("category : " + checkcategory(),
                style: const TextStyle(fontSize: 24.0)),
            const SizedBox(height: 15),
            //inputEmail(),
            // ElevatedButton.icon(
            //     onPressed: () {
            //       logOut();
            //     },
            //     icon: const Icon(Icons.lock_open),
            //     label: const Text("Log Out")),
            // const SizedBox(height: 15),
            // ElevatedButton.icon(
            //     onPressed: () {
            //       //Navigator.of(context).push(MaterialPageRoute(
            //           //builder: (context) => const PageListView()));
            //     },
            //     icon: const Icon(Icons.list_alt),
            //     label: const Text("Page List View"))
          ],
        ),
      ),
    );
  }
}
