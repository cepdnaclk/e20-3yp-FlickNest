import 'package:flutter/cupertino.dart';

class SettingsPage extends StatelessWidget{
  static const String route = '/settings';
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context){
    return const Center(
      child: Text('Settings'),

    );

  }
}