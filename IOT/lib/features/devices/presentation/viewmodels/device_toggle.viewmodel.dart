import 'dart:convert';
import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation_app/features/devices/data/models/device.model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../auth/data/models/user_detail.dart';
import '../../../chart/data/statistic_model.dart';
import '../../../landing/data/models/notification_model.dart';
import '../../../shared/services/localstorage.service.dart';

class DeviceToggleViewModel extends StateNotifier<bool> {
  final Ref ref;

  DeviceToggleViewModel(super.state, this.ref);

  Future<void> toggleDevice(DeviceModel selectedDevice) async {
    state = true;
    await Future.delayed(500.milliseconds);

    triggerNotification(!selectedDevice.isSelected, selectedDevice.label);

    /// Handle notification and statistic
    late UserDetail currentUser;
    late SharedPreferences prefs;
    prefs = await SharedPreferences.getInstance();
    String? currents = prefs.getString("user");
    currentUser = UserDetail.fromJson(json.decode(currents!));
    currentUser = UserDetail.fromJson(json.decode(currents));
    List<DeviceModel> deviceList = [];
    final configAsString =
        prefs.getString(LocalStorageService.deviceListConfig) ?? '';

    if (configAsString.isNotEmpty) {
      List<dynamic> decodedList = json.decode(configAsString);

      deviceList = decodedList
          .map((e) => DeviceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    setData(prefs, deviceList, selectedDevice);
    await handleData(selectedDevice, currentUser);


    state = false;
  }

  triggerNotification(bool isSelected, String deviceName) {
    var id = Random().nextInt(1000000);
    AwesomeNotifications().createNotification(
        content: NotificationContent(
      id: id,
      channelKey: 'basic_channel',
      title: '$deviceName is turn ${isSelected ? "on" : "off"}',
    ));
  }

  Future<void> addNotification(NotificationPageModel notification, String id) {
    DatabaseReference ref = FirebaseDatabase.instance.ref('notifications');
    return ref.child(id).set(notification.toJson());
  }

  Future<void> addStatistic(
      Statistic statistic, String id, UserDetail currentUser) async {
    //Add Statistic
    DatabaseReference ref = FirebaseDatabase.instance.ref('statistics');
    final refStatistic = await ref.get();
    var bool = false;
    if (refStatistic.exists) {
      final myStatistics = Map<dynamic, dynamic>.from(
          refStatistic.value as Map<dynamic, dynamic>);
      myStatistics.forEach((key, value) {
        final currentStatistic = Map<String, dynamic>.from(value);
        if (currentStatistic['deviceId'] == statistic.deviceId &&
            currentStatistic['userId'] == currentUser.id) {
          var amount = currentStatistic['amount'] + 1;
          ref.child(currentStatistic['id']).update({"amount": amount});
          bool = true;
        }
      });
      if (!bool) {
        return ref.child(id).set(statistic.toJson());
      }
    } else {
      return ref.child(id).set(statistic.toJson());
    }
  }

  handleData(DeviceModel selectedDevice, UserDetail currentUser) async {
    const id = Uuid();
    var uId = id.v1();
    //Add Statistic
    var uId1 = id.v1();
    await addStatistic(
        Statistic(
            id: uId1,
            amount: 1.0,
            userId: currentUser.id.toString(),
            deviceId: selectedDevice.id,
            deviceName: selectedDevice.label),
        uId1,
        currentUser);

    ///Add Notification
    await addNotification(
        NotificationPageModel(
          isRead: false,
          id: uId,
          description:
              '${selectedDevice.label} is turn ${!selectedDevice.isSelected ? "on" : "off"}',
          date: DateTime.now().microsecondsSinceEpoch,
          nameDevice: selectedDevice.label,
          userId: currentUser.id,
          deviceId: selectedDevice.id,
        ),
        uId);
  }

  void setData(SharedPreferences prefs, List<DeviceModel> deviceList,
      DeviceModel currentDevice) {
    final List<DeviceModel> currentList = [];
    for (final device in deviceList) {
      if (device.id == currentDevice.id) {
        device.isSelected = !device.isSelected;
      }
      currentList.add(device);
    }
    List<Map<String, dynamic>> serializedList =
        currentList.map((device) => device.toJson()).toList();
    String deviceListAsString = json.encode(serializedList);
    prefs.setString(LocalStorageService.deviceListConfig, deviceListAsString);
  }
}
