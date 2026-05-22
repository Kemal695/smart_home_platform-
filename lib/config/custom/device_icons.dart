import 'package:flutter/material.dart';

enum DeviceType {
  light,
  thermostat,
  switch_,
  sensor,
  camera,
  lock,
  fan,
  plug,
  unknown;

  static DeviceType fromString(String value) => switch (value.toLowerCase()) {
        'light'      => DeviceType.light,
        'thermostat' => DeviceType.thermostat,
        'switch'     => DeviceType.switch_,
        'sensor'     => DeviceType.sensor,
        'camera'     => DeviceType.camera,
        'lock'       => DeviceType.lock,
        'fan'        => DeviceType.fan,
        'plug'       => DeviceType.plug,
        _            => DeviceType.unknown,
      };
}

enum DeviceStatus { online, offline, updating, error }

abstract final class DeviceIcons {
  static IconData iconFor(DeviceType type, {bool isOn = true}) {
    return switch (type) {
      DeviceType.light      => isOn ? Icons.lightbulb              : Icons.lightbulb_outline,
      DeviceType.thermostat => isOn ? Icons.thermostat              : Icons.device_thermostat,
      DeviceType.switch_    => isOn ? Icons.toggle_on               : Icons.toggle_off,
      DeviceType.sensor     => isOn ? Icons.sensors                 : Icons.sensors_off,
      DeviceType.camera     => isOn ? Icons.videocam                : Icons.videocam_off,
      DeviceType.lock       => isOn ? Icons.lock_open               : Icons.lock,
      DeviceType.fan        => isOn ? Icons.air                     : Icons.air_outlined,
      DeviceType.plug       => isOn ? Icons.power                   : Icons.power_off,
      DeviceType.unknown    => Icons.device_unknown,
    };
  }

  static IconData statusIconFor(DeviceStatus status) {
    return switch (status) {
      DeviceStatus.online   => Icons.wifi_rounded,
      DeviceStatus.offline  => Icons.wifi_off_rounded,
      DeviceStatus.updating => Icons.sync_rounded,
      DeviceStatus.error    => Icons.error_outline_rounded,
    };
  }

  static Color colorFor(DeviceType type) {
    return switch (type) {
      DeviceType.light      => const Color(0xFFEF9F27),
      DeviceType.thermostat => const Color(0xFFD85A30),
      DeviceType.switch_    => const Color(0xFF534AB7),
      DeviceType.sensor     => const Color(0xFF1D9E75),
      DeviceType.camera     => const Color(0xFF185FA5),
      DeviceType.lock       => const Color(0xFFA32D2D),
      DeviceType.fan        => const Color(0xFF0C447C),
      DeviceType.plug       => const Color(0xFF3B6D11),
      DeviceType.unknown    => const Color(0xFF5F5E5A),
    };
  }

  static Color bgColorFor(DeviceType type) =>
      colorFor(type).withValues(alpha: 0.12);

  static Color statusColorFor(DeviceStatus status) {
    return switch (status) {
      DeviceStatus.online   => const Color(0xFF22C55E),
      DeviceStatus.offline  => const Color(0xFF94A3B8),
      DeviceStatus.updating => const Color(0xFFEF9F27),
      DeviceStatus.error    => const Color(0xFFE24B4A),
    };
  }

  static String labelFor(DeviceType type) {
    return switch (type) {
      DeviceType.light      => 'Light',
      DeviceType.thermostat => 'Thermostat',
      DeviceType.switch_    => 'Switch',
      DeviceType.sensor     => 'Sensor',
      DeviceType.camera     => 'Camera',
      DeviceType.lock       => 'Lock',
      DeviceType.fan        => 'Fan',
      DeviceType.plug       => 'Plug',
      DeviceType.unknown    => 'Device',
    };
  }
}

class DeviceIconWidget extends StatelessWidget {
  const DeviceIconWidget({
    super.key,
    required this.type,
    this.isOn = true,
    this.size = 48,
    this.showStatusDot = false,
    this.status,
  });

  final DeviceType type;
  final bool isOn;
  final double size;
  final bool showStatusDot;
  final DeviceStatus? status;

  @override
  Widget build(BuildContext context) {
    final icon = DeviceIcons.iconFor(type, isOn: isOn);
    final color = DeviceIcons.colorFor(type);

    Widget iconWidget = Icon(icon, color: color, size: size * 0.6);

    if (showStatusDot) {
      final dotColor = status != null
          ? DeviceIcons.statusColorFor(status!)
          : Colors.grey;
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: size * 0.22,
              height: size * 0.22,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: DeviceIcons.bgColorFor(type),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Center(child: iconWidget),
    );
  }
}
