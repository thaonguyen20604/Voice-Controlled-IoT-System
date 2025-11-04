import 'dart:ffi';


class Statistic {
  String id;
  double amount;
  String userId;
  String deviceId;
  String deviceName;

  Statistic(
      {required this.id,
      required this.amount,
      required this.userId,
      required this.deviceId,
      required this.deviceName});

  factory Statistic.fromSqfLiteDatabase(Map<String, dynamic> map) => Statistic(
      id: map['id']?.toInt() ?? 0,
      amount: map['amount'].toDouble ?? 0.0,
      userId: map['userId'] ?? "",
      deviceId: map['deviceId'] ?? "",
      deviceName: map["deviceName"] ?? "");

  Statistic.fromJson(Map<String, Object?> json)
      : this(
          id: json['id']! as String,
          amount: json['amount']! as double,
          userId: json['userId']! as String,
          deviceId: json['deviceId']! as String,
          deviceName: json['deviceName']! as String,
        );


  Map<String, Object?> toJson() {
    return {
      'id': id,
      'amount': amount,
      'userId': userId,
      'deviceId': deviceId,
      'deviceName': deviceName,
    };
  }


}
