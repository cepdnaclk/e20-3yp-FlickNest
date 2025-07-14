import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsLocalBrokerSection extends StatefulWidget {
  const SettingsLocalBrokerSection({Key? key}) : super(key: key);

  @override
  State<SettingsLocalBrokerSection> createState() => _SettingsLocalBrokerSectionState();
}

class _SettingsLocalBrokerSectionState extends State<SettingsLocalBrokerSection> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  final _wifiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBrokerSettings();
  }

  Future<void> _loadBrokerSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ipController.text = prefs.getString('local_broker_ip') ?? '10.0.2.2';
      _portController.text = prefs.getString('local_broker_port') ?? '5000';
      _wifiController.text = prefs.getString('local_broker_wifi') ?? '';
    });
  }

  Future<void> _saveBrokerSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_broker_ip', _ipController.text);
    await prefs.setString('local_broker_port', _portController.text);
    await prefs.setString('local_broker_wifi', _wifiController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Local broker settings saved!')),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _wifiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Local Broker Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(labelText: 'Broker IP'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(labelText: 'Broker Port'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _wifiController,
              decoration: const InputDecoration(labelText: 'WiFi SSID'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveBrokerSettings,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}


