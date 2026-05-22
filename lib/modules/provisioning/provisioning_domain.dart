import 'package:equatable/equatable.dart';

enum ProvisioningStep {
  idle, scanning, deviceFound, connecting, connected,
  sendingCredentials, waitingForWifi, wifiConnected,
  registeringDevice, complete, failed,
}

extension ProvisioningStepX on ProvisioningStep {
  String get label => switch (this) {
    ProvisioningStep.idle => '',
    ProvisioningStep.scanning => 'Scanning for device...',
    ProvisioningStep.deviceFound => 'Device found',
    ProvisioningStep.connecting => 'Connecting...',
    ProvisioningStep.connected => 'Connected',
    ProvisioningStep.sendingCredentials => 'Sending WiFi credentials...',
    ProvisioningStep.waitingForWifi => 'Waiting for WiFi connection...',
    ProvisioningStep.wifiConnected => 'Connected to WiFi',
    ProvisioningStep.registeringDevice => 'Registering with server...',
    ProvisioningStep.complete => 'Device added!',
    ProvisioningStep.failed => 'Setup failed',
  };

  double get progress => switch (this) {
    ProvisioningStep.idle => 0.0,
    ProvisioningStep.scanning => 0.1,
    ProvisioningStep.deviceFound => 0.2,
    ProvisioningStep.connecting => 0.3,
    ProvisioningStep.connected => 0.4,
    ProvisioningStep.sendingCredentials => 0.5,
    ProvisioningStep.waitingForWifi => 0.7,
    ProvisioningStep.wifiConnected => 0.8,
    ProvisioningStep.registeringDevice => 0.9,
    ProvisioningStep.complete => 1.0,
    ProvisioningStep.failed => 0.0,
  };

  bool get isTerminal => this == ProvisioningStep.complete || this == ProvisioningStep.failed;
  bool get isInProgress => !isTerminal && this != ProvisioningStep.idle;
}

class WifiCredentials extends Equatable {
  const WifiCredentials({required this.ssid, this.password = ''});
  final String ssid;
  final String password;
  bool get isValid => ssid.isNotEmpty;
  @override List<Object?> get props => [ssid, password];
}

class ProvisioningState extends Equatable {
  const ProvisioningState({
    this.step = ProvisioningStep.idle,
    this.scannedDeviceName,
    this.scannedDeviceId,
    this.errorMessage,
    this.provisionedDeviceId,
  });

  final ProvisioningStep step;
  final String? scannedDeviceName;
  final String? scannedDeviceId;
  final String? errorMessage;
  final String? provisionedDeviceId;

  ProvisioningState copyWith({
    ProvisioningStep? step,
    String? scannedDeviceName,
    String? scannedDeviceId,
    String? errorMessage,
    String? provisionedDeviceId,
    bool clearError = false,
  }) => ProvisioningState(
    step: step ?? this.step,
    scannedDeviceName: scannedDeviceName ?? this.scannedDeviceName,
    scannedDeviceId: scannedDeviceId ?? this.scannedDeviceId,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    provisionedDeviceId: provisionedDeviceId ?? this.provisionedDeviceId,
  );

  ProvisioningState withError(String message) => copyWith(step: ProvisioningStep.failed, errorMessage: message);
  bool get hasError => errorMessage != null;
  bool get isComplete => step == ProvisioningStep.complete;
  bool get isFailed => step == ProvisioningStep.failed;
  bool get isScanning => step == ProvisioningStep.scanning;

  @override List<Object?> get props => [step, scannedDeviceName, scannedDeviceId, errorMessage, provisionedDeviceId];
}
