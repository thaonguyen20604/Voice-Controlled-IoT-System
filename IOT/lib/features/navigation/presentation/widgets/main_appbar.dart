import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation_app/features/landing/data/models/notification_model.dart';
import 'package:home_automation_app/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation_app/helpers/enums.dart';
import 'package:home_automation_app/styles/styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/utils.dart';
import '../../../auth/data/models/user_detail.dart';
import '../../../landing/presentation/widgets/notification_page.dart';

class HomeAutomationAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  const HomeAutomationAppBar({super.key});

  @override
  State<HomeAutomationAppBar> createState() => _HomeAutomationAppBarState();

  @override
  Size get preferredSize =>
      const Size.fromHeight(HomeAutomationStyles.appBarSize);
}

class _HomeAutomationAppBarState extends State<HomeAutomationAppBar> {
  ///Realtime Database
  DatabaseReference ref = FirebaseDatabase.instance.ref('notifications');
  final Stream<DatabaseEvent> _notificationsStream = FirebaseDatabase.instance
      .ref('notifications')
      .orderByChild('isRead')
      .equalTo(false)
      .onValue;

  late UserDetail currentUser;
  late SharedPreferences prefs;

  String id = "";

  getSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
    String? currents = prefs.getString("user");
    if (currents != null) {
      setState(() {
        currentUser = UserDetail.fromJson(json.decode(currents));
        id = currentUser.id;
      });
    }
  }

  @override
  void initState() {
    getSharedPreferences();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      iconTheme: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const FlickyAnimatedIcons(
        icon: FlickyAnimatedIconOptions.flickybulb,
        isSelected: true,
      ),
      centerTitle: true,
      actions: [
        SizedBox(
            width: 100,
            height: double.infinity,
            child: StreamBuilder<DatabaseEvent>(
              stream: _notificationsStream,
              builder:
                  (BuildContext context, AsyncSnapshot<DatabaseEvent> event) {
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

                List<NotificationPageModel> notificationList = [];
                if (event.data!.snapshot.exists) {
                  final myNotification = Map<dynamic, dynamic>.from(
                      (event.data!).snapshot.value as Map<dynamic, dynamic>);
                  myNotification.forEach((key, value) {
                    final currentNotification =
                        Map<String, dynamic>.from(value);
                    if (currentNotification['userId'].toString() == id) {
                      notificationList.add(NotificationPageModel(
                        id: currentNotification['id'].toString(),
                        isRead: currentNotification['isRead'],
                        description: currentNotification['description'],
                        date: currentNotification['date'],
                        nameDevice: currentNotification['nameDevice'],
                        userId: currentNotification['userId'],
                        deviceId: currentNotification['deviceId'],
                      ));
                    }
                  });
                }

                return Align(
                  alignment: Alignment.bottomRight,
                  child: Stack(
                    children: [
                      Positioned(
                        child: IconButton(
                          icon: const Icon(
                            Icons.notifications_outlined,
                          ),
                          onPressed: () {
                            GoRouter.of(Utils.mainNav.currentContext!)
                                .push(NotificationPage.route);
                          },
                        ), //Icon
                      ), //Positioned

                      Positioned(
                        top: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          child: Text(
                            notificationList.length.toString(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ), //CircularAvatar
                      ), //Positioned
                    ], //<Widget>[]
                  ),
                );
              },
            )),
        HomeAutomationStyles.xsmallHGap
      ],
    );
  }
}
