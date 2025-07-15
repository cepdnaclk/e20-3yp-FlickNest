import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsLocalBrokerSection extends StatefulWidget {
  final VoidCallback? onSave;

  const SettingsLocalBrokerSection({Key? key, this.onSave}) : super(key: key);

  @override
  State<SettingsLocalBrokerSection> createState() => _SettingsLocalBrokerSectionState();
}

class _SettingsLocalBrokerSectionState extends State<SettingsLocalBrokerSection> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  String? _ipError;
  String? _portError;

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
    });
  }

  Future<void> _saveBrokerSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_broker_ip', _ipController.text);
    await prefs.setString('local_broker_port', _portController.text);
    if (widget.onSave != null) widget.onSave!();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Local broker settings saved!')),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _ipController,
          decoration: InputDecoration(
            labelText: 'Broker IP',
            hintText: '192.168.1.100',
            prefixIcon: Icon(Icons.lan, color: theme.colorScheme.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _portController,
          decoration: InputDecoration(
            labelText: 'Broker Port',
            hintText: '1883',
            prefixIcon: Icon(Icons.numbers, color: theme.colorScheme.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save Settings'),
            onPressed: () {
              _saveBrokerSettings();
            },
          ),
        ),
      ],
    );
  }
}

