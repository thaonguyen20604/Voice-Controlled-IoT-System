import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../../data/models/user_detail.dart';

const String USER_COLLECTION_REF = "UserDetail";

class UserDatabaseRef {
  final databaseReference = FirebaseDatabase.instance.ref("users");

  final _firestore = FirebaseFirestore.instance;

  Future<void> addUserDetail(UserDetail user) async {
    _firestore.collection(USER_COLLECTION_REF).add(user.toJson());
  }

  Future<void> updateUserDetail(String id, UserDetail userUpdated) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection(USER_COLLECTION_REF)
        .where('id', isEqualTo: id)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      String docId = querySnapshot.docs.first.id;
      await _firestore
          .collection(USER_COLLECTION_REF)
          .doc(docId)
          .update(userUpdated.toJson());
    }
  }

  Future<UserDetail> getUserDetails(String id) async {
    final snapshot = await _firestore
        .collection(USER_COLLECTION_REF)
        .where("id", isEqualTo: id)
        .get();
    final userData =
        snapshot.docs.map((e) => UserDetail.fromSnapshot(e)).single;
    return userData;
  }
}
