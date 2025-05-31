import 'package:flutter/material.dart';

class AboutFlickNestPage extends StatelessWidget {
  static const String route = '/about';
  const AboutFlickNestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Flick Nest'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Flick Nest',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Flick Nest is an app that automates smart home systems. '
              'Easily control, monitor, and optimize your home devices from anywhere. '
              'Enjoy seamless integration, energy savings, and a smarter lifestyle with Flick Nest.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
            Text(
              'Features:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Control lights, devices, and rooms remotely.'),
            Text('• Get notifications and automate routines.'),
            Text('• Secure, fast, and easy to use.'),
            SizedBox(height: 24),
            Text('Version 1.0.0'),
          ],
        ),
      ),
    );
  }
} 