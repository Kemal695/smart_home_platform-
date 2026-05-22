import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thingsboard_app/modules/provisioning/provisioning_domain.dart';
import 'package:thingsboard_app/services/smart_home_api.dart';

final provisioningProvider = StateNotifierProvider.autoDispose<ProvisioningNotifier, ProvisioningState>((ref) {
  final dio = ref.read(smartHomeDioProvider);
  return ProvisioningNotifier(dio, ref);
});

class ProvisioningNotifier extends StateNotifier<ProvisioningState> {
  ProvisioningNotifier(this._dio, this._ref) : super(const ProvisioningState());

  final Dio _dio;
  final Ref _ref;

  void startScan() => state = state.copyWith(step: ProvisioningStep.scanning);

  void deviceFound(String name, String id) {
    state = state.copyWith(
      step: ProvisioningStep.deviceFound,
      scannedDeviceName: name,
      scannedDeviceId: id,
    );
  }

  void startConnecting() => state = state.copyWith(step: ProvisioningStep.connecting);

  void connected() => state = state.copyWith(step: ProvisioningStep.connected);

  Future<String?> sendCredentials(WifiCredentials wifi, String? homeId, {String? roomId}) async {
    state = state.copyWith(step: ProvisioningStep.sendingCredentials);
    try {
      final res = await _dio.post<Map<String, dynamic>>('/api/provision/init', data: {
        'homeId': homeId,
        if (roomId != null) 'roomId': roomId,
        'ssid': wifi.ssid,
        'password': wifi.password,
      });
      final token = res.data?['token'] as String?;
      if (token == null) throw Exception('No provisioning token received');
      return token;
    } catch (e) {
      state = state.withError('Failed to get provisioning token: $e');
      return null;
    }
  }

  void waitingForWifi() => state = state.copyWith(step: ProvisioningStep.waitingForWifi);

  void wifiConnected() => state = state.copyWith(step: ProvisioningStep.wifiConnected);

  void registeringDevice() => state = state.copyWith(step: ProvisioningStep.registeringDevice);

  void complete(String deviceId) {
    state = state.copyWith(step: ProvisioningStep.complete, provisionedDeviceId: deviceId);
  }

  void fail(String message) => state = state.copyWith(step: ProvisioningStep.failed, errorMessage: message);

  void reset() {
    state = const ProvisioningState();
  }
}
