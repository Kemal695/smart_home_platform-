import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thingsboard_app/modules/scenes/scene_provider.dart';

class SceneListPage extends ConsumerWidget {
  const SceneListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenesAsync = ref.watch(sceneListProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Scenes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/scenes/create'),
        child: const Icon(Icons.add_rounded),
      ),
      body: scenesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
                const SizedBox(height: 16),
                Text('Failed to load scenes', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('$e', textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                const SizedBox(height: 24),
                FilledButton.tonalIcon(
                  onPressed: () => ref.read(sceneListProvider.notifier).load(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (scenes) => scenes.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 64, color: cs.outline),
                    const SizedBox(height: 16),
                    Text('No scenes yet', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('Create your first scene', style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () => ref.read(sceneListProvider.notifier).load(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: scenes.length,
                  itemBuilder: (_, i) => _SceneTile(scenes[i], cs, ref),
                ),
              ),
      ),
    );
  }
}

class _SceneTile extends ConsumerWidget {
  const _SceneTile(this.scene, this.cs, this.ref);
  final Scene scene;
  final ColorScheme cs;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scene.favorite ? Colors.amber.withAlpha(30) : cs.surfaceContainerHighest,
          child: Icon(
            _iconFor(scene.iconKey),
            color: scene.favorite ? Colors.amber : cs.onSurfaceVariant,
          ),
        ),
        title: Text(scene.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${scene.actions.length} action${scene.actions.length == 1 ? '' : 's'}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(scene.favorite ? Icons.star_rounded : Icons.star_outline_rounded, color: scene.favorite ? Colors.amber : null),
              onPressed: () => ref.read(sceneListProvider.notifier).toggleFavorite(scene.id),
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.green),
              tooltip: 'Activate',
              onPressed: () async {
                final err = await ref.read(sceneListProvider.notifier).activate(scene.id);
                if (context.mounted && err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: cs.error),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete scene'),
                    content: Text('Delete "${scene.name}"?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                    ],
                  ),
                );
                if (confirm == true) {
                  final err = await ref.read(sceneListProvider.notifier).delete(scene.id);
                  if (context.mounted && err != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scene deleted')));
                  }
                }
              },
            ),
          ],
        ),
        onTap: () => context.push('/scenes/${scene.id}'),
      ),
    );
  }

  IconData _iconFor(String? iconKey) => switch (iconKey) {
    'bedroom' => Icons.bed_rounded,
    'night' => Icons.nightlight_round,
    'away' => Icons.directions_car_rounded,
    'home' => Icons.home_rounded,
    'movie' => Icons.movie_rounded,
    'party' => Icons.celebration_rounded,
    _ => Icons.auto_awesome_rounded,
  };
}
