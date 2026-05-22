import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thingsboard_app/modules/automation/automation_provider.dart';

class AutomationDetailPage extends ConsumerWidget {
  const AutomationDetailPage({super.key, required this.automationId});
  final String automationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final automationsAsync = ref.watch(automationListProvider);
    final automation = automationsAsync.maybeWhen(
      data: (list) => list.where((a) => a.id == automationId).firstOrNull,
      orElse: () => null,
    );
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(automation?.name ?? 'Automation'),
        actions: [
          if (automation != null)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Edit',
              onPressed: () => context.push('/automations/create', extra: automation),
            ),
        ],
      ),
      body: automation == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatusCard(automation: automation, cs: cs),
                const SizedBox(height: 12),
                _InfoCard(automation: automation, cs: cs),
              ],
            ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.automation, required this.cs});
  final Automation automation;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              automation.enabled ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
              color: automation.enabled ? Colors.green : Colors.grey,
              size: 32,
            ),
            const SizedBox(width: 12),
            Text(
              automation.enabled ? 'Active' : 'Paused',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: automation.enabled ? Colors.green : Colors.grey),
            ),
            const Spacer(),
            if (automation.lastRunAt != null)
              Text('Last run: ${_formatDate(automation.lastRunAt!)}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.automation, required this.cs});
  final Automation automation;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _row('Trigger', automation.triggerType.name),
            _row('Action', automation.actionType.name),
            _row('Run count', '${automation.runCount}'),
            if (automation.description != null) _row('Description', automation.description!),
            if (automation.triggerConfig != null) _row('Trigger config', automation.triggerConfig!),
            if (automation.actionConfig != null) _row('Action config', automation.actionConfig!),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
