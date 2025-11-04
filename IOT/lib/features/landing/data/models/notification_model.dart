class NotificationPageModel {
  final String id;
  final String description;
  final int date;
  final bool isRead;
  final String nameDevice;
  final String userId;
  final String deviceId;

  const NotificationPageModel(
      {required this.deviceId,
      required this.isRead,
      required this.id,
      required this.description,
      required this.date,
      required this.nameDevice,
      required this.userId});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'date': date,
      'isRead': isRead,
      'nameDevice': nameDevice,
      'userId': userId,
      'deviceId': deviceId
    };
  }

  factory NotificationPageModel.fromJson(Map<String, dynamic> json) {
    return NotificationPageModel(
      id: json['id'],
      isRead: json['isRead'],
      description: json['description'],
      date: json['date'],
      nameDevice: json['nameDevice'],
      userId: json['userId'],
      deviceId: json['nameDevice'],
    );
  }
}
