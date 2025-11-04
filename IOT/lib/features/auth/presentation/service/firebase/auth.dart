import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:home_automation_app/features/auth/presentation/service/firebase/user_database_ref.dart';
import '../../../../../helpers/utils.dart';
import '../../../../landing/presentation/pages/home.page.dart';
import '../../../data/models/user_detail.dart';
import '../sqlite/user_database.dart';
import 'SharedPref.dart';

class AuthService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  UserDatabaseRef databaseRef = UserDatabaseRef();
  final userDatabase = UserDatabase();
  final SharedPrefService sharedPref = SharedPrefService();
  bool cc = false;
  var _user;

  getCurrentUser() async {
    return auth.currentUser;
  }

  Future<bool> checkUserExist(UserCredential result) async {
    final User? user = auth.currentUser;
    final email = user?.email;
    return cc;
  }

  signInWithGoogle(BuildContext context) async {
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    final GoogleSignIn googleSignIn = GoogleSignIn();

    final GoogleSignInAccount? googleSignInAccount =
        await googleSignIn.signIn();

    final GoogleSignInAuthentication? googleSignInAuthentication =
        await googleSignInAccount?.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication?.idToken,
        accessToken: googleSignInAuthentication?.accessToken);

    UserCredential result = await firebaseAuth.signInWithCredential(credential);
    User? userDetails = result.user;
    if (await checkUserExist(result) == false) {
      //SQLite
      var id = await userDatabase.create(
          fullName: userDetails!.displayName.toString(),
          userName: userDetails.email
              .toString()
              .substring(0, userDetails.email.toString().indexOf('@')),
          email: userDetails.email.toString(),
          password: "",
          imgPath: userDetails.photoURL.toString());
      id ??= await userDatabase.create(
          fullName: userDetails.displayName.toString(),
          userName: userDetails.email
              .toString()
              .substring(0, userDetails.email.toString().indexOf('@')),
          email: userDetails.email.toString(),
          password: "",
          imgPath: userDetails.photoURL.toString());

      //Firebase
      UserDetail user = UserDetail(
          fullName: userDetails.displayName.toString(),
          userName: userDetails.email
              .toString()
              .substring(0, userDetails.email.toString().indexOf('@')),
          email: userDetails.email.toString(),
          imgPath: userDetails.photoURL.toString(),
          id: id.toString());
      await databaseRef.addUserDetail(user);
    }
    _user = await userDatabase.fetchByEmail(userDetails!.email.toString());
    _user ??= await userDatabase.fetchByEmail(userDetails.email.toString());

    sharedPref.write(key: "isLoggedIn", value: "1");
    sharedPref.write(key: "user", value: jsonEncode(_user?.toJson()));
    sharedPref.write(key: "pw", value: "");
    SchedulerBinding.instance.addPostFrameCallback((_) {
      GoRouter.of(Utils.mainNav.currentContext!).go(HomePage.route);
    });
  }
}
