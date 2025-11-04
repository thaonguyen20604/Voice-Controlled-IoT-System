import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetail {
  String id;
  String fullName;
  String userName;
  String email;
  String? password;
  String imgPath;

  UserDetail(
      {required this.id,
      required this.fullName,
      required this.userName,
      required this.email,
      this.password,
      required this.imgPath});

  factory UserDetail.fromSqfLiteDatabase(Map<String, dynamic> map) =>
      UserDetail(
        id: (map['id']?.toInt() ?? 0).toString(),
        fullName: map['fullName'] ?? '',
        userName: map['userName'] ?? '',
        email: map['email'] ?? '',
        password: map['password'] ?? '',
        imgPath: map['imgPath'] ?? '',
      );

  UserDetail.fromJson(Map<String, Object?> json)
      : this(
          id: json['id']! as String,
          fullName: json['fullName']! as String,
          userName: json['userName']! as String,
          email: json['email']! as String,
          imgPath: json['imgPath']! as String,
        );

  UserDetail copyWith({
    String? id,
    String? fullName,
    String? userName,
    String? email,
    String? imgPath,
  }) {
    return UserDetail(
        id: id ?? this.id,
        fullName: fullName ?? this.fullName,
        userName: userName ?? this.userName,
        email: email ?? this.email,
        imgPath: imgPath ?? this.imgPath);
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'userName': userName,
      'email': email,
      'imgPath': imgPath,
    };
  }

  factory UserDetail.fromSnapshot(
      QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    return UserDetail.fromJson(data);
  }
}
