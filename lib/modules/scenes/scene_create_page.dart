import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thingsboard_app/modules/scenes/scene_provider.dart';

const _sceneIcons = [
  ('auto_awesome_rounded', Icons.auto_awesome_rounded, 'Default'),
  ('home_rounded', Icons.home_rounded, 'Home'),
  ('bed_rounded', Icons.bed_rounded, 'Bedroom'),
  ('nightlight_round', Icons.nightlight_round, 'Night'),
  ('directions_car_rounded', Icons.directions_car_rounded, 'Away'),
  ('movie_rounded', Icons.movie_rounded, 'Movie'),
  ('celebration_rounded', Icons.celebration_rounded, 'Party'),
  ('wb_sunny_rounded', Icons.wb_sunny_rounded, 'Morning'),
  ('restaurant_rounded', Icons.restaurant_rounded, 'Dinner'),
  ('music_note_rounded', Icons.music_note_rounded, 'Music'),
];

class SceneCreatePage extends ConsumerStatefulWidget {
  const SceneCreatePage({super.key, this.scene});
  final Scene? scene;
  @override
  ConsumerState<SceneCreatePage> createState() => _SceneCreatePageState();
}

class _SceneCreatePageState extends ConsumerState<SceneCreatePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  String? _selectedIconKey;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.scene?.name ?? '');
    _selectedIconKey = widget.scene?.iconKey;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _editing => widget.scene != null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final String? err;
    if (_editing) {
      err = await ref.read(sceneListProvider.notifier).update(
        widget.scene!.id,
        name: _nameCtrl.text.trim(),
        iconKey: _selectedIconKey,
      );
    } else {
      err = await ref.read(sceneListProvider.notifier).create(
        name: _nameCtrl.text.trim(),
        iconKey: _selectedIconKey,
      );
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_editing ? 'Scene updated' : 'Scene created')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit Scene' : 'Create Scene')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Scene name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_rounded),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              autofocus: true,
            ),
            const SizedBox(height: 24),
            Text('Icon', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _sceneIcons.map((entry) {
                final key = entry.$1;
                final icon = entry.$2;
                final label = entry.$3;
                final selected = _selectedIconKey == key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIconKey = key),
                  child: Container(
                    width: 72,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? cs.primary : Colors.transparent, width: 2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant, size: 28),
                        const SizedBox(height: 4),
                        Text(label, style: TextStyle(fontSize: 10, color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_rounded),
              label: Text(_saving ? 'Saving...' : (_editing ? 'Update Scene' : 'Create Scene')),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
