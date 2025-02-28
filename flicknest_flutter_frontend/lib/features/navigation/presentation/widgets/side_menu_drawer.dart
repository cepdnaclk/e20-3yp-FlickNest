import 'package:flicknest_flutter_frontend/features/navigation/providers/navigation_providers.dart';
import 'package:flicknest_flutter_frontend/styles/flicky_icons_icons.dart';
import 'package:flicknest_flutter_frontend/styles/styles.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SideMenuDrawer extends StatelessWidget {
  const SideMenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context).drawerTheme;

    return Padding(
      padding: HomeAutomationStyles.largePadding,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              FlickyIcons.flickylight,
              size: HomeAutomationStyles.largeIconSize,
              color: theme.surfaceTintColor,
            ),
            HomeAutomationStyles.largeVGap,
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final sideMenuItems = ref.read(sideMenuProvider);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      for(var item in sideMenuItems)
                        TextButton(
                          onPressed: () {},
                          child: Row(
                            children: [
                              Icon(item.icon, color: theme.surfaceTintColor),
                              HomeAutomationStyles.smallHGap,
                              Text(
                                item.label,
                                style: Theme.of(context).textTheme.labelLarge!
                                  .copyWith(
                                  color: theme.surfaceTintColor
                                )
                              )
                            ],
                          ),
                        )
                    ].animate(
                      interval: 200.ms,
                    ).slideX(
                      begin: -0.5, end: 0,
                      duration: 0.5.seconds,
                      curve: Curves.easeInOut
                    ).fadeIn(
                      duration: 0.5.seconds,
                      curve: Curves.easeInOut,
                    ),
                  );
                },
              ),
            ),
            Icon(
              FlickyIcons.flicky,
              size: HomeAutomationStyles.largeIconSize,
              color: theme.surfaceTintColor
            )
          ],
        ),
      )
    );
  }
}