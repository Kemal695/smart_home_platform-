import 'package:go_router/go_router.dart';
import 'package:thingsboard_app/modules/provisioning/lottie_provision_widget.dart';
import 'package:thingsboard_app/modules/provisioning/provisioning_screens.dart';

final provisioningRoutes = [
  GoRoute(
    path: '/provision',
    builder: (_, state) {
      final extra = state.extra as Map<String, dynamic>?;
      return ProvisioningScreen(
        homeId: extra?['homeId'] as String?,
        roomId: extra?['roomId'] as String?,
      );
    },
    routes: [
      GoRoute(
        path: 'wifi',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return WifiCredentialsScreen(
            homeId: extra?['homeId'] as String?,
            roomId: extra?['roomId'] as String?,
            deviceType: extra?['deviceType'] as String?,
          );
        },
      ),
      GoRoute(
        path: 'progress',
        builder: (_, state) => const ProvisioningProgressScreen(),
      ),
      GoRoute(
        path: 'lottie',
        builder: (_, state) => const LottieProvisioningScreen(),
      ),
    ],
  ),
];
