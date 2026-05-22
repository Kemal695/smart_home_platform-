import 'package:go_router/go_router.dart';
import 'package:thingsboard_app/modules/scenes/scene_create_page.dart';
import 'package:thingsboard_app/modules/scenes/scene_list_page.dart';
import 'package:thingsboard_app/modules/scenes/scene_detail_page.dart';
import 'package:thingsboard_app/modules/scenes/scene_provider.dart';

final sceneRoutes = [
  GoRoute(
    path: '/scenes',
    builder: (_, __) => const SceneListPage(),
    routes: [
      GoRoute(
        path: 'create',
        builder: (_, state) => SceneCreatePage(scene: state.extra as Scene?),
      ),
      GoRoute(
        path: ':id',
        builder: (_, state) => SceneDetailPage(sceneId: state.pathParameters['id']!),
      ),
    ],
  ),
];
