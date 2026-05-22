import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thingsboard_app/services/smart_home_api.dart';

enum TriggerType { schedule, deviceState, sensorThreshold, sunriseSunset, manual }
enum ActionType { deviceCommand, sceneActivate, notification, webhook }

final class Automation {
  const Automation({
    required this.id,
    required this.name,
    this.description,
    required this.enabled,
    required this.triggerType,
    required this.actionType,
    this.triggerConfig,
    this.actionConfig,
    this.lastRunAt,
    this.runCount = 0,
  });

  factory Automation.fromJson(Map<String, dynamic> json) => Automation(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    enabled: json['enabled'] as bool? ?? true,
    triggerType: _parseTriggerType(json['triggerType'] as String? ?? ''),
    actionType: _parseActionType(json['actionType'] as String? ?? ''),
    triggerConfig: json['triggerConfig'] as String?,
    actionConfig: json['actionConfig'] as String?,
    lastRunAt: json['lastRunAt'] != null ? DateTime.parse(json['lastRunAt'] as String) : null,
    runCount: json['runCount'] as int? ?? 0,
  );

  final String id;
  final String name;
  final String? description;
  final bool enabled;
  final TriggerType triggerType;
  final ActionType actionType;
  final String? triggerConfig;
  final String? actionConfig;
  final DateTime? lastRunAt;
  final int runCount;

  static TriggerType _parseTriggerType(String raw) =>
    switch (raw.toUpperCase()) {
      'SCHEDULE' => TriggerType.schedule,
      'DEVICE_STATE' => TriggerType.deviceState,
      'SENSOR_THRESHOLD' => TriggerType.sensorThreshold,
      'SUNRISE_SUNSET' => TriggerType.sunriseSunset,
      _ => TriggerType.manual,
    };

  static ActionType _parseActionType(String raw) =>
    switch (raw.toUpperCase()) {
      'DEVICE_COMMAND' => ActionType.deviceCommand,
      'SCENE_ACTIVATE' => ActionType.sceneActivate,
      'NOTIFICATION' => ActionType.notification,
      'WEBHOOK' => ActionType.webhook,
      _ => ActionType.deviceCommand,
    };
}

final automationListProvider = StateNotifierProvider<AutomationListNotifier, AsyncValue<List<Automation>>>((ref) {
  final dio = ref.read(smartHomeDioProvider);
  return AutomationListNotifier(dio);
});

class AutomationListNotifier extends StateNotifier<AsyncValue<List<Automation>>> {
  AutomationListNotifier(this._dio) : super(const AsyncLoading()) {
    load();
  }

  final Dio _dio;

  Future<void> load() async {
    state = const AsyncLoading();
    try {
      final res = await _dio.get<List<dynamic>>('/api/automations');
      final list = (res.data ?? []).cast<Map<String, dynamic>>().map(Automation.fromJson).toList();
      state = AsyncData(list);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<String?> toggle(String id) async {
    try {
      await _dio.patch<Map<String, dynamic>>('/api/automations/$id/toggle');
      load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> create({
    required String name,
    String? description,
    TriggerType triggerType = TriggerType.manual,
    ActionType actionType = ActionType.deviceCommand,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>('/api/automations', data: {
        'name': name,
        if (description != null) 'description': description,
        'triggerType': _toServerEnum(triggerType.name),
        'actionType': _toServerEnum(actionType.name),
      });
      load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  static String _toServerEnum(String camelCase) =>
    camelCase.replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m.group(0)}').toUpperCase();

  Future<String?> update(String id, {
    String? name,
    String? description,
    TriggerType? triggerType,
    ActionType? actionType,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (triggerType != null) data['triggerType'] = _toServerEnum(triggerType.name);
      if (actionType != null) data['actionType'] = _toServerEnum(actionType.name);
      await _dio.put<Map<String, dynamic>>('/api/automations/$id', data: data);
      load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> delete(String id) async {
    try {
      await _dio.delete<void>('/api/automations/$id');
      load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
