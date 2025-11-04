import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation_app/features/devices/data/models/device.model.dart';
import 'package:home_automation_app/features/devices/presentation/providers/device_providers.dart';
import 'package:home_automation_app/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation_app/helpers/enums.dart';
import 'package:home_automation_app/styles/colors.dart';
import 'package:home_automation_app/styles/styles.dart';

class DeviceDetailsPanel extends ConsumerWidget {
  const DeviceDetailsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget? returningWidget;

    final isDeviceSaving = ref.watch(deviceToggleVMProvider);
    var deviceData = ref.watch(selectedDeviceProvider);

    if (deviceData == null) {
      returningWidget = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt,
                size: HomeAutomationStyles.largeIconSize,
                color: Theme.of(context).colorScheme.secondary),
            Text('Select device',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge!
                    .copyWith(color: Theme.of(context).colorScheme.secondary))
          ]
              .animate(
                interval: 200.ms,
              )
              .slideY(
                begin: 0.5,
                end: 0,
                duration: 0.5.seconds,
                curve: Curves.easeInOut,
              )
              .fadeIn(
                duration: 0.5.seconds,
                curve: Curves.easeInOut,
              ),
        ),
      );
      return returningWidget;
    }

    final colorScheme = Theme.of(context).colorScheme;

    final refDevice =
        FirebaseDatabase.instance.ref('devices').child(deviceData.id);

    final Stream<DatabaseEvent> devicesStream = refDevice.onValue;


    final Stream<DatabaseEvent> devicesStreamListen =
        FirebaseDatabase.instance.ref('devices').child(deviceData.id).onValue;
    devicesStreamListen.listen((event) {
      if (event.snapshot.exists) {
        final myDevices = Map<dynamic, dynamic>.from(
            (event.snapshot.value as Map<dynamic, dynamic>));
        final nameIcon = myDevices['iconOption'].toString();
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
        final deviceModel = DeviceModel(
            id: myDevices["id"],
            iconOption: icon,
            label: myDevices["label"],
            isSelected: myDevices["isSelected"]);
        if (deviceData.isSelected != deviceModel.isSelected) {
          ref.read(deviceToggleVMProvider.notifier).toggleDevice(deviceModel);
          deviceData.isSelected = deviceModel.isSelected;
        }
      }
    });

    return StreamBuilder(
        stream: devicesStream,
        builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> event) {
          if (event.hasError) {
            return const Center(
                child: Text(
              'Something went wrong',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ));
          }

          if (event.connectionState == ConnectionState.waiting) {
            return const Center(
                child: Text(
              "Loading",
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ));
          }

          if (!event.data!.snapshot.exists) {
            return const Center(
                child: Text(
              "Empty",
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ));
          }
          final myDevices = Map<dynamic, dynamic>.from(
              (event.data!).snapshot.value as Map<dynamic, dynamic>);
          final nameIcon = myDevices['iconOption'].toString();
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
          final deviceModel = DeviceModel(
              id: myDevices["id"],
              iconOption: icon,
              label: myDevices["label"],
              isSelected: myDevices["isSelected"]);
          final selectionColor = deviceModel.isSelected
              ? colorScheme.primary
              : colorScheme.secondary;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                          HomeAutomationStyles.smallRadius),
                      color: selectionColor.withOpacity(0.125)),
                  child: Center(
                    child: Padding(
                      padding: HomeAutomationStyles.smallPadding,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FlickyAnimatedIcons(
                                    key: ValueKey(deviceModel.iconOption),
                                    icon: deviceModel.iconOption,
                                    size: FlickyAnimatedIconSizes.x2large,
                                    isSelected: deviceModel.isSelected,
                                  ),
                                  Text(deviceModel.label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium!
                                          .copyWith(color: selectionColor)),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: isDeviceSaving
                                ? const Padding(
                                    padding: HomeAutomationStyles.largePadding,
                                    child: Center(
                                      child: SizedBox(
                                          width: HomeAutomationStyles
                                              .largeIconSize,
                                          height: HomeAutomationStyles
                                              .largeIconSize,
                                          child: CircularProgressIndicator(
                                            strokeWidth:
                                                HomeAutomationStyles.smallSize,
                                          )),
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: () async {
                                      ref.read(deviceToggleVMProvider.notifier).toggleDevice(deviceModel);
                                      await refDevice.update(({
                                        "isSelected": !deviceModel.isSelected
                                      }));
                                    },
                                    child: Icon(
                                      deviceModel.isSelected
                                          ? Icons.toggle_on
                                          : Icons.toggle_off,
                                      color: deviceModel.isSelected
                                          ? colorScheme.primary
                                          : colorScheme.secondary,
                                      size:
                                          HomeAutomationStyles.x2largeIconSize,
                                    ),
                                  ),
                          )
                        ]
                            .animate(interval: 100.ms)
                            .slideY(
                              begin: 0.5,
                              end: 0,
                              duration: 0.5.seconds,
                              curve: Curves.easeInOut,
                            )
                            .fadeIn(
                              duration: 0.5.seconds,
                              curve: Curves.easeInOut,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
              HomeAutomationStyles.mediumVGap,
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !deviceModel.isSelected
                        ? HomeAutomationColors.lightPrimary
                        : colorScheme.secondary,
                  ),
                  onPressed: !deviceModel.isSelected && !isDeviceSaving
                      ? () {
                          ref
                              .read(deviceListVMProvider.notifier)
                              .removeDevice(deviceModel);
                        }
                      : null,
                  child: const Text('Remove This Device')),
            ],
          );
        });
  }
}
