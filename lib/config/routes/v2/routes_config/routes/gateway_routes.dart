import 'package:go_router/go_router.dart';
import 'package:thingsboard_app/modules/auth/gateway_register_page.dart';

final gatewayRoutes = [
  GoRoute(
    path: '/gateway/register',
    builder: (_, __) => const GatewayRegisterPage(),
  ),
];
