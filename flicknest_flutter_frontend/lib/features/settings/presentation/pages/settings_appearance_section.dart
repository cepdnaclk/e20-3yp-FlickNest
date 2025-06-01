import 'package:flutter/material.dart';
import '../../../../helpers/theme_notifier.dart';

class SettingsAppearanceSection extends StatelessWidget {
  final ValueNotifier<ThemeMode> themeNotifier;
  const SettingsAppearanceSection({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 0, 8),
          child: Text('Appearance', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[700], fontWeight: FontWeight.bold)),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: const Icon(Icons.palette_outlined, color: Colors.orange),
            title: const Text('Appearance'),
            subtitle: Text(
              themeNotifier.value == ThemeMode.light
                  ? 'Light'
                  : themeNotifier.value == ThemeMode.dark
                      ? 'Dark'
                      : 'System',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final selected = await showDialog<ThemeMode>(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text('Choose Theme'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  children: [
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.system,
                      groupValue: themeNotifier.value,
                      title: const Text('System Default'),
                      onChanged: (mode) => Navigator.pop(context, mode),
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.light,
                      groupValue: themeNotifier.value,
                      title: const Text('Light'),
                      onChanged: (mode) => Navigator.pop(context, mode),
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.dark,
                      groupValue: themeNotifier.value,
                      title: const Text('Dark'),
                      onChanged: (mode) => Navigator.pop(context, mode),
                    ),
                  ],
                ),
              );
              if (selected != null) {
                themeNotifier.value = selected;
              }
            },
          ),
        ),
      ],
    );
  }
} 