import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../helpers/enums.dart';
import '../viewmodals/loading_notification.viewmodel.dart';

final loadingMessageProvider = StateProvider<String>((ref) => '');

final loadingNotificationVMProvider = StateNotifierProvider<LoadingNotificationViewModel, AppLoadingStates>((ref) {
  return LoadingNotificationViewModel(AppLoadingStates.none, ref);
});