import 'package:flicknest_flutter_frontend/features/landing/presentation/widgets/home_page_header.dart';
import 'package:flicknest_flutter_frontend/features/landing/presentation/widgets/home_tile_options_panel.dart';
import 'package:flicknest_flutter_frontend/helpers/enums.dart';
import 'package:flicknest_flutter_frontend/styles/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomePage extends StatelessWidget {
  static const String route = '/home';

  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Flex(
      direction: Axis.vertical,
        children: [
          Expanded(
            child: Flex(
              direction: Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomePageHeader(),
                HomeAutomationStyles.smallVGap,

                HomeTileOptionsPanel()
              ],
            ),
          )
        ],
    );
  }
}