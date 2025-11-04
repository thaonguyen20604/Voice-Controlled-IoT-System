import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/utils.dart';
import '../../../../styles/colors.dart';
import '../../../auth/data/models/user_detail.dart';
import '../../../auth/presentation/service/firebase/SharedPref.dart';
import '../../../auth/presentation/service/firebase/user_database_ref.dart';
import '../../../auth/presentation/service/sqlite/user_database.dart';
import '../../../auth/widgets/login_page.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final ImagePicker picker = ImagePicker();
  String image = "", id = "", username = "";
  var ggCheck;
  Uint8List? _image;
  bool isLoading = true;
  var _obscureText = true;
  final _formkey = GlobalKey<FormState>();

  final userDatabase = UserDatabase();

  UserDatabaseRef databaseRef = UserDatabaseRef();
  SharedPrefService sharedPref = SharedPrefService();
  TextEditingController nameController = TextEditingController();
  TextEditingController oldPassController = TextEditingController();
  TextEditingController newPassController = TextEditingController();
  TextEditingController confirmPassController = TextEditingController();

  @override
  void initState() {
    getSharedPreferences();
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        isLoading = false;
      });
    });
    super.initState();
  }

  late UserDetail currentUser;
  late SharedPreferences prefs;

  getSharedPreferences() async {
    ggCheck = await GoogleSignIn().isSignedIn();
    prefs = await SharedPreferences.getInstance();
    String? currents = prefs.getString("user");
    if (currents != null) {
      setState(() {
        currentUser = UserDetail.fromJson(json.decode(currents));
        nameController.text = currentUser.userName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: isLoading
            ? buildLoadingScreen(context)
            : Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Stack(
                    children: [
                      !currentUser.imgPath.contains("http") &&
                              !currentUser.imgPath.contains("images")
                          ? CircleAvatar(
                              radius: 60,
                              backgroundImage: MemoryImage(
                                  convertStringToUint8List(
                                      currentUser.imgPath)),
                            )
                          : CircleAvatar(
                              radius: 60,
                              child: ClipOval(
                                  child: currentUser.imgPath.contains("http")
                                      ? Image.network(currentUser.imgPath)
                                      : Image.asset(currentUser.imgPath)),
                            ),
                      Positioned(
                        bottom: -10,
                        left: 65,
                        child: IconButton(
                          onPressed: selectImage,
                          icon: const Icon(
                            Icons.add_a_photo,
                            size: 30,
                            color: Colors.black,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 30.0,
                  ),
                  Builder(builder: (context) {
                    return Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Form(
                        key: _formkey,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: TextFormField(
                                readOnly: true,
                                controller: TextEditingController(
                                    text: currentUser.userName),
                                decoration: InputDecoration(
                                    prefixIcon:
                                        const Icon(Icons.account_box_rounded),
                                    suffixIcon: InkWell(
                                        onTap: () {
                                          buildUsernameDialog(context);
                                        },
                                        child: const Icon(Icons.edit)),
                                    border: const OutlineInputBorder(),
                                    labelText: "Tên tài khoản"),
                              ),
                            ),
                            const SizedBox(
                              height: 10.0,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: TextFormField(
                                readOnly: true,
                                controller: TextEditingController(
                                    text: currentUser.email),
                                decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.mail),
                                    border: OutlineInputBorder(),
                                    labelText: "Email"),
                              ),
                            ),
                            const SizedBox(
                              height: 20.0,
                            ),
                            Builder(builder: (context) {
                              return GestureDetector(
                                onTap: () {
                                  _signOut();
                                },
                                child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15.0, horizontal: 30.0),
                                    decoration: BoxDecoration(
                                        color:
                                            HomeAutomationColors.lightPrimary,
                                        borderRadius:
                                            BorderRadius.circular(30)),
                                    child: const Center(
                                        child: Text(
                                      "Sign out",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 25.0,
                                          fontWeight: FontWeight.bold),
                                    ))),
                              );
                            }),
                            const SizedBox(
                              height: 20.0,
                            ),
                            ggCheck
                                ? Container()
                                : GestureDetector(
                                    onTap: () {
                                      buildChangePassDialog(context);
                                    },
                                    child: Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 15.0, horizontal: 30.0),
                                        decoration: BoxDecoration(
                                            color: Colors.indigo[900],
                                            borderRadius:
                                                BorderRadius.circular(30)),
                                        child: const Center(
                                            child: Text(
                                          "Change Password",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 25.0,
                                              fontWeight: FontWeight.bold),
                                        ))),
                                  ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }

  void buildUsernameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sửa tên tài khoản'),
          content: StatefulBuilder(builder: (context, StateSetter setState) {
            return TextFormField(
              controller: nameController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Tên tài khoản không được để trống!';
                } else if (value.length < 4) {
                  return 'Tên tài khoản quá ngắn!';
                }
                return null;
              },
              decoration:
                  const InputDecoration(hintText: "Nhập tên tài khoản mới"),
            );
          }),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Lưu'),
              onPressed: () async {
                if (_formkey.currentState!.validate()) {
                  UserDetail tmp = UserDetail(
                      fullName: nameController.text,
                      userName: nameController.text,
                      email: currentUser.email.toString(),
                      imgPath: currentUser.imgPath,
                      id: currentUser.id);
                  await databaseRef.updateUserDetail(
                      currentUser.id.toString(), tmp);
                  await userDatabase.update(
                      id: int.parse(currentUser.id),
                      fullName: nameController.text,
                      userName: nameController.text,
                      email: currentUser.email.toString(),
                      password: currentUser.password ?? '',
                      imgPath: currentUser.imgPath);
                  var dataUser =
                      await userDatabase.fetchById(int.parse(currentUser.id));
                  await prefs.setString("user", jsonEncode(dataUser.toJson()));
                  getSharedPreferences();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      backgroundColor: HomeAutomationColors.lightPrimary,
                      content: Text(
                        "Thay đổi tên tài khoản thành công!",
                      )));
                  setState(() {
                    getSharedPreferences();
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void buildChangePassDialog(BuildContext context) {
    var password = prefs.getString("pw")!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Thay đổi mật khẩu'),
          content: StatefulBuilder(builder: (context, StateSetter setState) {
            return Form(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: TextFormField(
                      controller: oldPassController,
                      obscureText: true,
                      keyboardType: TextInputType.visiblePassword,
                      decoration: const InputDecoration(
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: HomeAutomationColors.lightPrimary,
                          ),
                        ),
                        prefixIcon: Icon(Icons.password),
                        border: OutlineInputBorder(),
                        hintText: "Nhập mật khẩu cũ",
                        labelText: "Mật khẩu cũ",
                        labelStyle: TextStyle(color: HomeAutomationColors.lightPrimary),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: TextFormField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Mật khẩu không được để trống!';
                        } else if (value.length < 6 || value.length > 30) {
                          return 'Độ dài mật khẩu phải từ 6 đến 30 ký tự!';
                        } else if (!RegExp(
                                r"^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).*$")
                            .hasMatch(value)) {
                          return 'Mật khẩu phải chứa ít nhất 1 ký tự hoa, 1 ký tự thường,'
                              '\n1 chữ số và 1 ký tự đặc biệt!';
                        }
                        return null;
                      },
                      controller: newPassController,
                      obscureText: _obscureText,
                      keyboardType: TextInputType.visiblePassword,
                      decoration: InputDecoration(
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: HomeAutomationColors.lightPrimary,
                          ),
                        ),
                        prefixIcon: const Icon(Icons.password),
                        suffixIcon: InkWell(
                          onTap: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                          child: Icon(
                            _obscureText
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.black,
                          ),
                        ),
                        border: const OutlineInputBorder(),
                        hintText: "Nhập mật khẩu mới",
                        labelText: "Mật khẩu mới",
                        labelStyle: const TextStyle(color: HomeAutomationColors.lightPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: TextFormField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Mật khẩu xác thực không được để trống!';
                        } else if (value.toString() != newPassController.text) {
                          return 'Mật khẩu xác thực không khớp!';
                        }
                        return null;
                      },
                      controller: confirmPassController,
                      obscureText: true,
                      keyboardType: TextInputType.visiblePassword,
                      decoration: const InputDecoration(
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: HomeAutomationColors.lightPrimary,
                          ),
                        ),
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                        hintText: "Nhập lại mật khẩu",
                        labelText: "Mật khẩu xác thực",
                        labelStyle: TextStyle(color: HomeAutomationColors.lightPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Lưu'),
              onPressed: () async {
                if (_formkey.currentState!.validate() &&
                    oldPassController.text == password) {
                  changePassword(
                      email: currentUser.email,
                      oldPassword: oldPassController.text,
                      newPassword: newPassController.text);
                  await userDatabase.update(
                      id: int.parse(currentUser.id),
                      fullName: nameController.text,
                      userName: nameController.text,
                      email: currentUser.email.toString(),
                      password: newPassController.text,
                      imgPath: currentUser.imgPath);
                  var dataUser =
                      await userDatabase.fetchById(int.parse(currentUser.id));
                  await prefs.setString("user", jsonEncode(dataUser.toJson()));
                  await prefs.setString("pw", newPassController.text);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      backgroundColor: HomeAutomationColors.lightPrimary,
                      content: Text(
                        "Thay đổi mật khẩu thành công!",
                      )));
                  setState(() {
                    getSharedPreferences();
                  });
                  oldPassController.clear();
                  newPassController.clear();
                  confirmPassController.clear();
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      backgroundColor: Colors.red,
                      content: Text(
                        "Mật khẩu cũ không chính xác!",
                      )));
                }
              },
            ),
          ],
        );
      },
    );
  }

  void changePassword(
      {required email, required oldPassword, required newPassword}) async {
    var cred =
        EmailAuthProvider.credential(email: email, password: oldPassword);
    await FirebaseAuth.instance.currentUser!
        .reauthenticateWithCredential(cred)
        .then((value) {
      FirebaseAuth.instance.currentUser!.updatePassword(newPassword);
    });
  }

  Uint8List convertStringToUint8List(String str) {
    final List<int> codeUnits = str.codeUnits;
    final Uint8List unit8List = Uint8List.fromList(codeUnits);

    return unit8List;
  }

  String convertUint8ListToString(Uint8List uint8list) {
    return String.fromCharCodes(uint8list);
  }

  void selectImage() async {
    Uint8List img =
        (await picker.pickImage(source: ImageSource.gallery)) as Uint8List;
    setState(() {
      _image = img;
      UserDetail tmp = UserDetail(
          fullName: nameController.text,
          userName: currentUser.email
              .toString()
              .substring(0, currentUser.email.toString().indexOf('@')),
          email: currentUser.email,
          imgPath: convertUint8ListToString(_image!),
          id: currentUser.id);
      databaseRef.updateUserDetail(currentUser.id, tmp);
    });
    await userDatabase.update(
        id: int.parse(currentUser.id),
        fullName: nameController.text,
        userName: currentUser.email
            .toString()
            .substring(0, currentUser.email.toString().indexOf('@')),
        email: currentUser.email,
        password: currentUser.password ?? '',
        imgPath: convertUint8ListToString(_image!));
    var dataUser = await userDatabase.fetchById(int.parse(currentUser.id));
    await prefs.setString("user", jsonEncode(dataUser.toJson()));
    getSharedPreferences();
  }

  Future<void> _signOut() async {
    await sharedPref.write(key: "user", value: "");
    await sharedPref.write(key: "isLoggedIn", value: "");
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    GoRouter.of(Utils.mainNav.currentContext!).go(LogIn.route);
  }

  Widget buildLoadingScreen(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          backgroundColor: HomeAutomationColors.lightPrimary,
        ),
        SizedBox(
          height: 10,
        ),
        Text(
          "Loading...",
          style: TextStyle(fontSize: 25, color: HomeAutomationColors.lightPrimary),
        )
      ],
    );
  }
}
