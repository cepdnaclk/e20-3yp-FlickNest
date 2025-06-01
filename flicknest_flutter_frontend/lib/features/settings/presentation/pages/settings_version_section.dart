import 'package:flutter/material.dart';

class SettingsVersionSection extends StatelessWidget {
  const SettingsVersionSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Text(
          'Version 1.0.0',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ),
    );
  }
} 