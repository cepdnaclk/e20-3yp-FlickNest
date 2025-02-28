import 'package:flicknest_flutter_frontend/features/landing/data/models/home_tile_option.dart';
import 'package:flicknest_flutter_frontend/helpers/enums.dart';
import 'package:flicknest_flutter_frontend/styles/flicky_icons_icons.dart';
import 'package:flutter/material.dart';

class HomeTileOptionsRepository {

  List<HomeTileOption> getHomeTileOptions() {
    return [
      HomeTileOption(
          icon: Icons.add_circle_outline,
          label: 'Add New Device',
          option: HomeTileOptions.addDevice
      ),
      HomeTileOption(
          icon: FlickyIcons.oven,
          label: 'Manage Devices',
          option: HomeTileOptions.manageDevices
      )
    ];
  }

}