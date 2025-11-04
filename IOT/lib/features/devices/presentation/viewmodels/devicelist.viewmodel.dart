import 'dart:convert';
import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation_app/features/devices/data/models/device.model.dart';
import 'package:home_automation_app/features/devices/presentation/pages/device_details.page.dart';
import 'package:home_automation_app/features/devices/presentation/providers/device_providers.dart';
import 'package:home_automation_app/helpers/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../auth/data/models/user_detail.dart';
import '../../../landing/data/models/notification_model.dart';
import '../../../shared/services/localstorage.service.dart';

class DeviceListViewModel extends StateNotifier<List<DeviceModel>> {
  final Ref ref;

  DeviceListViewModel(super.state, this.ref);

  void initializeState(List<DeviceModel> devices) {
    state = devices;
  }

  ///Toggle Device
  void toggleDevice(DeviceModel selectedDevice) async {
    state = [
      for (final device in state)
        if (device == selectedDevice)
          device.copyWith(isSelected: !device.isSelected)
        else
          device
    ];

    ref.read(selectedDeviceProvider.notifier).state =
        state.where((d) => d.id == selectedDevice.id).first;
  }

  void addDevice(DeviceModel device) {
    state = [...state, device];
  }

  bool deviceExists(String deviceName) {
    return state.any(
        (d) => d.label.trim().toLowerCase() == deviceName.trim().toLowerCase());
  }

  ///Show detail Device
  void showDeviceDetails(device) {
    ref.read(selectedDeviceProvider.notifier).state = device;

    if (Utils.isMobile()) {
      GoRouter.of(Utils.mainNav.currentContext!).push(DeviceDetailsPage.route);
    }
  }

  Future<void> removeDevice(DeviceModel deviceData) async {
    if (Utils.isMobile()) {
      GoRouter.of(Utils.mainNav.currentContext!).pop();
    }

    late SharedPreferences prefs;
    prefs = await SharedPreferences.getInstance();
    List<DeviceModel> deviceList = [];
    final configAsString =
        prefs.getString(LocalStorageService.deviceListConfig) ?? '';

    if (configAsString.isNotEmpty) {
      List<dynamic> decodedList = json.decode(configAsString);

      deviceList = decodedList
          .map((e) => DeviceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    handleData(deviceData);
    deleteData(prefs, deviceList, deviceData);
  }

  deleteData(SharedPreferences prefs, List<DeviceModel> deviceList,
      DeviceModel currentDevice) {
    final currentList = [
      for (final device in deviceList)
        if (device.id != currentDevice.id) device
    ];
    List<Map<String, dynamic>> serializedList =
        currentList.map((device) => device.toJson()).toList();
    String deviceListAsString = json.encode(serializedList);
    prefs.setString(LocalStorageService.deviceListConfig, deviceListAsString);
  }

  handleData(DeviceModel selectedDevice) async {

    late UserDetail currentUser;
    const id = Uuid();
    var uId = id.v1();
    late SharedPreferences prefs;
    prefs = await SharedPreferences.getInstance();
    String? currents = prefs.getString("user");
    currentUser = UserDetail.fromJson(json.decode(currents!));
    currentUser = UserDetail.fromJson(json.decode(currents));

    await deleteStatistic(currentUser, selectedDevice);

    ///Add Notification
    await addNotification(
        NotificationPageModel(
          isRead: false,
          id: uId,
          description: '${selectedDevice.label} is remove',
          date: DateTime.now().microsecondsSinceEpoch,
          nameDevice: selectedDevice.label,
          userId: currentUser.id,
          deviceId: selectedDevice.id,
        ),
        uId);

    triggerNotification(selectedDevice.label);
  }

  Future<void> addNotification(NotificationPageModel notification, String id) {
    DatabaseReference ref = FirebaseDatabase.instance.ref('notifications');
    return ref.child(id).set(notification.toJson());
  }

  Future<void> deleteStatistic(UserDetail user, DeviceModel device) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref('statistics');
    final event = await ref.get();
    if (event.exists) {
      final myStatistics =
          Map<dynamic, dynamic>.from((event.value as Map<dynamic, dynamic>));
      myStatistics.forEach((key, value) {
        final currentStatistic = Map<String, dynamic>.from(value);
        if (currentStatistic['deviceId'] == device.id &&
            currentStatistic['userId'] == user.id) {
          ref.child(currentStatistic['id']).remove();
        }
      });
    }
  }

  triggerNotification(String deviceName) {
    var random = Random();
    var id = Random().nextInt(1000000);
    AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: 'basic_channel',
            title: '$deviceName is remove'));
  }
}
