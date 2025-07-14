import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class LocalBrokerService {
  static final LocalBrokerService _instance = LocalBrokerService._internal();
  factory LocalBrokerService() => _instance;
  LocalBrokerService._internal();

  String get _baseUrl => AppConstants.localBrokerUrl;

  Future<dynamic> updateSymbolState(String symbolKey, bool state) async {
    try {
      final url = Uri.parse('$_baseUrl${AppConstants.symbolsEndpoint}/$symbolKey');
      final data = {'state': state ? 'on' : 'off'};
      final bodyJson = json.encode(data);

      // Debug prints
      print('🔵 Request Details:');
      print('URL: $url');
      print('Headers: ${{'Content-Type': 'application/json'}}');
      print('Body: $data');

      // Create and send request with increased timeout
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: bodyJson,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('🔴 Request timed out');
          throw Exception('Request timed out - Check if the server is running and accessible');
        },
      );

      // Debug response
      print('🟢 Response Details:');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }

      throw Exception('Failed to update symbol state. Status: ${response.statusCode}, Body: ${response.body}');
    } catch (e) {
      print('🔴 Error Details:');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');

      if (e.toString().contains('Connection refused')) {
        throw Exception('Cannot connect to local broker - Please ensure the server is running at $_baseUrl');
      }
      throw Exception('Local broker connection failed: $e');
    }
  }

  Future<dynamic> fetchData(String path) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$path'),
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
      final response = await http.get(
        Uri.parse('$_baseUrl${AppConstants.healthEndpoint}'),
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
      final response = await http.get(
        Uri.parse('$_baseUrl${AppConstants.symbolsEndpoint}'),
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
