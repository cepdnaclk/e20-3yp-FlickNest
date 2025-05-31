import 'package:flicknest_flutter_frontend/styles/flicky_icons_icons.dart';
import 'package:flicknest_flutter_frontend/styles/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/navigation_providers.dart';

class SideMenuDrawer extends StatelessWidget {
  const SideMenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).drawerTheme;
    final colorScheme = Theme.of(context).colorScheme;

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
                  final currentRoute = ModalRoute.of(context)?.settings.name;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < sideMenuItems.length; i++)
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: AnimatedContainer(
                            duration: 300.ms,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius:
                              BorderRadius.circular(HomeAutomationStyles.smallRadius),
                              color: currentRoute == sideMenuItems[i].route
                                  ? theme.backgroundColor?.withOpacity(0.2) ?? colorScheme.primary.withOpacity(0.15)
                                  : Colors.transparent,
                            ),
                            child: InkWell(
                              onTap: () {
                                if (currentRoute != sideMenuItems[i].route) {
                                  Navigator.pushNamed(context, sideMenuItems[i].route);
                                }
                              },
                              borderRadius:
                              BorderRadius.circular(HomeAutomationStyles.smallRadius),
                              hoverColor: colorScheme.primary.withOpacity(0.1),
                              splashColor: colorScheme.primary.withOpacity(0.2),
                              highlightColor: colorScheme.primary.withOpacity(0.05),
                              child: Padding(
                                padding: HomeAutomationStyles.smallPadding,
                                child: Row(
                                  children: [
                                    Icon(
                                      sideMenuItems[i].icon,
                                      color: currentRoute == sideMenuItems[i].route
                                          ? colorScheme.primary
                                          : theme.surfaceTintColor,
                                    ),
                                    HomeAutomationStyles.smallHGap,
                                    Text(
                                      sideMenuItems[i].label,
                                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                                            color: currentRoute == sideMenuItems[i].route
                                                ? colorScheme.primary
                                                : theme.surfaceTintColor,
                                          ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ).animate(
                          delay: (200 * i).ms,
                        ).slideX(
                          begin: -0.5,
                          end: 0,
                          duration: 500.ms,
                          curve: Curves.easeInOut,
                        ).fadeIn(
                          duration: 500.ms,
                          curve: Curves.easeInOut,
                        ),
                    ],
                  );
                },
              ),
            ),
            Icon(
              FlickyIcons.flicky,
              size: HomeAutomationStyles.largeIconSize,
              color: theme.surfaceTintColor,
            ),
          ],
        ),
      ),
    );
  }
}