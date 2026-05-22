import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thingsboard_app/services/smart_home_api.dart';

final smartDeviceListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(smartHomeDioProvider);
  final res = await dio.get<List<dynamic>>('/api/devices');
  return (res.data ?? []).cast<Map<String, dynamic>>();
});

class SmartDeviceListPage extends ConsumerWidget {
  const SmartDeviceListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(smartDeviceListProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Devices')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/provision'),
        child: const Icon(Icons.add_rounded),
      ),
      body: devicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
                const SizedBox(height: 16),
                Text('Failed to load devices', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('$e', textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                const SizedBox(height: 24),
                FilledButton.tonalIcon(
                  onPressed: () => ref.invalidate(smartDeviceListProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (devices) => devices.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.devices_rounded, size: 64, color: cs.outline),
                    const SizedBox(height: 16),
                    Text('No devices', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('Tap + to add a new device', style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(smartDeviceListProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: devices.length,
                  itemBuilder: (_, i) {
                    final d = devices[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cs.surfaceContainerHighest,
                          child: Icon(_typeIcon(d['type'] as String?), color: cs.primary),
                        ),
                        title: Text(d['name'] as String? ?? 'Unknown', maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(d['type'] as String? ?? '', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                        trailing: _onlineDot(d['online'] as bool? ?? false, cs),
                        onTap: () => context.push('/deviceControl/${d['id']}'),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _onlineDot(bool online, ColorScheme cs) => Container(
    width: 10, height: 10,
    decoration: BoxDecoration(shape: BoxShape.circle, color: online ? Colors.green : cs.outline),
  );

  IconData _typeIcon(String? type) => switch (type?.toLowerCase()) {
    'light' => Icons.lightbulb_rounded,
    'switch' => Icons.toggle_on_rounded,
    'sensor' => Icons.sensors_rounded,
    'thermostat' => Icons.thermostat_rounded,
    'lock' => Icons.lock_rounded,
    'camera' => Icons.videocam_rounded,
    _ => Icons.devices_rounded,
  };
}
