import 'dart:async';
import 'dart:convert';
import 'dart:core';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation_app/features/landing/data/models/notification_model.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/utils.dart';
import '../../../../styles/styles.dart';
import '../../../auth/data/models/user_detail.dart';

class NotificationPage extends StatefulWidget {
  @override
  State<NotificationPage> createState() => _NotificationPageState();

  static const String route = '/notification';

  const NotificationPage({super.key});
}

class _NotificationPageState extends State<NotificationPage> {
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

  //Convert Date
  String timeAgo(int milliseconds) {
    final now = DateTime.now();
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    final diff = now.difference(date);

    if (diff.inSeconds < 60) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inDays < 2) {
      return 'yesterday';
    } else {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    }
  }

  //Check Internet
  bool isConnectedToInternet = true;
  StreamSubscription? _internetConnectionStreamSubscription;
  final myController = TextEditingController();

  String _value = "";

  Stream<DatabaseEvent> stream() async* {
    final Stream<DatabaseEvent> notificationsStream = FirebaseDatabase.instance
        .ref('notifications')
        .orderByChild("date")
        .onValue;
    yield* notificationsStream;
  }

  DatabaseReference ref = FirebaseDatabase.instance.ref("notifications");

  Stream<DatabaseEvent> searchData(String value) async* {
    final Stream<DatabaseEvent> searchStream =
        ref.orderByChild("nameDevice").equalTo(value).onValue;

    yield* searchStream;
  }

  updateNotificationState() async {
    final event = await ref.get();
    if (event.exists) {
      final myNotifications =
          Map<dynamic, dynamic>.from(event.value as Map<dynamic, dynamic>);
      myNotifications.forEach((key, value) async {
        final currentNotification = Map<String, dynamic>.from(value);
        if (currentNotification['isRead'] == false &&
            currentNotification['userId'] == id) {
          await ref.child(currentNotification['id']).update({"isRead": true});
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getSharedPreferences();
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
            isConnectedToInternet = false;
          });
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return MaterialApp(
      title: 'Notification',
      home: SafeArea(
          child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) {
            return;
          }
          await updateNotificationState();
          GoRouter.of(Utils.mainNav.currentContext!).pop();
        },
        child: Scaffold(
            appBar: AppBar(
              elevation: 0,
              foregroundColor: Colors.black,
              backgroundColor: Colors.grey[100],
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  await updateNotificationState();
                  GoRouter.of(Utils.mainNav.currentContext!).pop();
                },
              ),
              centerTitle: true,
              title: const Text(
                'Notification',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            body: isConnectedToInternet
                ? Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          controller: myController,
                          onChanged: (value) {
                            setState(() {
                              _value = value;
                            });
                          },
                          decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: IconButton(
                                  onPressed: clear,
                                  icon: const Icon(Icons.clear)),
                              hintText: 'Search Notifications',
                              contentPadding: const EdgeInsets.all(16.0),
                              fillColor: Colors.black12,
                              filled: true,
                              border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.circular(10.0))),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Expanded(
                          child: StreamBuilder<DatabaseEvent>(
                        stream:
                            _value.isNotEmpty ? searchData(_value) : stream(),
                        builder: (BuildContext context,
                            AsyncSnapshot<DatabaseEvent> event) {
                          if (event.hasError) {
                            return const Center(
                                child: Text(
                              'Something went wrong',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ));
                          }

                          if (event.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: Text(
                              "Loading",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ));
                          }

                          if (!event.data!.snapshot.exists) {
                            return const Center(
                                child: Text(
                              "Empty Notification",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ));
                          }

                          List<NotificationPageModel> notificationList = [];
                          final myNotifications = Map<dynamic, dynamic>.from(
                              (event.data!).snapshot.value
                                  as Map<dynamic, dynamic>);
                          myNotifications.forEach((key, value) {
                            final currentNotification =
                                Map<String, dynamic>.from(value);
                            if (currentNotification['userId'] == id) {
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
                          if (notificationList.isEmpty) {
                            return const Center(
                                child: Text(
                              "Empty Notification",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ));
                          }
                          // notificationList = notificationList.reversed.toList();
                          return ListView.separated(
                              itemBuilder: (context, index) {
                                return Container(
                                    margin: const EdgeInsets.all(12.0),
                                    child: Slidable(
                                        endActionPane: ActionPane(
                                            extentRatio: 0.3,
                                            motion: const ScrollMotion(),
                                            children: [
                                              SlidableAction(
                                                onPressed: (context) async {
                                                  await ref
                                                      .child(notificationList[
                                                              index]
                                                          .id)
                                                      .remove();
                                                },
                                                icon: Icons.delete,
                                                foregroundColor: Colors.white,
                                                backgroundColor: Colors.red,
                                              )
                                            ]),
                                        child: ListTile(
                                          isThreeLine: true,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: size.width * 0.02),
                                          leading: const CircleAvatar(
                                            radius: 25,
                                            backgroundImage: AssetImage(
                                                "assets/icons/flicky_icon.png"),
                                          ),
                                          title: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                notificationList[index]
                                                    .nameDevice
                                                    .toString(),
                                                style: const TextStyle(
                                                    fontSize:
                                                        HomeAutomationStyles
                                                            .smallIconSize,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                timeAgo(notificationList[index]
                                                    .date),
                                                style: const TextStyle(
                                                    fontSize:
                                                        HomeAutomationStyles
                                                            .labelMediumSize,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          subtitle: Text(
                                            notificationList[index]
                                                .description
                                                .toString(),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          trailing: SizedBox(
                                              height: 100,
                                              width: 10,
                                              child: Container(
                                                  // or ClipRRect if you need to clip the content
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: !notificationList[
                                                                index]
                                                            .isRead
                                                        ? Colors.blue
                                                        : Colors
                                                            .white, // inner circle color
                                                  ),
                                                  child: Container())),
                                        )));
                              },
                              separatorBuilder: (context, index) => Divider(
                                    color: Colors.grey[400],
                                    indent: size.width * .08,
                                    endIndent: size.width * .08,
                                  ),
                              itemCount: notificationList.length);
                        },
                      ))
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        isConnectedToInternet ? Icons.wifi : Icons.wifi_off,
                        size: HomeAutomationStyles.smallIconSize,
                        color:
                            isConnectedToInternet ? Colors.green : Colors.red,
                      ),
                      Center(
                          child: Text(isConnectedToInternet
                              ? "You are connected to the internet"
                              : "You are not connected to the internet."))
                    ],
                  )),
      )),
      debugShowCheckedModeBanner: false,
    );
  }

  void clear() {
    if (myController.text.isNotEmpty) {
      myController.text = "";
      setState(() {
        _value = "";
      });
    }
  }
}
