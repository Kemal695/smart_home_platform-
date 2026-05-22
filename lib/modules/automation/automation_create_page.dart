import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thingsboard_app/modules/automation/automation_provider.dart';

class AutomationCreatePage extends ConsumerStatefulWidget {
  const AutomationCreatePage({super.key, this.automation});
  final Automation? automation;
  @override
  ConsumerState<AutomationCreatePage> createState() => _AutomationCreatePageState();
}

class _AutomationCreatePageState extends ConsumerState<AutomationCreatePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late TriggerType _triggerType;
  late ActionType _actionType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.automation?.name ?? '');
    _descCtrl = TextEditingController(text: widget.automation?.description ?? '');
    _triggerType = widget.automation?.triggerType ?? TriggerType.schedule;
    _actionType = widget.automation?.actionType ?? ActionType.deviceCommand;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool get _editing => widget.automation != null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final String? err;
    if (_editing) {
      err = await ref.read(automationListProvider.notifier).update(
        widget.automation!.id,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        triggerType: _triggerType,
        actionType: _actionType,
      );
    } else {
      err = await ref.read(automationListProvider.notifier).create(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        triggerType: _triggerType,
        actionType: _actionType,
      );
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_editing ? 'Automation updated' : 'Automation created')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit Automation' : 'Create Automation')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Rule name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_rounded),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_rounded),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Text('Trigger', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<TriggerType>(
              value: _triggerType,
              decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.touch_app_rounded)),
              items: TriggerType.values.map((t) => DropdownMenuItem(value: t, child: Text(_triggerLabel(t)))).toList(),
              onChanged: (v) => setState(() => _triggerType = v!),
            ),
            const SizedBox(height: 24),
            Text('Action', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<ActionType>(
              value: _actionType,
              decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.play_arrow_rounded)),
              items: ActionType.values.map((t) => DropdownMenuItem(value: t, child: Text(_actionLabel(t)))).toList(),
              onChanged: (v) => setState(() => _actionType = v!),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_rounded),
              label: Text(_saving ? 'Saving...' : (_editing ? 'Update Automation' : 'Create Automation')),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ],
        ),
      ),
    );
  }

  String _triggerLabel(TriggerType t) => switch (t) {
    TriggerType.schedule => 'Schedule',
    TriggerType.deviceState => 'Device State Change',
    TriggerType.sensorThreshold => 'Sensor Threshold',
    TriggerType.sunriseSunset => 'Sunrise / Sunset',
    TriggerType.manual => 'Manual',
  };

  String _actionLabel(ActionType t) => switch (t) {
    ActionType.deviceCommand => 'Device Command',
    ActionType.sceneActivate => 'Activate Scene',
    ActionType.notification => 'Send Notification',
    ActionType.webhook => 'Webhook',
  };
}
