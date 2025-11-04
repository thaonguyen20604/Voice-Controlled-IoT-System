import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation_app/features/devices/data/models/device.model.dart';

import 'package:home_automation_app/features/devices/presentation/providers/device_providers.dart';
import 'package:home_automation_app/features/devices/presentation/viewmodels/add_device_type.viewmodel.dart';
import 'package:home_automation_app/features/devices/presentation/viewmodels/add_device_save.viewmodel.dart';
import 'package:home_automation_app/helpers/enums.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/services/localstorage.service.dart';

final deviceNameFieldProvider = Provider((ref) {
  return TextEditingController();
});

final deviceNameValueProvider = StateProvider<String>((ref) => '');

final deviceTypeListProvider = Provider<List<DeviceModel>>((ref) {


  ///Realtime Database
  final Stream<DatabaseEvent> _devicesStream =
      FirebaseDatabase.instance.ref('devices').onValue;

  final List<DeviceModel> listDevices = [];
  _devicesStream.listen((DatabaseEvent event) async {
    listDevices.clear();
    final prefs = await SharedPreferences.getInstance();
    List<DeviceModel> devicesList = [];
    final configAsString =
        prefs.getString(LocalStorageService.deviceListConfig) ?? '';

    if (configAsString.isNotEmpty) {
      List<dynamic> decodedList = json.decode(configAsString);

      devicesList = decodedList
          .map((e) => DeviceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (event.snapshot.exists) {
      final myDevices = Map<dynamic, dynamic>.from(
          (event.snapshot).value as Map<dynamic, dynamic>);
      myDevices.forEach((key, value) {
        final currentDevice = Map<String, dynamic>.from(value);
        final nameIcon = currentDevice['iconOption'].toString();
        FlickyAnimatedIconOptions icon = FlickyAnimatedIconOptions.lightbulb;
        if (nameIcon == 'fan') {
          icon = FlickyAnimatedIconOptions.fan;
        } else if (nameIcon == 'hairdryer') {
          icon = FlickyAnimatedIconOptions.hairdryer;
        } else if (nameIcon == 'oven') {
          icon = FlickyAnimatedIconOptions.oven;
        } else if (nameIcon == 'bolt') {
          icon = FlickyAnimatedIconOptions.bolt;
        } else if (nameIcon == 'lightbulb') {
          icon = FlickyAnimatedIconOptions.lightbulb;
        } else if (nameIcon == 'ac') {
          icon = FlickyAnimatedIconOptions.ac;
        }
        if (devicesList.isNotEmpty) {
          var bool = false;
          for (var device in devicesList) {
            if (device.id == currentDevice['id']) {
              bool = true;
              break;
            }
          }
          if (!bool) {
            listDevices.add(DeviceModel(
                id: currentDevice['id'],
                iconOption: icon,
                label: currentDevice['label'].toString(),
                isSelected: currentDevice['isSelected']));
          }
        } else {
          listDevices.add(DeviceModel(
              id: currentDevice['id'],
              iconOption: icon,
              label: currentDevice['label'].toString(),
              isSelected: currentDevice['isSelected']));
        }
      });
    }
  });
  return listDevices;
});

final deviceExistsValidatorProvider = Provider<bool>((ref) {
  var deviceName = ref.watch(deviceNameValueProvider);
  return ref.read(deviceListVMProvider.notifier).deviceExists(deviceName);
});

final deviceTypeSelectionVMProvider =
    StateNotifierProvider<AddDeviceTypeViewModel, List<DeviceModel>>((ref) {
  final deviceTypesList = ref.read(deviceTypeListProvider);
  return AddDeviceTypeViewModel(deviceTypesList, ref);
});

final formValidationProvider = Provider<bool>((ref) {
  var deviceName = ref.watch(deviceNameValueProvider);
  var deviceTypes = ref.watch(deviceTypeSelectionVMProvider);
  var deviceTypeSelected = deviceTypes.any((e) => e.isSelected);

  var deviceDoesNotExist =
      !ref.read(deviceListVMProvider.notifier).deviceExists(deviceName);

  var isFormValid =
      deviceName.isNotEmpty && deviceTypeSelected && deviceDoesNotExist;

  return isFormValid;
});

final saveAddDeviceVMProvider =
    StateNotifierProvider<AddDeviceSaveViewModel, AddDeviceStates>((ref) {
  return AddDeviceSaveViewModel(AddDeviceStates.none, ref);
});
