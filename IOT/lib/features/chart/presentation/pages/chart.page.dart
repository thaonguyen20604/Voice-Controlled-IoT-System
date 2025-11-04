import 'package:flutter/material.dart';
import 'package:home_automation_app/features/chart/presentation/widgets/radial_bar_chart_page.dart';
import 'package:home_automation_app/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation_app/features/shared/widgets/main_page_header.dart';
import 'package:home_automation_app/features/shared/widgets/warning_message.dart';
import 'package:home_automation_app/helpers/enums.dart';

class ChartPage extends StatelessWidget {
  static const String route = '/chart';

  const ChartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MainPageHeader(
          icon: FlickyAnimatedIcons(
            icon: FlickyAnimatedIconOptions.barrooms,
            size: FlickyAnimatedIconSizes.medium,
            isSelected: true,
          ),
          title: 'My Chart',
        ),
         RadialBarChartPage(),
      ],
    ));
  }
}
