import 'package:flicknest_flutter_frontend/features/navigation/data/models/side_menu_item.dart';
import 'package:flutter/material.dart';

class SideMenuRepository {

  List<SideMenuItem> getSideMenuItems() {
    return [
      SideMenuItem(icon: Icons.info, label: 'About Flick Nest', route: '/about'),
      SideMenuItem(icon: Icons.home, label: 'My Home', route: '/landing'),
      SideMenuItem(icon: Icons.podcasts, label: 'My Network', route: '/network'),
    ];
  }
}