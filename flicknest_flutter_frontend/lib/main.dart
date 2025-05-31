import 'package:flicknest_flutter_frontend/features/auth/presentation/pages/login_page.dart';
import 'package:flicknest_flutter_frontend/routes/app.routes.dart';
import 'package:flicknest_flutter_frontend/styles/flicky_icons_icons.dart';
import 'package:flicknest_flutter_frontend/styles/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'helpers/theme_notifier.dart';
import 'package:go_router/go_router.dart';

final themeNotifier = ThemeNotifier();
final environmentProvider = StateProvider<String>((ref) => 'env_12345'); // default env id

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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
    return MaterialApp.router(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: mode,
      debugShowCheckedModeBanner: false,
      routeInformationProvider : AppRoutes.router.routeInformationProvider,
      routeInformationParser: AppRoutes.router.routeInformationParser,
      routerDelegate: AppRoutes.router.routerDelegate,
        );
      },
    );
  }
}