import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thingsboard_app/modules/automation/automation_provider.dart';

class AutomationListPage extends ConsumerWidget {
  const AutomationListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final automationsAsync = ref.watch(automationListProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Automations')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/automations/create'),
        child: const Icon(Icons.add_rounded),
      ),
      body: automationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
                const SizedBox(height: 16),
                Text('Failed to load automations', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('$e', textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                const SizedBox(height: 24),
                FilledButton.tonalIcon(
                  onPressed: () => ref.read(automationListProvider.notifier).load(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (automations) => automations.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.rocket_launch_rounded, size: 64, color: cs.outline),
                    const SizedBox(height: 16),
                    Text('No automations yet', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('Create your first automation rule', style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () => ref.read(automationListProvider.notifier).load(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: automations.length,
                  itemBuilder: (_, i) => _AutomationTile(automations[i], cs, ref),
                ),
              ),
      ),
    );
  }
}

class _AutomationTile extends ConsumerWidget {
  const _AutomationTile(this.automation, this.cs, this.ref);
  final Automation automation;
  final ColorScheme cs;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          automation.enabled ? Icons.play_circle_rounded : Icons.pause_circle_rounded,
          color: automation.enabled ? Colors.green : Colors.grey,
          size: 32,
        ),
        title: Text(automation.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${automation.triggerType.name}  →  ${automation.actionType.name}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(automation.enabled ? Icons.toggle_on_rounded : Icons.toggle_off_outlined, color: automation.enabled ? Colors.green : null),
              onPressed: () => ref.read(automationListProvider.notifier).toggle(automation.id),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: cs.error),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete automation'),
                    content: Text('Delete "${automation.name}"?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                    ],
                  ),
                );
                if (confirm == true) {
                  final err = await ref.read(automationListProvider.notifier).delete(automation.id);
                  if (context.mounted && err != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Automation deleted')));
                  }
                }
              },
            ),
          ],
        ),
        onTap: () => context.push('/automations/${automation.id}'),
      ),
    );
  }
}
