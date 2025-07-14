import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../constants.dart';

class LocalBrokerConfig {
  static Future<String> getBrokerIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('local_broker_ip') ?? _defaultIp();
  }

  static Future<String> getBrokerPort() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('local_broker_port') ?? _defaultPort();
  }

  static Future<String> getBrokerUrl() async {
    final ip = await getBrokerIp();
    final port = await getBrokerPort();
    final url = 'http://$ip:$port';
    print('🔵 Local Broker URL: $url');  // Debug log
    return url;
  }

  static String _defaultIp() {
    if (Platform.isAndroid) {
      // Use 10.0.2.2 for Android emulator to access host machine's localhost
      return '10.0.2.2';
    }
    return 'localhost';
  }

  static String _defaultPort() {
    return '5000';
  }
}

