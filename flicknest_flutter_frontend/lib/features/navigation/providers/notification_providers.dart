// notification_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationCountProvider = StateProvider<int>((ref) {
  return 0; // Initial count
});