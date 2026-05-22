import 'package:go_router/go_router.dart';
import 'package:thingsboard_app/modules/device_icon/device_icon_page.dart';

final deviceIconRoutes = [
  GoRoute(
    path: '/device-icons',
    builder: (_, state) => const DeviceIconDemoPage(),
  ),
];