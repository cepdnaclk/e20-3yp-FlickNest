import 'package:flicknest_flutter_frontend/helpers/enums.dart';
import 'package:flutter/material.dart';

class HomeTileOption {
  final IconData icon;
  final String label;
  final HomeTileOptions option;

  const HomeTileOption({
    required this.icon,
    required this.label,
    required this.option
  });
}