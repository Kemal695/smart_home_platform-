import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:thingsboard_app/modules/device/device_control_page.dart';

class DeviceControlRoutes {
  static const deviceControl = '/deviceControl';
}

final deviceControlRoutes = [
  GoRoute(
    path: '${DeviceControlRoutes.deviceControl}/:id',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return DeviceControlPage(key: ValueKey(state.uri), deviceId: id);
    },
  ),
];
