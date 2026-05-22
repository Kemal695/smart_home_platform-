import 'package:go_router/go_router.dart';
import 'package:thingsboard_app/modules/device/smart_device_list_page.dart';

final smartDeviceRoutes = [
  GoRoute(
    path: '/smart-devices',
    builder: (_, __) => const SmartDeviceListPage(),
  ),
];
