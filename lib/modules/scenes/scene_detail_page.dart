import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thingsboard_app/modules/scenes/scene_provider.dart';

class SceneDetailPage extends ConsumerWidget {
  const SceneDetailPage({super.key, required this.sceneId});
  final String sceneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenesAsync = ref.watch(sceneListProvider);
    final scene = scenesAsync.maybeWhen(
      data: (list) => list.where((s) => s.id == sceneId).firstOrNull,
      orElse: () => null,
    );
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(scene?.name ?? 'Scene'),
        actions: [
          if (scene != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Edit',
              onPressed: () => context.push('/scenes/create', extra: scene),
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow_rounded),
              tooltip: 'Activate',
              onPressed: () async {
                final err = await ref.read(sceneListProvider.notifier).activate(scene.id);
                if (context.mounted && err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                }
              },
            ),
          ],
        ],
      ),
      body: scene == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: scene.favorite ? Colors.amber.withAlpha(30) : cs.surfaceContainerHighest,
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: scene.favorite ? Colors.amber : cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Text(scene.name, style: Theme.of(context).textTheme.titleLarge)),
                        if (scene.favorite)
                          const Icon(Icons.star_rounded, color: Colors.amber),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Actions (${scene.actions.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...scene.actions.map((a) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.devices_rounded),
                    title: Text('Device ${a.deviceId}', maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(a.commandJson, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                    trailing: a.delayMs > 0 ? Text('${a.delayMs}ms', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)) : null,
                  ),
                )),
              ],
            ),
    );
  }
}
