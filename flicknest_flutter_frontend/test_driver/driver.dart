import 'package:flutter_driver/flutter_driver.dart';

class FlutterDriverConfig {
  static Future<FlutterDriver> configureDriver() async {
    return await FlutterDriver.connect();
  }
} 