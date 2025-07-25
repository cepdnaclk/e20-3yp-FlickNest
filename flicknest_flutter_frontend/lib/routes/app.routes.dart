import 'package:flicknest_flutter_frontend/features/auth/presentation/pages/login_page.dart';
import 'package:flicknest_flutter_frontend/features/navigation/presentation/pages/invitations_page.dart';
import 'package:flicknest_flutter_frontend/features/navigation/presentation/pages/invitation_details_page.dart';
import 'package:flicknest_flutter_frontend/features/admin/presentation/pages/device_management.dart';
import 'package:flicknest_flutter_frontend/features/admin/presentation/pages/room_management.dart';
import 'package:flicknest_flutter_frontend/features/admin/presentation/pages/manage_users.page.dart';
import 'package:flicknest_flutter_frontend/Firebase/deviceService.dart';
import 'package:flicknest_flutter_frontend/Firebase/switchModel.dart';
// import 'package:flicknest_flutter_frontend/features/auth/presentation/pages/register_page.dart';
import 'package:go_router/go_router.dart';

import '../features/devices/presentation/pages/devices.page.dart';
import '../features/intro/presentation/pages/loading.page.dart';
import '../features/intro/presentation/pages/splash.page.dart';
import '../features/landing/presentation/pages/home.page.dart';
import '../features/landing/presentation/pages/landing.page.dart';
import '../features/profile/presentation/pages/profile.page.dart';
import '../features/rooms/presentation/pages/rooms.page.dart';
import '../features/settings/presentation/pages/settings.pages.dart';
import '../helpers/utils.dart';
import '../features/about/presentation/pages/about_flick_nest.page.dart';
import '../features/environments/presentation/pages/create_environment.dart';
import '../features/rooms/presentation/pages/room_details_page.dart';

class AppRoutes {
  static final deviceService = DeviceService();
  static final switchService = SwitchService(''); // Provide a default or placeholder environmentId

  static final router = GoRouter(
    routerNeglect: true,
    initialLocation: LoginPage.route,
    navigatorKey: Utils.mainNav,
    routes: [
      GoRoute(
        parentNavigatorKey: Utils.mainNav,
        path: LoginPage.route,
        builder: (context, state) {
          return const LoginPage();
        },
      ),
      // GoRoute(
      //   parentNavigatorKey: Utils.mainNav,
      //   path: RegisterPage.route,
      //   builder: (context, state) {
      //     return const RegisterPage();
      //   },
      // ),
      GoRoute(
        parentNavigatorKey: Utils.mainNav,
        path: SplashPage.route,
        builder: (context, state) {
          return const SplashPage();
        },
      ),
      GoRoute(
        parentNavigatorKey: Utils.mainNav,
        path: InvitationsPage.route,
        builder: (context, state) {
          return const InvitationsPage();
        },
      ),
      GoRoute(
        parentNavigatorKey: Utils.mainNav,
        path: LoadingPage.route,
        builder: (context, state) {
          return LoadingPage();
        },
      ),
      ShellRoute(
        navigatorKey: Utils.tabNav,
        builder: (context, state, child) {
          return LandingPage(child: child);
        },
        routes: [
          GoRoute(
            parentNavigatorKey: Utils.tabNav,
            path: HomePage.route,
            pageBuilder: (context, state) {
              return NoTransitionPage(
                child: HomePage(
                  deviceService: deviceService,
                  switchService: switchService,
                ),
              );
            },
          ),
          GoRoute(
            parentNavigatorKey: Utils.tabNav,
            path: ProfilePage.route,
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: ProfilePage(),
              );
            },
          ),
          GoRoute(
            parentNavigatorKey: Utils.tabNav,
            path: RoomsPage.route,
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: RoomsPage(),
              );
            },
          ),
          GoRoute(
            parentNavigatorKey: Utils.tabNav,
            path: DevicesPage.route,
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: DevicesPage(),
              );
            },
          ),
          GoRoute(
            parentNavigatorKey: Utils.tabNav,
            path: SettingsPage.route,
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: SettingsPage(),
              );
            },
          ),
        ],
      ),
      // Uncomment the following route as needed
      // GoRoute(
      //   parentNavigatorKey: Utils.mainNav,
      //   path: DeviceDetailsPage.route,
      //   builder: (context, state) {
      //     return const DeviceDetailsPage();
      //   },
      // ),
      GoRoute(
        parentNavigatorKey: Utils.mainNav,
        path: AboutFlickNestPage.route,
        builder: (context, state) {
          return const AboutFlickNestPage();
        },
      ),
      GoRoute(
        parentNavigatorKey: Utils.mainNav,
        path: CreateEnvironmentPage.route,
        builder: (context, state) {
          return const CreateEnvironmentPage();
        },
      ),
      GoRoute(
        parentNavigatorKey: Utils.mainNav,
        path: DeviceManagementPage.route,
        builder: (context, state) {
          return const DeviceManagementPage();
        },
      ),
      GoRoute(
        parentNavigatorKey: Utils.mainNav,
        path: RoomManagementPage.route,
        builder: (context, state) {
          return const RoomManagementPage();
        },
      ),
      GoRoute(
        parentNavigatorKey: Utils.mainNav,
        path: ManageUsersPage.route,
        builder: (context, state) {
          return const ManageUsersPage();
        },
      ),
      GoRoute(
        parentNavigatorKey: Utils.mainNav,
        path: InvitationDetailsPage.route,
        builder: (context, state) {
          final invitation = state.extra as Map<String, dynamic>?;
          return InvitationDetailsPage(invitation: invitation);
        },
      ),
      GoRoute(
        parentNavigatorKey: Utils.mainNav,
        path: RoomDetailsPage.route,
        builder: (context, state) {
          final Map<String, dynamic> params = state.extra as Map<String, dynamic>;
          return RoomDetailsPage(
            environmentId: params['environmentId'],
            roomId: params['roomId'],
            roomName: params['roomName'],
          );
        },
      ),
    ],
  );
}

