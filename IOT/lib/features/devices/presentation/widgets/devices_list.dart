import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation_app/features/devices/presentation/pages/device_details.page.dart';
import 'package:home_automation_app/features/devices/presentation/providers/device_providers.dart';
import 'package:home_automation_app/features/devices/presentation/widgets/device_row_item.dart';
import 'package:home_automation_app/features/shared/widgets/warning_message.dart';
import 'package:home_automation_app/styles/styles.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../helpers/enums.dart';
import '../../../../helpers/utils.dart';
import '../../../shared/services/localstorage.service.dart';
import '../../data/models/device.model.dart';

class DevicesList extends ConsumerWidget {
  const DevicesList({super.key});

  Future<List<DeviceModel>> getStringData() async {
    final prefs = await SharedPreferences.getInstance();
    List<DeviceModel> deviceList = [];
    final configAsString =
        prefs.getString(LocalStorageService.deviceListConfig) ?? '';

    if (configAsString.isNotEmpty) {
      List<dynamic> decodedList = json.decode(configAsString);

      deviceList = decodedList
          .map((e) => DeviceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return deviceList;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refDevice = FirebaseDatabase.instance.ref('devices');
    return FutureBuilder<List<DeviceModel>>(
      future: getStringData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return const WarningMessage(message: "No available devices");
        } else if (snapshot.hasData) {
          final devicesList =
              List<DeviceModel>.from(snapshot.data as List<DeviceModel>);
          if (devicesList.isEmpty) {
            return const WarningMessage(message: "No available devices");
          }
          return ListView.builder(
            itemCount: devicesList.length,
            padding: HomeAutomationStyles.mediumPadding,
            itemBuilder: (context, index) {
              return StreamBuilder(
                  stream: refDevice.child(devicesList[index].id).onValue,
                  builder: (BuildContext context,
                      AsyncSnapshot<DatabaseEvent> event) {
                    if (event.hasError) {
                      return const Center(
                          child: Text(
                        'Something went wrong',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ));
                    }

                    if (event.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: Text(
                        "Loading",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ));
                    }

                    if (!event.data!.snapshot.exists) {
                      return const Center(
                          child: Text(
                        "Empty",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ));
                    }
                    final myDevices = Map<dynamic, dynamic>.from(
                        (event.data!).snapshot.value as Map<dynamic, dynamic>);
                    final nameIcon = myDevices['iconOption'].toString();
                    FlickyAnimatedIconOptions icon =
                        FlickyAnimatedIconOptions.lightbulb;
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
                    final deviceModel = DeviceModel(
                        id: myDevices["id"],
                        iconOption: icon,
                        label: myDevices["label"],
                        isSelected: myDevices["isSelected"]);
                    return DeviceRowItem(
                            device: deviceModel,
                            onTapDevice: (device) {
                              ref
                                  .read(deviceListVMProvider.notifier)
                                  .showDeviceDetails(device);
                            })
                        .animate(
                          delay: (index * 0.125).seconds,
                        )
                        .slideY(
                            begin: 0.5,
                            end: 0,
                            duration: 0.5.seconds,
                            curve: Curves.easeInOut)
                        .fadeIn(duration: 0.5.seconds, curve: Curves.easeInOut);
                  });
            },
          );
        } else {
          return const WarningMessage(message: "No available devices");
        }
      },
    );
  }
}
