import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingsboard_app/locator.dart';
import 'package:thingsboard_app/thingsboard_client.dart';
import 'package:thingsboard_app/utils/services/tb_client_service/i_tb_client_service.dart';

class DeviceControlPage extends ConsumerStatefulWidget {
  const DeviceControlPage({super.key, required this.deviceId});
  final String deviceId;

  @override
  ConsumerState<DeviceControlPage> createState() => _DeviceControlPageState();
}

class _DeviceControlPageState extends ConsumerState<DeviceControlPage> {
  final tbClient = getIt<ITbClientService>().client;
  DeviceInfo? _device;
  bool _loading = true;
  String? _error;
  String? _rpcResult;

  @override
  void initState() {
    super.initState();
    _loadDevice();
  }

  Future<void> _loadDevice() async {
    try {
      final device = await tbClient.getDeviceService().getDeviceInfo(widget.deviceId);
      if (mounted) setState(() { _device = device; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _sendRpc(String method, {Map<String, dynamic>? params}) async {
    setState(() => _rpcResult = 'Sending $method...');
    try {
      final response = await tbClient.post<dynamic>(
        '/api/rpc/twoway/${widget.deviceId}',
        data: jsonEncode({
          'method': method,
          'params': params ?? {},
        }),
      );
      if (mounted) setState(() => _rpcResult = 'Result: ${response.data}');
    } catch (e) {
      if (mounted) setState(() => _rpcResult = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_device?.name ?? 'Device Control')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Device: ${_device!.name}', style: Theme.of(context).textTheme.titleMedium),
        Text('Type: ${_device!.type}', style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 24),
        Text('RPC Commands', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        ..._buildRpcButtons(),
        if (_rpcResult != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_rpcResult!, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildRpcButtons() {
    return [
      _rpcButton('Toggle', Icons.power_settings_new, () => _sendRpc('toggle')),
      _rpcButton('Set Brightness', Icons.lightbulb, () => _showSliderDialog('setBrightness', 'brightness', 0, 100)),
      _rpcButton('Set Temperature', Icons.thermostat, () => _showSliderDialog('setTemperature', 'temperature', 10, 40)),
      _rpcButton('Get Status', Icons.refresh, () => _sendRpc('getStatus')),
    ];
  }

  Widget _rpcButton(String label, IconData icon, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Future<void> _showSliderDialog(String method, String param, double min, double max) async {
    double value = 50;
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set $method'),
        content: StatefulBuilder(
          builder: (_, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${value.round()}'),
              Slider(
                value: value,
                min: min,
                max: max,
                onChanged: (v) => setDialogState(() => value = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, value), child: const Text('Send')),
        ],
      ),
    );
    if (result != null) {
      await _sendRpc(method, params: {param: result.round()});
    }
  }
}
