import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class LocalBrokerService {
  static final LocalBrokerService _instance = LocalBrokerService._internal();
  factory LocalBrokerService() => _instance;
  LocalBrokerService._internal();

  String get _baseUrl => AppConstants.localBrokerUrl;

  Future<dynamic> fetchData(String path) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$path'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to fetch data from local broker');
    } catch (e) {
      throw Exception('Local broker connection failed: $e');
    }
  }

  Future<void> saveData(String path, dynamic data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$path'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to save data to local broker');
      }
    } catch (e) {
      throw Exception('Local broker connection failed: $e');
    }
  }
}
