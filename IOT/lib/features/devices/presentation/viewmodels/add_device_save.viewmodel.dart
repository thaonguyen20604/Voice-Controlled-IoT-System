import 'dart:convert';
import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation_app/features/devices/data/models/device.model.dart';
import 'package:home_automation_app/features/devices/presentation/providers/add_device_providers.dart';
import 'package:home_automation_app/features/devices/presentation/providers/device_providers.dart';
import 'package:home_automation_app/helpers/enums.dart';
import 'package:home_automation_app/helpers/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../auth/data/models/user_detail.dart';
import '../../../landing/data/models/notification_model.dart';

class AddDeviceSaveViewModel extends StateNotifier<AddDeviceStates> {
  final Ref ref;

  AddDeviceSaveViewModel(super.state, this.ref);

  Future<void> addNotification(NotificationPageModel notification, String id) {
    DatabaseReference ref = FirebaseDatabase.instance.ref('notifications');
    return ref.child(id).set(notification.toJson());
  }

  Future<void> saveDevice() async {
    state = AddDeviceStates.saving;
    await Future.delayed(1.seconds);

    // collect the info
    final label = ref.read(deviceNameValueProvider);
    final deviceType = ref
        .read(deviceTypeSelectionVMProvider.notifier)
        .getSelectedDeviceType();

    ref.read(deviceListVMProvider.notifier).addDevice(DeviceModel(
          id: deviceType.id,
          iconOption: deviceType.iconOption,
          label: label,
          isSelected: false,
        ));

    late UserDetail currentUser;
    late SharedPreferences prefs;
    prefs = await SharedPreferences.getInstance();
    String? currents = prefs.getString("user");
    currentUser = UserDetail.fromJson(json.decode(currents!));
    currentUser = UserDetail.fromJson(json.decode(currents));

    triggerNotification(deviceType.label);

    const id = Uuid();
    var uId = id.v1();
    await addNotification(
        NotificationPageModel(
          isRead: false,
          id: uId,
          description: '${deviceType.label} is running',
          date: DateTime.now().microsecondsSinceEpoch,
          nameDevice: deviceType.label,
          userId: currentUser.id,
          deviceId: deviceType.id,
        ),
        uId);

    /// Save to local storage
    final saveSuccess = await saveDeviceList();

    if (saveSuccess) {
      state = AddDeviceStates.saved;
      await Future.delayed(1.seconds);
      GoRouter.of(Utils.mainNav.currentContext!).pop();
    }
  }

  Future<bool> saveDeviceList() async {
    await Future.delayed(1.seconds);
    final updatedList = ref.read(deviceListVMProvider);
    ref.read(deviceRepositoryProvider).saveDeviceList(updatedList);
    return Future.value(true);
  }

  triggerNotification(String deviceName) async {
    var id = Random().nextInt(1000000);
    AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: 'basic_channel',
            title: '$deviceName is running'));
  }

  void resetAllValues() {
    state = AddDeviceStates.none;

    ref.read(deviceNameFieldProvider).clear();
    ref.read(deviceNameValueProvider.notifier).state = '';
    var rawList = ref.read(deviceTypeListProvider);
    ref.read(deviceTypeSelectionVMProvider.notifier).state = rawList;
  }
}
