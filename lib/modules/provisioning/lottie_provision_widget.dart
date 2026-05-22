import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import 'package:thingsboard_app/modules/provisioning/provisioning_domain.dart';
import 'package:thingsboard_app/modules/provisioning/provisioning_notifier.dart';

class LottieProvisioningScreen extends ConsumerStatefulWidget {
  const LottieProvisioningScreen({super.key});

  @override
  ConsumerState<LottieProvisioningScreen> createState() =>
      _LottieProvisioningScreenState();
}

class _LottieProvisioningScreenState
    extends ConsumerState<LottieProvisioningScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainCtrl;
  late final AnimationController _bgPulseCtrl;

  ProvisioningStep _lastStep = ProvisioningStep.idle;
  WifiCredentials? _wifi;
  String? _homeId;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(vsync: this);
    _bgPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    final ctx = context;
    final extra = GoRouterState.of(ctx).extra as Map<String, dynamic>?;
    _wifi = extra?['wifi'] as WifiCredentials?;
    _homeId = extra?['homeId'] as String?;

    WidgetsBinding.instance.addPostFrameCallback((_) => _startFlow());
  }

  @override
  void dispose() {
    _cancelled = true;
    _mainCtrl.dispose();
    _bgPulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _startFlow() async {
    final notifier = ref.read(provisioningProvider.notifier);

    notifier.startScan();
    _setStep(ProvisioningStep.scanning);

    await Future.delayed(const Duration(seconds: 2));
    if (_cancelled) return;
    _setStep(ProvisioningStep.deviceFound);

    await Future.delayed(const Duration(milliseconds: 800));
    if (_cancelled) return;
    _setStep(ProvisioningStep.connecting);

    await Future.delayed(const Duration(seconds: 2));
    if (_cancelled) return;
    _setStep(ProvisioningStep.connected);

    final token = await notifier.sendCredentials(
      _wifi ?? const WifiCredentials(ssid: 'HomeWiFi'),
      _homeId,
    );
    if (_cancelled || token == null) return;

    _setStep(ProvisioningStep.waitingForWifi);
    await Future.delayed(const Duration(seconds: 3));
    if (_cancelled) return;
    _setStep(ProvisioningStep.wifiConnected);

    notifier.registeringDevice();
    _setStep(ProvisioningStep.registeringDevice);
    await Future.delayed(const Duration(seconds: 2));
    if (_cancelled) return;

    final deviceId = 'dev-${DateTime.now().millisecondsSinceEpoch}';
    notifier.complete(deviceId);
    _setStep(ProvisioningStep.complete);
  }

  void _setStep(ProvisioningStep step) {
    if (_cancelled) return;
    ref.read(provisioningProvider.notifier);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(provisioningProvider);
    final cs = Theme.of(context).colorScheme;

    final router = GoRouter.of(context);
    ref.listen<ProvisioningState>(provisioningProvider, (prev, next) {
      if (next.step != _lastStep) {
        _mainCtrl.reset();
        _lastStep = next.step;
      }
      if (next.isComplete && next.provisionedDeviceId != null) {
        final deviceId = next.provisionedDeviceId;
        Future.delayed(
          const Duration(milliseconds: 1800),
          () => router.go('/deviceControl/$deviceId'),
        );
      }
    });

    return PopScope(
      canPop: state.step.isTerminal || state.step == ProvisioningStep.idle,
      child: Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _TopBar(step: state.step),
                const SizedBox(height: 32),
                _LottieHero(
                  step: state.step,
                  mainCtrl: _mainCtrl,
                  bgPulseCtrl: _bgPulseCtrl,
                ),
                const SizedBox(height: 28),
                _StepLabel(state: state),
                const SizedBox(height: 24),
                _AnimatedProgressBar(step: state.step),
                const SizedBox(height: 32),
                const Expanded(child: SizedBox()),
                _LottieChecklist(currentStep: state.step),
                const SizedBox(height: 24),
                if (state.isFailed)
                  _ErrorActions(
                    onRetry: () {
                      ref.read(provisioningProvider.notifier).reset();
                      _cancelled = false;
                      _startFlow();
                    },
                    onCancel: () => Navigator.of(context).pop(),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.step});
  final ProvisioningStep step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (!step.isInProgress || step.isTerminal)
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: Theme.of(context).colorScheme.onSurface,
          ),
        const Expanded(
          child: Text(
            'Device Setup',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }
}

class _LottieHero extends StatelessWidget {
  const _LottieHero({
    required this.step,
    required this.mainCtrl,
    required this.bgPulseCtrl,
  });

  final ProvisioningStep step;
  final AnimationController mainCtrl;
  final AnimationController bgPulseCtrl;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: anim,
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: _buildHeroContent(context, cs),
    );
  }

  Widget _buildHeroContent(BuildContext context, ColorScheme cs) {
    return switch (step) {
      ProvisioningStep.idle => _idleWidget(cs),
      ProvisioningStep.scanning || ProvisioningStep.deviceFound => _scanWidget(cs),
      ProvisioningStep.connecting || ProvisioningStep.connected => _connectWidget(cs),
      ProvisioningStep.sendingCredentials => _sendWidget(cs),
      ProvisioningStep.waitingForWifi || ProvisioningStep.wifiConnected => _wifiWidget(cs),
      ProvisioningStep.registeringDevice => _cloudWidget(cs),
      ProvisioningStep.complete => _successWidget(cs),
      ProvisioningStep.failed => _errorWidget(cs),
    };
  }

  Widget _idleWidget(ColorScheme cs) => _HeroContainer(
        key: const ValueKey('idle'),
        color: cs.primaryContainer,
        child: Icon(Icons.bluetooth_rounded, size: 80, color: cs.primary),
      );

  Widget _scanWidget(ColorScheme cs) => _HeroContainer(
        key: const ValueKey('scan'),
        color: cs.primaryContainer,
        child: _LottieOrFallback(
          lottiePath: 'assets/animations/anim_ble_scan.json',
          controller: mainCtrl,
          fallbackIcon: Icons.bluetooth_searching_rounded,
          fallbackColor: cs.primary,
          onLoaded: (comp) {
            mainCtrl.duration = comp.duration;
            mainCtrl.repeat();
          },
        ),
      );

  Widget _connectWidget(ColorScheme cs) => _HeroContainer(
        key: const ValueKey('connect'),
        color: cs.primaryContainer,
        child: _LottieOrFallback(
          lottiePath: 'assets/animations/anim_loading.json',
          controller: mainCtrl,
          fallbackIcon: Icons.bluetooth_connected_rounded,
          fallbackColor: cs.primary,
          onLoaded: (comp) {
            mainCtrl.duration = comp.duration;
            mainCtrl.repeat();
          },
        ),
      );

  Widget _sendWidget(ColorScheme cs) => _HeroContainer(
        key: const ValueKey('send'),
        color: cs.secondaryContainer,
        child: _LottieOrFallback(
          lottiePath: 'assets/animations/anim_loading.json',
          controller: mainCtrl,
          fallbackIcon: Icons.send_rounded,
          fallbackColor: cs.secondary,
          onLoaded: (comp) {
            mainCtrl.duration = comp.duration;
            mainCtrl.repeat();
          },
        ),
      );

  Widget _wifiWidget(ColorScheme cs) => _HeroContainer(
        key: const ValueKey('wifi'),
        color: const Color(0xFFE6F4F1),
        child: _LottieOrFallback(
          lottiePath: 'assets/animations/anim_wifi_connect.json',
          controller: mainCtrl,
          fallbackIcon: Icons.wifi_rounded,
          fallbackColor: const Color(0xFF1D9E75),
          onLoaded: (comp) {
            mainCtrl.duration = comp.duration;
            mainCtrl.repeat();
          },
        ),
      );

  Widget _cloudWidget(ColorScheme cs) => _HeroContainer(
        key: const ValueKey('cloud'),
        color: const Color(0xFFE6F4F1),
        child: _LottieOrFallback(
          lottiePath: 'assets/animations/anim_cloud_upload.json',
          controller: mainCtrl,
          fallbackIcon: Icons.cloud_upload_rounded,
          fallbackColor: const Color(0xFF1D9E75),
          onLoaded: (comp) {
            mainCtrl.duration = comp.duration;
            mainCtrl.repeat();
          },
        ),
      );

  Widget _successWidget(ColorScheme cs) => _HeroContainer(
        key: const ValueKey('success'),
        color: const Color(0xFFE8F5E9),
        child: _LottieOrFallback(
          lottiePath: 'assets/animations/anim_success.json',
          controller: mainCtrl,
          fallbackIcon: Icons.check_circle_rounded,
          fallbackColor: Colors.green,
          onLoaded: (comp) {
            mainCtrl.duration = comp.duration;
            mainCtrl.forward();
          },
        ),
      );

  Widget _errorWidget(ColorScheme cs) => _HeroContainer(
        key: const ValueKey('error'),
        color: cs.errorContainer,
        child: _LottieOrFallback(
          lottiePath: 'assets/animations/anim_error.json',
          controller: mainCtrl,
          fallbackIcon: Icons.error_rounded,
          fallbackColor: cs.error,
          onLoaded: (comp) {
            mainCtrl.duration = comp.duration;
            mainCtrl.forward();
          },
        ),
      );
}

