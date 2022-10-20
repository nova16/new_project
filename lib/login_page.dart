import 'dart:convert';

// import 'package:kpuproject/views/home_page.dart';
// import 'package:kpuproject/widgets/dialogs.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'widget/dialogs.dart';
import 'dart:developer';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class HeadClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);
    path.quadraticBezierTo(
        size.width / 4, size.height - 40, size.width / 2, size.height - 20);
    path.quadraticBezierTo(
        3 / 4 * size.width, size.height, size.width, size.height - 30);
    path.lineTo(size.width, 0);

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  var txtEditEmail = TextEditingController();
  var txtEditPwd = TextEditingController();

  void _validateInputs() {
    if (_formKey.currentState!.validate()) {
      //If all data are correct then save data to out variables
      _formKey.currentState!.save();

      //debugPrint("deri");
      //debugPrint(txtEditEmail.text);
      doLogin(txtEditEmail.text, txtEditPwd.text);
    }
  }

  doLogin(email, password) async {
    final GlobalKey<State> _keyLoader = GlobalKey<State>();
    Dialogs.loading(context, _keyLoader, "Loading ...");

    // try {
    final response =
        await http.post(Uri.parse("http://192.168.1.7/api/api/auth/login"),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              "email": email,
              "password": password,
            }));

    final output = jsonDecode(response.body);
    log("OUTPUT LOGIN : $output");
    if (response.statusCode == 200) {
      Navigator.of(_keyLoader.currentContext!, rootNavigator: false).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
          output['message'],
          style: const TextStyle(fontSize: 16),
        )),
      );

      if (output['success'] == true) {
        //debugPrint(output['token']);
        saveSession(
            output['photo'],
            // output['id_number'],
            output['category'],
            output['unid_user'],
            // output['token'],
            output['unid_employee'],
            output['full_name']);
      }
      //debugPrint(output['message']);
    } else {
      Navigator.of(_keyLoader.currentContext!, rootNavigator: false).pop();
      //debugPrint(output['message']);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
          //output.toString(),
          output['message'],
          style: const TextStyle(fontSize: 16),
        )),
      );
    }
    // } catch (e) {
    //   Navigator.of(_keyLoader.currentContext!, rootNavigator: false).pop();
    //   Dialogs.popUp(context, '$e');
    //   debugPrint('$e');
    // }
  }

  saveSession(String photo, String category, String unid_user,
      String unid_employee, String full_name) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString("photo", photo);
    // await pref.setString("id_number", id_number);
    await pref.setString("category", category);
    await pref.setString("unid_user", unid_user);
    // await pref.setString("token", token);
    await pref.setString("unid_employee", unid_employee);
    await pref.setString("full_name", full_name);
    await pref.setBool("is_login", true);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => const HomePage(),
      ),
      (route) => false,
    );
  }

  void ceckLogin() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    var islogin = pref.getBool("is_login");
    if (islogin != null && islogin) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => const HomePage(),
        ),
        (route) => false,
      );
    }
  }

  @override
  void initState() {
    ceckLogin();
    super.initState();
  }

  @override
  dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xffe6e6e6),
        body: Form(
          key: _formKey,
          child: Container(
            color: Colors.black12,
            child: Column(
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 150, 20, 20),
                  padding: const EdgeInsets.all(0),
                  width: MediaQuery.of(context).size.width,
                  height: 500,
                  decoration: BoxDecoration(
                    color: const Color(0xffffffff),
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(16.0),
                    border:
                        Border.all(color: const Color(0x4d9e9e9e), width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          ///***If you have exported images you must have to copy those images in assets/images directory.
                          const Image(
                            image: AssetImage("assets/images/logo-kpu.png"),
                            height: 110,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "LOGIN",
                                textAlign: TextAlign.start,
                                overflow: TextOverflow.clip,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontStyle: FontStyle.normal,
                                  fontSize: 22,
                                  color: Color(0xff000000),
                                ),
                              ),
                            ),
                          ),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Apps Shared System",
                              textAlign: TextAlign.left,
                              overflow: TextOverflow.clip,
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.normal,
                                fontSize: 14,
                                color: Color(0xff000000),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 0),
                            child: TextFormField(
                              //controller: TextEditingController(),
                              obscureText: false,
                              textAlign: TextAlign.left,
                              maxLines: 1,
                              style: const TextStyle(
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.normal,
                                fontSize: 14,
                                color: Color(0xff000000),
                              ),
                              cursorColor: Colors.white,
                              keyboardType: TextInputType.emailAddress,
                              autofocus: false,
                              validator: (email) => email != null &&
                                      !EmailValidator.validate(email)
                                  ? 'Masukkan email yang valid'
                                  : null,
                              controller: txtEditEmail,
                              onSaved: (String? val) {
                                txtEditEmail.text = val!;
                              },
                              decoration: InputDecoration(
                                disabledBorder: UnderlineInputBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                  borderSide: const BorderSide(
                                      color: Color(0xff000000), width: 1),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                  borderSide: const BorderSide(
                                      color: Color(0xff000000), width: 1),
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                  borderSide: const BorderSide(
                                      color: Color(0xff000000), width: 1),
                                ),
                                hintText: "Enter Email",
                                hintStyle: const TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontStyle: FontStyle.normal,
                                  fontSize: 14,
                                  color: Color(0xff494646),
                                ),
                                filled: true,
                                fillColor: const Color(0xffffffff),
                                isDense: false,
                                contentPadding: const EdgeInsets.all(0),
                              ),
                            ),
                          ),
                          TextFormField(
                            // controller: TextEditingController(),
                            //obscureText: true,
                            textAlign: TextAlign.start,
                            maxLines: 1,
                            style: const TextStyle(
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                              fontSize: 14,
                              color: Color(0xff000000),
                            ),
                            cursorColor: Colors.white,
                            keyboardType: TextInputType.text,
                            autofocus: false,
                            obscureText: true, //make decript inputan
                            validator: (String? arg) {
                              if (arg == null || arg.isEmpty) {
                                return 'Password harus diisi';
                              } else {
                                return null;
                              }
                            },
                            controller: txtEditPwd,
                            onSaved: (String? val) {
                              txtEditPwd.text = val!;
                            },
                            decoration: InputDecoration(
                              disabledBorder: UnderlineInputBorder(
                                borderRadius: BorderRadius.circular(4.0),
                                borderSide: const BorderSide(
                                    color: Color(0xff000000), width: 1),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderRadius: BorderRadius.circular(4.0),
                                borderSide: const BorderSide(
                                    color: Color(0xff000000), width: 1),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderRadius: BorderRadius.circular(4.0),
                                borderSide: const BorderSide(
                                    color: Color(0xff000000), width: 1),
                              ),
                              hintText: "Enter Password",
                              hintStyle: const TextStyle(
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.normal,
                                fontSize: 14,
                                color: Color(0xff494646),
                              ),
                              filled: true,
                              fillColor: const Color(0xffffffff),
                              isDense: false,
                              contentPadding: const EdgeInsets.all(0),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 40, 0, 0),
                            child: MaterialButton(
                              onPressed: () => _validateInputs(),
                              color: const Color(0xffe8a23a),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              padding: const EdgeInsets.all(16),
                              textColor: const Color(0xffffffff),
                              height: 40,
                              minWidth: MediaQuery.of(context).size.width,
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  fontStyle: FontStyle.normal,
                                ),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
                            child: Text(
                              "Copyrigth 2022 - KPU Kota Cimahi",
                              textAlign: TextAlign.start,
                              overflow: TextOverflow.clip,
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.normal,
                                fontSize: 10,
                                color: Color(0xff000000),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
