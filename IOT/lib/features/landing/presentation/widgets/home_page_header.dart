import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:home_automation_app/features/landing/presentation/responsiveness/landing_page_responsive.config.dart';
import 'package:home_automation_app/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation_app/helpers/enums.dart';
import 'package:home_automation_app/styles/styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../auth/data/models/user_detail.dart';

class HomePageHeader extends StatefulWidget {
  const HomePageHeader({super.key});

  @override
  State<HomePageHeader> createState() => _HomePageHeaderState();
}

class _HomePageHeaderState extends State<HomePageHeader> {
  late UserDetail currentUser;
  late SharedPreferences prefs;

  var ggCheck;

  String name = "";

  bool isLoading = true;

  @override
  void initState() {
    getSharedPreferences();
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        isLoading = false;
      });
    });
    super.initState();
  }

  Widget buildLoadingScreen(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          backgroundColor: Colors.blue,
        ),
        SizedBox(
          height: 10,
        ),
        Text(
          "Loading...",
          style: TextStyle(fontSize: 25, color: Colors.blue),
        )
      ],
    );
  }

  getSharedPreferences() async {
    ggCheck = await GoogleSignIn().isSignedIn();
    prefs = await SharedPreferences.getInstance();
    String? currents = prefs.getString("user");
    if (currents != null) {
      setState(() {
        currentUser = UserDetail.fromJson(json.decode(currents));
        name = currentUser.userName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = LandingPageResponsiveConfig.landingPageConfig(context);

    return isLoading
        ? buildLoadingScreen(context)
        : Padding(
            padding: HomeAutomationStyles.smallPadding.copyWith(
              bottom: 0,
              left: HomeAutomationStyles.mediumSize,
            ),
            child: Row(
              children: [
                Visibility(
                  visible: config.showBoltOnHeader,
                  child: const FlickyAnimatedIcons(
                    icon: FlickyAnimatedIconOptions.bolt,
                    isSelected: true,
                    size: FlickyAnimatedIconSizes.medium,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome,',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(
                                color:
                                    Theme.of(context).colorScheme.secondary)),
                    Text(
                      name,
                      style:
                          Theme.of(context).textTheme.headlineMedium!.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ]
                      .animate(interval: 300.ms)
                      .slideX(
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
              ],
            ),
          );
  }
}
