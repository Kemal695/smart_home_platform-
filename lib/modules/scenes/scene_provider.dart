import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thingsboard_app/services/smart_home_api.dart';

final class SceneActionItem {
  const SceneActionItem({
    required this.id,
    required this.deviceId,
    required this.commandJson,
    this.delayMs = 0,
    this.sortOrder = 0,
  });

  factory SceneActionItem.fromJson(Map<String, dynamic> json) => SceneActionItem(
    id: json['id'] as String,
    deviceId: json['deviceId'] as String,
    commandJson: json['commandJson'] as String,
    delayMs: json['delayMs'] as int? ?? 0,
    sortOrder: json['sortOrder'] as int? ?? 0,
  );

  final String id;
  final String deviceId;
  final String commandJson;
  final int delayMs;
  final int sortOrder;
}

final class Scene {
  const Scene({
    required this.id,
    required this.name,
    this.iconKey,
    this.favorite = false,
    this.actions = const [],
  });

  factory Scene.fromJson(Map<String, dynamic> json) => Scene(
    id: json['id'] as String,
    name: json['name'] as String,
    iconKey: json['iconKey'] as String?,
    favorite: json['favorite'] as bool? ?? false,
    actions: (json['actions'] as List<dynamic>?)
        ?.map((a) => SceneActionItem.fromJson(a as Map<String, dynamic>))
        .toList() ?? [],
  );

  final String id;
  final String name;
  final String? iconKey;
  final bool favorite;
  final List<SceneActionItem> actions;
}

final sceneListProvider = StateNotifierProvider<SceneListNotifier, AsyncValue<List<Scene>>>((ref) {
  final dio = ref.read(smartHomeDioProvider);
  return SceneListNotifier(dio);
});

class SceneListNotifier extends StateNotifier<AsyncValue<List<Scene>>> {
  SceneListNotifier(this._dio) : super(const AsyncLoading()) {
    load();
  }

  final Dio _dio;

  Future<void> load() async {
    state = const AsyncLoading();
    try {
      final res = await _dio.get<List<dynamic>>('/api/scenes');
      final list = (res.data ?? []).cast<Map<String, dynamic>>().map(Scene.fromJson).toList();
      state = AsyncData(list);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<String?> toggleFavorite(String id) async {
    try {
      await _dio.patch<Map<String, dynamic>>('/api/scenes/$id/favorite');
      load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> activate(String id) async {
    try {
      await _dio.post<Map<String, dynamic>>('/api/scenes/$id/activate');
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> create({required String name, String? iconKey}) async {
    try {
      await _dio.post<Map<String, dynamic>>('/api/scenes', data: {
        'name': name,
        if (iconKey != null) 'iconKey': iconKey,
      });
      load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> update(String id, {required String name, String? iconKey}) async {
    try {
      await _dio.put<Map<String, dynamic>>('/api/scenes/$id', data: {
        'name': name,
        if (iconKey != null) 'iconKey': iconKey,
      });
      load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> delete(String id) async {
    try {
      await _dio.delete<void>('/api/scenes/$id');
      load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
