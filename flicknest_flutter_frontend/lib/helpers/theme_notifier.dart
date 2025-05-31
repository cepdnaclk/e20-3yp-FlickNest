import 'package:flutter/material.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system);
 
  void setTheme(ThemeMode mode) {
    value = mode;
  }
} 