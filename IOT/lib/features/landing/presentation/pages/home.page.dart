import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:home_automation_app/features/devices/data/models/device.model.dart';
import 'package:home_automation_app/features/landing/presentation/responsiveness/landing_page_responsive.config.dart';
import 'package:home_automation_app/features/landing/presentation/widgets/energy_consumption_panel.dart';
import 'package:home_automation_app/features/landing/presentation/widgets/home_page_header.dart';
import 'package:home_automation_app/features/landing/presentation/widgets/home_tile_options_panel.dart';
import 'package:home_automation_app/styles/styles.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uuid/uuid.dart';
import '../../../../helpers/enums.dart';
import '../../../../helpers/utils.dart';
import '../../../auth/data/models/user_detail.dart';
import '../../../chart/data/statistic_model.dart';
import '../../../shared/services/localstorage.service.dart';
import '../../data/models/notification_model.dart';

class HomePage extends StatefulWidget {
  static const String route = '/home';

  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late UserDetail currentUser;

  String id = "";

  late SharedPreferences prefs;

  getDataUser() async {
    String? currents = prefs.getString("user");
    if (currents != null) {
      setState(() {
        currentUser = UserDetail.fromJson(json.decode(currents));
        id = currentUser.id;
      });
    }
  }

  DatabaseReference ref = FirebaseDatabase.instance.ref('devices');

  //Check Internet
  bool isConnectedToInternet = true;
  late final StreamSubscription<InternetStatus> _subscription;

  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _speechEnabled = false;
  String _recognizedText = "";

  bool isListening = false;

  double _confidencelevel = 0;

  List<DeviceModel> deviceList = [];

  void getDataDevice() {
    final configAsString =
        prefs.getString(LocalStorageService.deviceListConfig) ?? '';

    if (configAsString.isNotEmpty) {
      List<dynamic> decodedList = json.decode(configAsString);

      deviceList = decodedList
          .map((e) => DeviceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  @override
  void initState() {
    super.initState();
    sharedData();
    _subscription = InternetConnection().onStatusChange.listen((event) {
      switch (event) {
        case InternetStatus.connected:
          setState(() {
            isConnectedToInternet = true;
          });
          break;
        case InternetStatus.disconnected:
          setState(() {
            isConnectedToInternet = false;
          });
          break;
        default:
          setState(() {
            isConnectedToInternet = false;
          });
          break;
      }
    });
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
    _initSpeech();
  }

  triggerNotification() {
    AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 10,
            channelKey: 'basic_channel',
            title: ' Simple Notification'));
  }

  void _initSpeech() async {
    _askingPermission();
    _speechEnabled = await _speech.initialize();
    setState(() {});
  }

  void _askingPermission() async {
    final PermissionStatus permissionStatus = await _getPermission();
    if (permissionStatus == PermissionStatus.granted) {} else {
      await Permission.microphone.request();
    }
  }

  Future<PermissionStatus> _getPermission() async {
    final PermissionStatus permission = await Permission.microphone.status;
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.denied) {
      final Map<Permission, PermissionStatus> permissionStatus =
      await [Permission.microphone].request();
      return permissionStatus[Permission.microphone] ?? PermissionStatus.denied;
    } else {
      return permission;
    }
  }

  void sharedData() async {
    prefs = await SharedPreferences.getInstance();
    getDataDevice();
    getDataUser();
  }

