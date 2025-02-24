import 'package:flicknest_flutter_frontend/features/navigation/presentation/widgets/home_automation_bottombar.dart';
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