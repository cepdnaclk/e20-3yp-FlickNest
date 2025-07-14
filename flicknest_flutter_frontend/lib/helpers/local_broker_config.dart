import 'package:shared_preferences/shared_preferences.dart';
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
    return 'http://$ip:$port';
  }

  static String _defaultIp() {
    final url = AppConstants.localBrokerUrl;
    final uri = Uri.tryParse(url);
    return uri?.host ?? '10.0.2.2';
  }

  static String _defaultPort() {
    final url = AppConstants.localBrokerUrl;
    final uri = Uri.tryParse(url);
    return uri?.port.toString() ?? '5000';
  }
}

