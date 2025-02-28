import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../data/models/bottom_bar_nav_item.dart';
import '../data/models/side_menu_item.dart';
import '../data/repositories/bottomnavbar.repository.dart';
import '../data/repositories/side_menu.repository.dart';
import '../presentation/viewmodels/bottombar.viewmodel.dart';


final bottomBarVMProvider = StateNotifierProvider<BottomBarViewModel, List<BottomBarNavItemModel>>((ref) {
  final navItems = ref.read(bottomBarRepositoryProvider).getBottomBarNavItems();
  return BottomBarViewModel(navItems, ref);
});

final bottomBarRepositoryProvider = Provider((ref) {
  return BottomNavBarRepository();
});

final sideMenuRepositoryProvider = Provider((ref) {
  return SideMenuRepository();
});

final sideMenuProvider = Provider<List<SideMenuItem>>((ref) {
  return ref.read(sideMenuRepositoryProvider).getSideMenuItems();
});

