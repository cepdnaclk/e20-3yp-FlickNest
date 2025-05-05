import 'package:flicknest_flutter_frontend/routes/app.routes.dart';
import 'package:flicknest_flutter_frontend/styles/flicky_icons_icons.dart';
import 'package:flicknest_flutter_frontend/styles/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ProviderScope(
      child: HomeAutomationApp(),
    ),
  );
}

class HomeAutomationApp extends StatelessWidget {
  const HomeAutomationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme:HomeAutomationTheme.light,
      darkTheme: HomeAutomationTheme.dark,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      routeInformationProvider : AppRoutes.router.routeInformationProvider,
      routeInformationParser: AppRoutes.router.routeInformationParser,
      routerDelegate: AppRoutes.router.routerDelegate,
    );
  }
}