class _HeroContainer extends StatelessWidget {
  const _HeroContainer({super.key, required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}

class _LottieOrFallback extends StatelessWidget {
  const _LottieOrFallback({
    required this.lottiePath,
    required this.controller,
    required this.fallbackIcon,
    required this.fallbackColor,
    required this.onLoaded,
  });

  final String lottiePath;
  final AnimationController controller;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final void Function(LottieComposition) onLoaded;

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      lottiePath,
      controller: controller,
      fit: BoxFit.contain,
      onLoaded: onLoaded,
      errorBuilder: (context, error, stackTrace) {
        return _AnimatedFallbackIcon(
          icon: fallbackIcon,
          color: fallbackColor,
        );
      },
    );
  }
}

class _AnimatedFallbackIcon extends StatelessWidget {
  const _AnimatedFallbackIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: 80, color: color)
        .animate(onPlay: (ctrl) => ctrl.repeat())
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.08, 1.08),
          duration: 1000.ms,
          curve: Curves.easeInOut,
        )
        .then()
        .scale(
          begin: const Offset(1.08, 1.08),
          end: const Offset(1, 1),
          duration: 1000.ms,
          curve: Curves.easeInOut,
        );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.state});
  final ProvisioningState state;

  static const _subtitles = {
    ProvisioningStep.scanning: 'Hold your device close to your phone',
    ProvisioningStep.deviceFound: 'SmartHome device detected nearby',
    ProvisioningStep.connecting: 'Establishing secure Bluetooth link\u2026',
    ProvisioningStep.connected: 'Bluetooth connection established',
    ProvisioningStep.sendingCredentials: 'Transmitting WiFi details securely\u2026',
    ProvisioningStep.waitingForWifi: 'Device is joining your network\u2026',
    ProvisioningStep.wifiConnected: 'Your device is now online',
    ProvisioningStep.registeringDevice: 'Linking device to your account\u2026',
    ProvisioningStep.complete: 'Your device is ready to use',
    ProvisioningStep.failed: 'Something went wrong. Try again.',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isFailed = state.isFailed;
    final subtitle = _subtitles[state.step] ?? '';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Column(
        key: ValueKey(state.step),
        children: [
          Text(
            state.step.label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isFailed ? cs.error : cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (state.hasError) ...[
            const SizedBox(height: 8),
            Text(
              state.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnimatedProgressBar extends StatelessWidget {
  const _AnimatedProgressBar({required this.step});
  final ProvisioningStep step;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isFailed = step == ProvisioningStep.failed;

    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: step.progress),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
          builder: (_, value, _) => ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: isFailed ? null : value,
              minHeight: 8,
              backgroundColor: cs.surfaceContainerHighest,
              color: isFailed ? cs.error : cs.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (!isFailed)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: step.progress),
            duration: const Duration(milliseconds: 700),
            builder: (_, value, _) => Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                  fontSize: 12,
                  color: cs.primary,
                  fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

class _LottieChecklist extends StatelessWidget {
  const _LottieChecklist({required this.currentStep});
  final ProvisioningStep currentStep;

  static const _steps = [
    (ProvisioningStep.scanning, 'Scanning for device'),
    (ProvisioningStep.connected, 'Bluetooth connected'),
    (ProvisioningStep.sendingCredentials, 'WiFi credentials sent'),
    (ProvisioningStep.waitingForWifi, 'Device joined WiFi'),
    (ProvisioningStep.registeringDevice, 'Registered with server'),
    (ProvisioningStep.complete, 'Setup complete'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: _steps.asMap().entries.map((entry) {
          final idx = entry.key;
          final step = entry.value.$1;
          final label = entry.value.$2;
          final isDone = currentStep.index > step.index;
          final isCurrent = currentStep == step;
          final isLast = idx == _steps.length - 1;

          return _ChecklistRow(
            label: label,
            isDone: isDone,
            isCurrent: isCurrent,
            showDivider: !isLast,
          );
        }).toList(),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.label,
    required this.isDone,
    required this.isCurrent,
    required this.showDivider,
  });

  final String label;
  final bool isDone;
  final bool isCurrent;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isDone
                      ? const Icon(Icons.check_circle_rounded,
                          key: ValueKey('done'),
                          color: Colors.green,
                          size: 24)
                      : isCurrent
                          ? Padding(
                              padding: const EdgeInsets.all(4),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: cs.primary,
                              ),
                            )
                          : Container(
                              width: 20,
                              height: 20,
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: cs.outline.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                            ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isCurrent ? FontWeight.w600 : FontWeight.normal,
                  color: isDone
                      ? Colors.green.shade600
                      : isCurrent
                          ? cs.onSurface
                          : cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
              const Spacer(),
              if (isDone)
                Text(
                  'Done',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.w500),
                ),
              if (isCurrent)
                Text(
                  'In progress',
                  style: TextStyle(
                      fontSize: 11,
                      color: cs.primary,
                      fontWeight: FontWeight.w500),
                ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 0,
            indent: 54,
            endIndent: 0,
            color: cs.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}

class _ErrorActions extends StatelessWidget {
  const _ErrorActions({required this.onRetry, required this.onCancel});

  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: onRetry,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }
}
