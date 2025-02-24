
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../helpers/enums.dart';
import '../providers/loading_page_provider.dart';

class LoadingNotificationViewModel extends StateNotifier<AppLoadingStates> {

  final Ref ref;

  LoadingNotificationViewModel(AppLoadingStates state, this.ref) : super(state);

  Future<void> triggerLoading() async{
    state = AppLoadingStates.loading;

    ref.read(loadingMessageProvider.notifier).state = 'Initializing App...';
    //perform waiting logic here
    await  Future.delayed(const Duration(seconds: 1));

    ref.read(loadingMessageProvider.notifier).state = 'Loading device list...';

    //perform waiting logic here
    await Future.delayed(const Duration(seconds: 1));

    ref.read(loadingMessageProvider.notifier).state = 'Loading Outlet Config...';

    //perform waiting logic here
    await Future.delayed(const Duration(seconds: 1));

    ref.read(loadingMessageProvider.notifier).state = 'Done!';

    state =AppLoadingStates.success;


  }
}

