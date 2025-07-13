import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkMode { local, online }

final networkModeProvider = StateProvider<NetworkMode>((ref) => NetworkMode.online);

