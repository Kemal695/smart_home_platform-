import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:thingsboard_app/modules/provisioning/provisioning_domain.dart';
import 'package:thingsboard_app/modules/provisioning/provisioning_notifier.dart';
import 'package:thingsboard_app/services/smart_home_api.dart';

class ProvisioningScreen extends StatefulWidget {
  const ProvisioningScreen({super.key, this.homeId, this.roomId});
  final String? homeId;
  final String? roomId;

  @override
  State<ProvisioningScreen> createState() => _ProvisioningScreenState();
}

class _ProvisioningScreenState extends State<ProvisioningScreen> {
  final _scannerController = MobileScannerController();
  bool _detected = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_detected) return;
    final barcode = capture.barcodes.firstOrNull;
    final raw = barcode?.rawValue;
    if (raw == null || raw.isEmpty) return;
    _detected = true;

    final uri = Uri.tryParse(raw);
    String? deviceType;
    if (uri != null && uri.scheme == 'smarthome' && uri.host == 'provision') {
      deviceType = uri.queryParameters['type'];
    }

    if (!mounted) return;
    context.push('/provision/wifi', extra: {
      'homeId': widget.homeId,
      'roomId': widget.roomId,
      'deviceType': deviceType,
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Add Device')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          _ScannerOverlay(cs),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 48),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                'Point the camera at the QR code on the bottom of your device',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay(this.cs);
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScannerOverlayPainter(cs),
      size: Size.infinite,
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  _ScannerOverlayPainter(this.cs);
  final ColorScheme cs;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 24),
      width: 260,
      height: 260,
    );

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16))),
      ),
      Paint()..color = Colors.black.withAlpha(102),
    );

    final paint = Paint()
      ..color = cs.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    const len = 24.0;

    canvas.drawPath(Path()
      ..moveTo(rect.left, rect.top + len)
      ..lineTo(rect.left, rect.top)
      ..lineTo(rect.left + len, rect.top), paint);
    canvas.drawPath(Path()
      ..moveTo(rect.right - len, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.top + len), paint);
    canvas.drawPath(Path()
      ..moveTo(rect.left, rect.bottom - len)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left + len, rect.bottom), paint);
    canvas.drawPath(Path()
      ..moveTo(rect.right - len, rect.bottom)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.right, rect.bottom - len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WifiCredentialsScreen extends StatefulWidget {
  const WifiCredentialsScreen({super.key, this.homeId, this.roomId, this.deviceType});
  final String? homeId;
  final String? roomId;
  final String? deviceType;

  @override
  State<WifiCredentialsScreen> createState() => _WifiCredentialsScreenState();
}

class _WifiCredentialsScreenState extends State<WifiCredentialsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ssidCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _ssidCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final bluetoothGranted = await Permission.bluetoothScan.request().isGranted ||
        await Permission.bluetooth.request().isGranted;
    final locationGranted = await Permission.location.request().isGranted;
    if (!bluetoothGranted || !locationGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth and location permissions are required')),
        );
      }
      return;
    }

    if (!mounted) return;
    context.push('/provision/progress', extra: {
      'homeId': widget.homeId,
      'roomId': widget.roomId,
      'wifi': WifiCredentials(ssid: _ssidCtrl.text.trim(), password: _pwdCtrl.text),
      'deviceType': widget.deviceType,
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('WiFi Setup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.wifi_rounded, size: 48, color: cs.primary),
              const SizedBox(height: 16),
              Text('Connect to your WiFi', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Your smart device needs WiFi to connect to the internet', style: TextStyle(color: cs.onSurfaceVariant)),
              const SizedBox(height: 32),
              TextFormField(
                controller: _ssidCtrl,
                decoration: const InputDecoration(
                  labelText: 'WiFi name (SSID)',
                  prefixIcon: Icon(Icons.router_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your WiFi name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pwdCtrl,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'WiFi password',
                  prefixIcon: const Icon(Icons.lock_rounded),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer.withAlpha(60),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 20, color: cs.tertiary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Make sure you select a 2.4 GHz network, as most smart devices don\'t support 5 GHz.',
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.bluetooth_searching_rounded),
                label: const Text('Connect Device'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProvisioningProgressScreen extends ConsumerStatefulWidget {
  const ProvisioningProgressScreen({super.key});
  @override
  ConsumerState<ProvisioningProgressScreen> createState() => _ProvisioningProgressScreenState();
}

class _ProvisioningProgressScreenState extends ConsumerState<ProvisioningProgressScreen> {
  WifiCredentials? _wifi;
  String? _homeId;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    _wifi = extra?['wifi'] as WifiCredentials?;
    _homeId = extra?['homeId'] as String?;
    WidgetsBinding.instance.addPostFrameCallback((_) => _startFlow());
  }

  @override
  void dispose() {
    _cancelled = true;
    super.dispose();
  }

  Future<void> _startFlow() async {
    final notifier = ref.read(provisioningProvider.notifier);
    final dio = ref.read(smartHomeDioProvider);

    notifier.startScan();

    final token = await notifier.sendCredentials(
      _wifi ?? const WifiCredentials(ssid: 'HomeWiFi', password: ''),
      _homeId,
    );
    if (_cancelled) return;
    if (token == null) return;

    notifier.registeringDevice();
    await _delay(2000);
    if (_cancelled) return;

    String? deviceId;
    for (var i = 0; i < 6; i++) {
      if (_cancelled) return;
      await _delay(3000);
      if (_cancelled) return;
      try {
        final res = await dio.get<List<dynamic>>('/api/devices');
        final devices = (res.data ?? []).cast<Map<String, dynamic>>();
        if (devices.isNotEmpty) {
          deviceId = devices.last['id'] as String?;
          break;
        }
      } catch (_) {}
    }

    if (_cancelled) return;
    notifier.complete(deviceId ?? 'dev-${DateTime.now().millisecondsSinceEpoch}');
  }

  Future<void> _delay(int ms) => Future.delayed(Duration(milliseconds: ms));

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(provisioningProvider);
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: state.step.isTerminal || state.step == ProvisioningStep.idle,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Setting Up Device'),
          leading: state.step.isInProgress ? const SizedBox() : null,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              _StepIcon(step: state.step, cs: cs),
              const SizedBox(height: 24),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: state.step.progress),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: state.isFailed ? null : v,
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 8,
                  backgroundColor: cs.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  state.step.label,
                  key: ValueKey(state.step),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (state.hasError) ...[
                const SizedBox(height: 12),
                Text(state.errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: cs.error, fontSize: 13)),
              ],
              const SizedBox(height: 32),
              _StepChecklist(currentStep: state.step, cs: cs),
              const Spacer(flex: 3),
              if (state.isFailed) ...[
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          _cancelled = true;
                          ref.read(provisioningProvider.notifier).reset();
                          context.pop();
                        },
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          ref.read(provisioningProvider.notifier).reset();
                          _cancelled = false;
                          _startFlow();
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try Again'),
                      ),
                    ),
                  ],
                ),
              ],
              if (state.isComplete) ...[
                FilledButton.icon(
                  onPressed: () {
                    final deviceId = state.provisionedDeviceId;
                    if (deviceId != null) {
                      context.go('/deviceControl/$deviceId');
                    } else {
                      context.pop();
                    }
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('View Device'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIcon extends StatelessWidget {
  const _StepIcon({required this.step, required this.cs});
  final ProvisioningStep step;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: SizedBox(width: 96, height: 96, key: ValueKey(step), child: _icon()),
    );
  }

  Widget _icon() {
    return switch (step) {
      ProvisioningStep.scanning || ProvisioningStep.deviceFound || ProvisioningStep.connecting =>
        _circle(Icons.bluetooth_searching_rounded, cs.primary, true),
      ProvisioningStep.connected =>
        _circle(Icons.bluetooth_connected_rounded, cs.primary, false),
      ProvisioningStep.sendingCredentials =>
        _circle(Icons.send_rounded, cs.primary, false),
      ProvisioningStep.waitingForWifi || ProvisioningStep.wifiConnected =>
        _circle(Icons.wifi_rounded, cs.tertiary, step == ProvisioningStep.waitingForWifi),
      ProvisioningStep.registeringDevice =>
        _circle(Icons.cloud_upload_rounded, cs.tertiary, false),
      ProvisioningStep.complete =>
        _circle(Icons.check_circle_rounded, Colors.green, false),
      ProvisioningStep.failed =>
        _circle(Icons.error_rounded, cs.error, false),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _circle(IconData icon, Color color, bool spinning) {
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withAlpha(25)),
      child: spinning
          ? Center(child: SizedBox(width: 48, height: 48, child: CircularProgressIndicator(strokeWidth: 3, color: color)))
          : Icon(icon, size: 48, color: color),
    );
  }
}

class _StepChecklist extends StatelessWidget {
  const _StepChecklist({required this.currentStep, required this.cs});
  final ProvisioningStep currentStep;
  final ColorScheme cs;

  static const _steps = [
    ('Scanning', Icons.bluetooth_searching_rounded),
    ('Connecting', Icons.bluetooth_connected_rounded),
    ('Sending credentials', Icons.send_rounded),
    ('Connecting to WiFi', Icons.wifi_rounded),
    ('Registering device', Icons.cloud_upload_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final stepIndex = ProvisioningStep.values.indexOf(currentStep);
    return Column(
      children: List.generate(_steps.length, (i) {
        final done = stepIndex > i + 1;
        final inProgress = stepIndex == i + 1;
        final color = done ? Colors.green : (inProgress ? cs.primary : cs.outline);
        final child = done
            ? const Icon(Icons.check_circle_rounded, size: 20, color: Colors.green)
            : inProgress
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary))
                : Icon(Icons.circle_outlined, size: 20, color: cs.outline);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              child,
              const SizedBox(width: 12),
              Text(_steps[i].$1, style: TextStyle(color: done || inProgress ? color : cs.outline)),
            ],
          ),
        );
      }),
    );
  }
}
