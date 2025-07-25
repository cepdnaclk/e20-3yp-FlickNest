import '../../../../helpers/enums.dart';
import '../../../devices/presentation/pages/devices.page.dart';
import '../../../landing/presentation/pages/home.page.dart';
import '../../../rooms/presentation/pages/rooms.page.dart';
import '../../../settings/presentation/pages/settings.pages.dart';
import '../models/bottom_bar_nav_item.dart';

class BottomNavBarRepository {
  List<BottomBarNavItemModel> getBottomBarNavItems() {
    return const [
      BottomBarNavItemModel(
        iconOption: FlickyAnimatedIconOptions.barhome,
        route: HomePage.route,
        label: 'Home',
        isSelected: true
      ),
      BottomBarNavItemModel(
        iconOption: FlickyAnimatedIconOptions.barrooms,
        route: RoomsPage.route,
        label: 'Rooms'
      ),
      BottomBarNavItemModel(
        iconOption: FlickyAnimatedIconOptions.bardevices,
        route: DevicesPage.route,
        label: 'Devices'
      ),
      BottomBarNavItemModel(
        iconOption: FlickyAnimatedIconOptions.barsettings,
        route: SettingsPage.route,
        label: 'Settings'
      ),
    ];
  }
}