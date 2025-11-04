import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation_app/features/auth/widgets/forgot_password_page.dart';
import 'package:home_automation_app/features/auth/widgets/sign_up_page.dart';
import 'package:home_automation_app/features/landing/presentation/pages/home.page.dart';
import 'package:home_automation_app/styles/colors.dart';

import '../../../helpers/utils.dart';
import '../presentation/service/firebase/SharedPref.dart';
import '../presentation/service/firebase/auth.dart';
import '../presentation/service/sqlite/database.dart';
import '../presentation/service/sqlite/user_database.dart';

class LogIn extends StatefulWidget {
  static const String route = '/login';

  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  String email = "", password = "";
  var _obscureText = true;
  final _formkey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isLoading1 = false;
  final FirebaseAuth auth = FirebaseAuth.instance;
  SharedPrefService sharedPref = SharedPrefService();
  TextEditingController mailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final userDatabase = UserDatabase();

  Future<void> getDatabase() async {
    await DataBaseService().database;
  }

  @override
  void initState() {
    initHome();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: HomeAutomationColors.lightPrimary,
          centerTitle: true,
          title: const Text("Sign in",
              style: TextStyle(
                  fontSize: 30.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ),
        body: Stack(children: [
          Center(
            child: SingleChildScrollView(
              child: Builder(builder: (context) {
                return isLoading
                    ? buildLoadingScreen(context)
                    : Column(
                        children: [
                          SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: Image.asset(
                                "assets/images/IOT.jpg",
                                fit: BoxFit.cover,
                              )),
                          const SizedBox(
                            height: 30.0,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Form(
                              key: _formkey,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: TextFormField(
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Email cant be emptied!';
                                        } else if (!RegExp(
                                                r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$")
                                            .hasMatch(value)) {
                                          return 'Invalid email!';
                                        }
                                        return null;
                                      },
                                      autofocus: true,
                                      controller: mailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: const InputDecoration(
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: HomeAutomationColors.lightSecondary,
                                          ),
                                        ),
                                        prefixIcon: Icon(Icons.mail),
                                        border: OutlineInputBorder(),
                                        hintText: "Enter email",
                                        labelText: "Email",
                                        labelStyle:
                                            TextStyle(color: HomeAutomationColors.lightPrimary),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 10.0,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: TextFormField(
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Password cant be emptied!';
                                        }
                                        return null;
                                      },
                                      controller: passwordController,
                                      obscureText: _obscureText,
                                      keyboardType:
                                          TextInputType.visiblePassword,
                                      decoration: InputDecoration(
                                          prefixIcon:
                                              const Icon(Icons.password),
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
                                          focusedBorder:
                                              const OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: HomeAutomationColors.lightPrimary,
                                            ),
                                          ),
                                          border: const OutlineInputBorder(),
                                          hintText: "Enter password",
                                          labelText: "Password",
                                          labelStyle: const TextStyle(
                                              color: HomeAutomationColors.lightPrimary)),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 30.0,
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      if (_formkey.currentState!.validate()) {
                                        setState(() {
                                          email = mailController.text;
                                          password = passwordController.text;
                                        });
                                      }
                                      var message = await login(context);
                                      if (message == 'Sign in successfully!' &&
                                          message != null) {
                                        setState(() {
                                          isLoading1 = true;
                                        });
                                        var user=await userDatabase.fetchByEmail(email);
                                        sharedPref.write(
                                            key: "isLoggedIn", value: "1");
                                        sharedPref.write(key: "user", value: jsonEncode(user.toJson()));
                                        sharedPref.write(key: "pw", value: passwordController.text);
                                        Future.delayed(
                                            const Duration(seconds: 2), () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                            content: Text(
                                              message.toString(),
                                              style: const TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            backgroundColor: HomeAutomationColors.lightPrimary,
                                          ));
                                          SchedulerBinding.instance
                                              .addPostFrameCallback((_) {
                                            GoRouter.of(Utils
                                                    .mainNav.currentContext!)
                                                .go(HomePage.route);
                                          });
                                        });
                                      } else {
                                        setState(() {
                                          isLoading1 = false;
                                        });
                                      }
                                    },
                                    child: Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 15.0, horizontal: 30.0),
                                        decoration: BoxDecoration(
                                            color: HomeAutomationColors.lightPrimary,
                                            borderRadius:
                                                BorderRadius.circular(30)),
                                        child: const Center(
                                            child: Text(
                                          "Sign in",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 25.0,
                                              fontWeight: FontWeight.bold),
                                        ))),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20.0,
                          ),
                          GestureDetector(
                            onTap: () {
                              GoRouter.of(Utils.mainNav.currentContext!)
                                  .push(ForgotPassword.route);
                            },
                            child: const Text("Forgot password?",
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(
                            height: 20.0,
                          ),
                          const Text(
                            "or Sign in by",
                            style: TextStyle(
                                color: HomeAutomationColors.lightPrimary,
                                fontSize: 25.0,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(
                            height: 30.0,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isLoading = true;
                                  });
                                  AuthService().signInWithGoogle(context);
                                },
                                child: Image.asset(
                                  "assets/images/google.png",
                                  height: 45,
                                  width: 45,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              // const SizedBox(
                              //   width: 30.0,
                              // ),
                              // GestureDetector(
                              //   onTap: (){
                              //     // AuthMethods().signInWithApple();
                              //   },
                              //   child: Image.asset(
                              //     "images/apple.png",
                              //     height: 50,
                              //     width: 50,
                              //     fit: BoxFit.cover,
                              //   ),
                              // )
                            ],
                          ),
                          const SizedBox(
                            height: 40.0,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Create an account?",
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(
                                width: 5.0,
                              ),
                              GestureDetector(
                                onTap: () {
                                  GoRouter.of(Utils.mainNav.currentContext!)
                                      .push(SignUp.route);
                                },
                                child: const Text(
                                  "Sign up",
                                  style: TextStyle(
                                      color:HomeAutomationColors.lightPrimary,
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          )
                        ],
                      );
              }),
            ),
          ),
          _buildViewSubmit(context, isLoading1)
        ]));
  }

  login(BuildContext context) async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      return "Sign in successfully!";
    } on FirebaseAuthException catch (e) {
      print(e);
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              "User not found!",
            )));
        return "User not found!";
      } else if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              "Invalid password!",
            )));
        return "Invalid password!";
      }
    }
  }

  initHome() async {
    await getDatabase();
    String? value = await sharedPref.read(key: "isLoggedIn");
    if (value != null && value.isNotEmpty) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        GoRouter.of(Utils.mainNav.currentContext!).go(HomePage.route);
      });
    }
  }

  Widget buildLoadingScreen(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          backgroundColor:HomeAutomationColors.lightPrimary,
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

  Widget _buildViewSubmit(BuildContext context, _isLoading) {
    if (_isLoading) {
      return Container(
        // width: double.infinity,
        height: double.infinity,
        color: Colors.white.withOpacity(0.5),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: HomeAutomationColors.lightPrimary,
              ),
              SizedBox(height: 20.0),
              Text(
                'Connecting to Home...',
                style: TextStyle(color: Colors.black, fontSize: 20),
              ),
            ],
          ),
        ),
      );
    }
    return Container();
  }
}
