import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../helpers/local_broker_config.dart';

class LocalBrokerService {
  static LocalBrokerService? _instance;
  static LocalBrokerService get instance {
    _instance ??= LocalBrokerService._internal();
    return _instance!;
  }

  LocalBrokerService._internal();

  Future<dynamic> updateSymbolState(String symbolKey, bool state) async {
    try {
      final brokerUrl = await LocalBrokerConfig.getBrokerUrl();
      // Use simple endpoint structure
      final url = Uri.parse('$brokerUrl/symbols/$symbolKey');
      final data = {'state': state}; // Send boolean state

      print('🔵 Sending to Local Broker:');
      print('URL: $url');
      print('Payload: $data');

      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('🔴 Local broker timeout');
          throw Exception('Connection to local broker timed out');
        },
      );

      print('🟢 Local Broker Response:');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to update state: ${response.statusCode}');
      }

      return json.decode(response.body);
    } catch (e) {
      print('🔴 Local Broker Error: $e');
      rethrow;
    }
  }

  Future<dynamic> fetchData(String path) async {
    try {
      final brokerUrl = await LocalBrokerConfig.getBrokerUrl();
      final response = await http.get(
        Uri.parse('$brokerUrl/$path'),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Request timed out'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to fetch data. Status: ${response.statusCode}');
    } catch (e) {
      print('Error fetching data: $e');
      throw Exception('Local broker connection failed: $e');
    }
  }

  Future<bool> checkConnection() async {
    try {
      final brokerUrl = await LocalBrokerConfig.getBrokerUrl();
      final response = await http.get(
        Uri.parse('$brokerUrl${AppConstants.healthEndpoint}'),
      ).timeout(
        const Duration(seconds: 3),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Connection check failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getAllSymbols() async {
    try {
      final brokerUrl = await LocalBrokerConfig.getBrokerUrl();
      final response = await http.get(
        Uri.parse('$brokerUrl${AppConstants.symbolsEndpoint}'),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Request timed out'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to fetch symbols. Status: ${response.statusCode}');
    } catch (e) {
      print('Error fetching symbols: $e');
      throw Exception('Local broker connection failed: $e');
    }
  }
}
