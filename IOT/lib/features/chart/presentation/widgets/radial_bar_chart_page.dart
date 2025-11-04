import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:home_automation_app/features/chart/data/statistic_model.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../styles/styles.dart';
import '../../../auth/data/models/user_detail.dart';
import '../../../shared/widgets/warning_message.dart';

class RadialBarChartPage extends StatefulWidget {
  const RadialBarChartPage({super.key});

  @override
  State<RadialBarChartPage> createState() => _RadialBarChartPageState();
}

class _RadialBarChartPageState extends State<RadialBarChartPage> {
  DatabaseReference ref = FirebaseDatabase.instance.ref("statistics");

  //Check Internet
  bool isConnectedToInternet = true;
  StreamSubscription? _internetConnectionStreamSubscription;

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
    // TODO: implement initState
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
            isConnectedToInternet = false;
          });
          break;
      }
    });
    getSharedPreferences();
  }

  final Stream<DatabaseEvent> chartsStream = FirebaseDatabase.instance
      .ref('statistics')
      .orderByChild("amount")
      .onValue;

  @override
  Widget build(BuildContext context) {
    return isConnectedToInternet
        ? Padding(
            padding: HomeAutomationStyles.largePadding,
            child: SizedBox(
                height: 250,
                child: StreamBuilder<DatabaseEvent>(
                  stream: chartsStream,
                  builder: ((BuildContext context,
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
                      return const Expanded(
                        child: WarningMessage(message: 'No available chart'),
                      );
                    }

                    List<Statistic> listStatistic = [];
                    final myStatistics = Map<dynamic, dynamic>.from(
                        (event.data!).snapshot.value as Map<dynamic, dynamic>);
                    myStatistics.forEach((key, value) {
                      final currentStatistic = Map<String, dynamic>.from(value);
                      if (currentStatistic['userId'] == id) {
                        listStatistic.add(Statistic(
                            id: currentStatistic['id'],
                            amount: double.parse(
                                currentStatistic['amount'].toString()),
                            userId: currentStatistic['userId'],
                            deviceId: currentStatistic['deviceId'],
                            deviceName: currentStatistic['deviceName']));
                      }
                    });
                    final List<Color> colors = [];
                    for (int i = 0; i < listStatistic.length; i++) {
                      colors.add(Color.fromARGB(
                        255,
                        Random().nextInt(256),
                        Random().nextInt(256),
                        Random().nextInt(256),
                      ));
                    }

                    if (listStatistic.isEmpty) {
                      return const Center(
                          child: Text(
                        "Empty Chart",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ));
                    }

                    return AspectRatio(
                      aspectRatio: 1.3,
                      child: Row(
                        children: <Widget>[
                          const SizedBox(
                            height: 18,
                          ),
                          Expanded(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: PieChart(
                                PieChartData(
                                  pieTouchData: PieTouchData(
                                    touchCallback: (FlTouchEvent event,
                                        pieTouchResponse) {},
                                  ),
                                  borderData: FlBorderData(
                                    show: false,
                                  ),
                                  sectionsSpace: 0,
                                  centerSpaceRadius: 40,
                                  sections:
                                      showingSections(colors, listStatistic),
                                ),
                              ),
                            ),
                          ),
                          Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: createLabel(colors, listStatistic)),
                          const SizedBox(
                            width: 28,
                          ),
                        ],
                      ),
                    );
                  }),
                )))
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

  List<PieChartSectionData> showingSections(colors, List<Statistic> list) {
    List<PieChartSectionData> result = [];
    final sum = list.fold(0.0, (current, value) => current + value.amount);
    const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
    for (var i = 0; i < list.length; i++) {
      final amount = (list[i].amount / sum) * 100;
      result.add(PieChartSectionData(
        color: colors[i],
        value: amount * 100,
        title: '${amount.toStringAsFixed(2)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: shadows,
        ),
      ));
    }
    return result;
  }

  List<Widget> createLabel(colors, List<Statistic> list) {
    List<Row> result = [];
    for (var i = 0; i < list.length; i++) {
      result.add(Row(
        children: [
          Container(
            height: 15,
            width: 15,
            decoration: BoxDecoration(
              color: colors[i],
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(
            width: 5,
          ),
          Text(list[i].deviceName)
        ],
      ));
    }
    return result;
  }
}
