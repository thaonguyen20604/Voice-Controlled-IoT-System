import 'dart:async';

import 'package:flutter/material.dart';
import 'package:home_automation_app/features/settings/presentation/pages/profile_page.dart';
import 'package:home_automation_app/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation_app/features/shared/widgets/main_page_header.dart';
import 'package:home_automation_app/helpers/enums.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../../../../styles/styles.dart';

class SettingsPage extends StatefulWidget {
  static const String route = '/settings';

  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  //Check Internet
  bool isConnectedToInternet = true;
  StreamSubscription? _internetConnectionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _internetConnectionStreamSubscription =
        InternetConnection().onStatusChange.listen((event) {
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
            isConnectedToInternet = true;
          });
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return isConnectedToInternet
        ? const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 1,
                child: MainPageHeader(
                  icon: FlickyAnimatedIcons(
                    icon: FlickyAnimatedIconOptions.barsettings,
                    size: FlickyAnimatedIconSizes.medium,
                    isSelected: true,
                  ),
                  title: 'My Profile',
                ),
              ),
              Flexible(flex: 1, child: Profile())
            ],
          )
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
}
