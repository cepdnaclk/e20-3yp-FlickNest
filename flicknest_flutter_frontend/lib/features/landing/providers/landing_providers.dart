import 'package:flicknest_flutter_frontend/features/landing/repositories/home_tile_options.repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeTileOptionsRepositoryProvider = Provider((ref) {
  return HomeTileOptionsRepository;
});