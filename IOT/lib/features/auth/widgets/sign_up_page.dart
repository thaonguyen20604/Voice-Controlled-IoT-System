import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation_app/features/auth/widgets/login_page.dart';
import '../../../helpers/utils.dart';
import '../../../styles/colors.dart';
import '../data/models/user_detail.dart';
import '../presentation/service/firebase/auth.dart';
import '../presentation/service/firebase/user_database_ref.dart';
import '../presentation/service/sqlite/user_database.dart';

class SignUp extends StatefulWidget {
  static const String route = '/sign_up';

  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  var _obscureText = true;
  final _formkey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController repasswordController = TextEditingController();
  TextEditingController mailController = TextEditingController();
  bool isLoading = false;
  final userDatabase = UserDatabase();
  final UserDatabaseRef userRef = UserDatabaseRef();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: HomeAutomationColors.lightPrimary,
          centerTitle: true,
          title: const Text("Sign up",
              style: TextStyle(
                  fontSize: 30.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ),
        body: Stack(children: [
          SingleChildScrollView(
              child: Column(
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
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Username must not be empty!';
                            } else if (value.length < 4) {
                              return 'Username is too short!';
                            }
                            return null;
                          },
                          autofocus: true,
                          controller: nameController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.account_box_rounded),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: HomeAutomationColors.lightPrimary,
                              ),
                            ),
                            hintText: "Enter username",
                            labelText: "Username",
                            labelStyle: TextStyle(color: HomeAutomationColors.lightPrimary),
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
                              return 'Email must not be empty!';
                            } else if (value.length < 6) {
                              return 'Email is too short!';
                            } else if (!RegExp(
                                    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$")
                                .hasMatch(value)) {
                              return 'Invalid email!';
                            }
                            return null;
                          },
                          controller: mailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: HomeAutomationColors.lightPrimary,
                              ),
                            ),
                            prefixIcon: Icon(Icons.mail),
                            border: OutlineInputBorder(),
                            hintText: "Enter email",
                            labelText: "Email",
                            labelStyle: TextStyle(color: HomeAutomationColors.lightPrimary),
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
                              return 'Password must not be empty!';
                            } else if (value.length < 6 || value.length > 30) {
                              return 'Password has to contain 6 to 30 characters!';
                            } else if (!RegExp(
                                    r"^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).*$")
                                .hasMatch(value)) {
                              return 'Password has to contain 1 uppercase, 1 lowercase,'
                                  '\n1 number và 1 special character!';
                            }
                            return null;
                          },
                          controller: passwordController,
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
                            hintText: "Enter password",
                            labelText: "Password",
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
                              return 'Confirmation password must not be empty!';
                            } else if (value.toString() !=
                                passwordController.text) {
                              return 'Confirmation password is not matched!';
                            }
                            return null;
                          },
                          controller: repasswordController,
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
                            hintText: "Enter confirmation password",
                            labelText: "Confirmation password",
                            labelStyle: TextStyle(color: HomeAutomationColors.lightPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 30.0,
                      ),
                      InkWell(
                        onTap: () async {
                          if (_formkey.currentState!.validate()) {
                            var message = await register(context);
                            if (message == 'Sign up successfully!' &&
                                message != null) {
                              setState(() {
                                isLoading = true;
                              });
                              Future.delayed(const Duration(seconds: 2), () {
                                setState(() {
                                  isLoading = false;
                                });
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
                                  GoRouter.of(Utils.mainNav.currentContext!)
                                      .go(LogIn.route);
                                });
                              });
                            } else {
                              setState(() {
                                isLoading = false;
                              });
                            }
                          }
                        },
                        child: Ink(
                            width: MediaQuery.of(context).size.width,
                            padding: const EdgeInsets.symmetric(
                                vertical: 15.0, horizontal: 30.0),
                            decoration: BoxDecoration(
                                color: HomeAutomationColors.lightPrimary,
                                borderRadius: BorderRadius.circular(30)),
                            child: const Center(
                                child: Text(
                              "Sign up",
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
              const Text(
                "or Sign in by",
                style: TextStyle(
                    color: HomeAutomationColors.lightPrimary,
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 30.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
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
                  const Text("Have an account already?",
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(
                    width: 5.0,
                  ),
                  GestureDetector(
                    onTap: () {
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        GoRouter.of(Utils.mainNav.currentContext!)
                            .go(LogIn.route);
                      });
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(
                          color: HomeAutomationColors.lightPrimary,
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          )),
          _buildViewSubmit(context, isLoading),
        ]));
  }

  register(BuildContext context) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: mailController.text, password: passwordController.text);
      var id = await userDatabase.create(
          fullName: nameController.text,
          userName: mailController.text
              .substring(0, mailController.text.indexOf('@')),
          email: mailController.text,
          password: passwordController.text,
          imgPath: 'images/avatar.png');
      id ??= await userDatabase.create(
          fullName: nameController.text,
          userName: mailController.text
              .substring(0, mailController.text.indexOf('@')),
          email: mailController.text,
          password: passwordController.text,
          imgPath: 'images/avatar.png');
      print('User created in SQLite with id: $id');
      UserDetail user = UserDetail(
          fullName: nameController.text,
          userName: mailController.text
              .substring(0, mailController.text.indexOf('@')),
          email: mailController.text,
          imgPath: 'images/avatar.png',
          id: id.toString() ?? "0");
      userRef.addUserDetail(user);
      return "Sign up successfully!";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              "Weak password!",
            )));
        return "Weak password!";
      } else if (e.code == "email-already-in-use") {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              "Email already in use!",
            )));
        return "Email already in use!";
      }
    }
  }

  Widget _buildViewSubmit(BuildContext context, isLoading) {
    if (isLoading) {
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
                'Connecting to backend server...',
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
