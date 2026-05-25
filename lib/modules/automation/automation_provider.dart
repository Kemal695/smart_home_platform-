import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thingsboard_app/services/gateway_auth_service.dart';
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
  return AutomationListNotifier(dio, ref);
});

class AutomationListNotifier extends StateNotifier<AsyncValue<List<Automation>>> {
  AutomationListNotifier(this._dio, this._ref) : super(const AsyncLoading()) {
    _ref.listen(gatewayTokenProvider, (prev, next) {
      if (prev == null && next != null) load();
    });
    load();
  }

  final Dio _dio;
  final Ref _ref;

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
      final rule = _buildDefaultRule(triggerType, actionType);
      await _dio.post<Map<String, dynamic>>('/api/automations', data: {
        'name': name,
        if (description != null) 'description': description,
        'triggerType': _toServerEnum(triggerType.name),
        'actionType': _toServerEnum(actionType.name),
        'enabled': true,
        'rules': [rule],
      });
      load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Map<String, dynamic> _buildDefaultRule(TriggerType triggerType, ActionType actionType) {
    return {
      'conditionJson': _buildDefaultCondition(triggerType),
      'actionJson': _buildDefaultAction(actionType),
      'sortOrder': 0,
    };
  }

  Map<String, dynamic> _buildDefaultCondition(TriggerType type) => switch (type) {
    TriggerType.schedule         => {'cron': '0 0 * * *', 'timezone': 'UTC'},
    TriggerType.deviceState      => {'deviceId': '', 'method': 'setPower', 'expectedValue': true},
    TriggerType.sensorThreshold  => {'metric': 'temperature', 'op': 'gt', 'value': 30},
    TriggerType.sunriseSunset    => {'event': 'sunset', 'offset': 0},
    TriggerType.manual           => {'manual': true},
  };

  Map<String, dynamic> _buildDefaultAction(ActionType type) => switch (type) {
    ActionType.deviceCommand  => {'deviceId': '', 'method': 'setPower', 'params': {'state': true}},
    ActionType.sceneActivate  => {'sceneId': ''},
    ActionType.notification   => {'title': 'Automation triggered', 'body': ''},
    ActionType.webhook        => {'url': '', 'method': 'POST'},
  };

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
