import 'package:flutter/material.dart';
import 'package:thingsboard_app/config/custom/device_icons.dart';

class DeviceIconDemoPage extends StatelessWidget {
  const DeviceIconDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Icons')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('All Device Types',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...DeviceType.values.map(
            (type) => Card(
              child: ListTile(
                leading: DeviceIconWidget(type: type, size: 40),
                title: Text(DeviceIcons.labelFor(type)),
                subtitle: Text(type.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DeviceIconWidget(type: type, size: 32),
                    const SizedBox(width: 8),
                    DeviceIconWidget(type: type, isOn: false, size: 32),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Status Indicators',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: DeviceStatus.values.map((status) {
                final iconData = DeviceIcons.statusIconFor(status);
                Color color;
                switch (status) {
                  case DeviceStatus.online:
                    color = Colors.green;
                  case DeviceStatus.offline:
                    color = Colors.grey;
                  case DeviceStatus.updating:
                    color = Colors.orange;
                  case DeviceStatus.error:
                    color = Colors.red;
                }
                return ListTile(
                  leading: Icon(iconData, color: color),
                  title: Text(status.name),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