  void _startListening() async {
    if (_speechEnabled) {
      await _speech.listen(onResult: _onSpeechResult);
      setState(() {
        isListening = true;
        _confidencelevel = 0;
      });
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    getDataDevice();
    if (deviceList.isEmpty) {
      Utils.showMessageOnSnack("Device", "Devices are empty");
      _stopListening();
    } else {
      switch (result.recognizedWords.toLowerCase()) {
        case 'tắt đèn':
          turnOff(deviceList, FlickyAnimatedIconOptions.lightbulb);
          break;
        case 'bật đèn':
          turnOn(deviceList, FlickyAnimatedIconOptions.lightbulb);
        case 'tắt quạt':
          turnOff(deviceList, FlickyAnimatedIconOptions.fan);
          break;
        case 'bật quạt':
          turnOn(deviceList, FlickyAnimatedIconOptions.fan);
          break;
        default:
      }
    }
  }

  void turnOff(List<DeviceModel> deviceList,
      FlickyAnimatedIconOptions icon) async {
    var check = false;
    for (var device in deviceList) {
      if (icon == device.iconOption) {
        if (device.isSelected) {
          check = true;
          await ref.child(device.id).update({"isSelected": !device.isSelected});
          setData(deviceList, device);
          device.isSelected = !device.isSelected;
          hanleData(device, currentUser);
          _stopListening();
          break;
        } else {
          check = true;
          Utils.showMessageOnSnack("Device", "Device is being turned off");
          _stopListening();
          break;
        }
      }
    }
    if (!check) {
      Utils.showMessageOnSnack("Device", "Device is not running");
      _stopListening();
    }
  }

  void turnOn(List<DeviceModel> deviceList,
      FlickyAnimatedIconOptions icon) async {
    var check = false;
    for (var device in deviceList) {
      if (icon == device.iconOption) {
        if (!device.isSelected) {
          check = true;
          await ref.child(device.id).update({"isSelected": !device.isSelected});
          setData(deviceList, device);
          device.isSelected = !device.isSelected;
          hanleData(device, currentUser);
          _stopListening();
          break;
        } else {
          check = true;
          Utils.showMessageOnSnack("Device", "Device is being turned on");
          _stopListening();
          break;
        }
      }
    }
    if (!check) {
      Utils.showMessageOnSnack("Device", "Device is not running");
      _stopListening();
    }
  }

  void setData(List<DeviceModel> deviceList, DeviceModel currentDevice) {
    final currentList = [
      for (final device in deviceList)
        if (device == currentDevice)
          device.copyWith(isSelected: !device.isSelected)
        else
          device
    ];
    List<Map<String, dynamic>> serializedList =
    currentList.map((device) => device.toJson()).toList();
    String deviceListAsString = json.encode(serializedList);
    prefs.setString(LocalStorageService.deviceListConfig, deviceListAsString);
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      isListening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = LandingPageResponsiveConfig.landingPageConfig(context);

    return isConnectedToInternet
        ? Scaffold(
        floatingActionButton: FloatingActionButton(
          tooltip: 'Listen',
          onPressed: () async {
            // var id = const Uuid();
            // var uUid = id.v1();
            // await addDevice(
            //     DeviceModel(
            //         id: uUid,
            //         iconOption: FlickyAnimatedIconOptions.ac,
            //         label: "ac",
            //         isSelected: false),
            //     uUid);
            _speech.isListening ? _stopListening() : _startListening();
          },
          child: Icon(isListening ? Icons.mic : Icons.mic_off),
        ),
        body: Flex(
          direction: Axis.vertical,
          children: [
            Expanded(
              flex: config.homeTopPartFlex,
              child: Flex(
                direction: config.homeTopDirection,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                      flex: config.homeHeaderFlex,
                      child: const HomePageHeader()),
                  const HomeTileOptionsPanel(),
                ],
              ),
            ),
            const EnergyConsumptionPanel()
          ],
        ))
        : Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          isConnectedToInternet ? Icons.wifi : Icons.wifi_off,
          size: HomeAutomationStyles.smallIconSize,
          color: isConnectedToInternet ? Colors.green : Colors.red,
        ),
        Text(isConnectedToInternet
            ? "You are connected to the internet"
            : "You are not connected to the internet.")
      ],
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> addDevice(DeviceModel device, String id) {
    return ref.child(id).set(device.toJson());
  }

  hanleData(DeviceModel selectedDevice, UserDetail currentUser) async {
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
          '${selectedDevice.label} is turn ${selectedDevice.isSelected
              ? "on"
              : "off"}',
          date: DateTime
              .now()
              .microsecondsSinceEpoch,
          nameDevice: selectedDevice.label,
          userId: currentUser.id,
          deviceId: selectedDevice.id,
        ),
        uId);
  }
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

Future<void> addStatistic(Statistic statistic, String id,
    UserDetail currentUser) async {
  //Add Statistic
  DatabaseReference ref = FirebaseDatabase.instance.ref('statistics');
  final refStatistic = await ref.get();
  var bool = false;
  if (refStatistic.exists) {
    final myStatistics =
    Map<dynamic, dynamic>.from(refStatistic.value as Map<dynamic, dynamic>);
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
