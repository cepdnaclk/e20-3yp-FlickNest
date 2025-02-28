import 'package:flicknest_flutter_frontend/features/navigation/presentation/widgets/home_automation_appbar.dart';
import 'package:flicknest_flutter_frontend/features/navigation/presentation/widgets/home_automation_bottombar.dart';
import 'package:flicknest_flutter_frontend/features/navigation/presentation/widgets/side_menu_drawer.dart';
import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  final Widget child;
  const LandingPage({
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Drawer(
        child: SideMenuDrawer(),
      ),
      appBar: const HomeAutomationAppBar(),
      body: Flex(
        direction: Axis.vertical,
        children: [
          Expanded(
            child:SafeArea(child: child),
          ),
          const HomeAutomationBottomBar(),
        ],
      ),
    );
  }
}