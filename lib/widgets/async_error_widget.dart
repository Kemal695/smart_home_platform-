import 'package:flutter/material.dart';

class AsyncErrorWidget extends StatelessWidget {
  const AsyncErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.title = 'Something went wrong',
    this.icon,
  });

  final Object error;
  final VoidCallback? onRetry;
  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon ?? Icons.error_outline_rounded, size: 48, color: cs.error),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('$error', textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AsyncEmptyWidget extends StatelessWidget {
  const AsyncEmptyWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.action,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? Icons.inbox_rounded, size: 64, color: cs.outline),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, style: TextStyle(color: cs.onSurfaceVariant)),
          ],
          if (action != null) ...[
            const SizedBox(height: 24),
            action!,
          ],
        ],
      ),
    );
  }
}
