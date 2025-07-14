import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/navigation_providers.dart';

class HomeAutomationBottomBar extends ConsumerWidget {
  const HomeAutomationBottomBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomBarVMProvider).indexWhere((item) => item.isSelected);

    return NavigationBar(
      onDestinationSelected: (int index) {
        final routes = ['/home', '/rooms', '/devices', '/settings'];
        context.go(routes[index]);
        
        // Update the selected item in the provider
        ref.read(bottomBarVMProvider.notifier).selectedIndex(index);
      },
      selectedIndex: currentIndex != -1 ? currentIndex : 0,
      destinations: const <Widget>[
        NavigationDestination(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.room),
          label: 'Rooms',
        ),
        NavigationDestination(
          icon: Icon(Icons.devices),
          label: 'Devices',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}