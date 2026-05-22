import 'package:go_router/go_router.dart';
import 'package:thingsboard_app/modules/automation/automation_create_page.dart';
import 'package:thingsboard_app/modules/automation/automation_list_page.dart';
import 'package:thingsboard_app/modules/automation/automation_detail_page.dart';
import 'package:thingsboard_app/modules/automation/automation_provider.dart';

final automationRoutes = [
  GoRoute(
    path: '/automations',
    builder: (_, __) => const AutomationListPage(),
    routes: [
      GoRoute(
        path: 'create',
        builder: (_, state) => AutomationCreatePage(automation: state.extra as Automation?),
      ),
      GoRoute(
        path: ':id',
        builder: (_, state) => AutomationDetailPage(automationId: state.pathParameters['id']!),
      ),
    ],
  ),
];
