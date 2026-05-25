import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thingsboard_app/services/gateway_auth_service.dart';

class GatewayRegisterPage extends ConsumerStatefulWidget {
  const GatewayRegisterPage({super.key});
  @override
  ConsumerState<GatewayRegisterPage> createState() => _GatewayRegisterPageState();
}

class _GatewayRegisterPageState extends ConsumerState<GatewayRegisterPage> {
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _isRegister = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailCtrl.text.trim().isEmpty || _pwdCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final service = ref.read(gatewayAuthProvider);
      if (_isRegister) {
        await service.register(
          _nameCtrl.text.trim().isEmpty ? _emailCtrl.text.trim() : _nameCtrl.text.trim(),
          _emailCtrl.text.trim(),
          _pwdCtrl.text,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created. Logging in...')),
        );
      }
      final ok = await service.login(_emailCtrl.text.trim(), _pwdCtrl.text);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gateway connected')),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gateway login failed — check credentials')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleMode() => setState(() => _isRegister = !_isRegister);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final token = ref.watch(gatewayTokenProvider);

    if (token != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gateway Account')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                Text('Gateway Connected', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(gatewayAuthProvider).logout();
                    setState(() {});
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Disconnect'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isRegister ? 'Create Gateway Account' : 'Gateway Login')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.home_rounded, size: 56, color: cs.primary),
            const SizedBox(height: 8),
            Text('Smart Home Gateway', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              _isRegister ? 'Create an account to sync with your smart home' : 'Log in to access smart home features',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            if (_isRegister) ...[
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_rounded), border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_rounded), border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pwdCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_rounded),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(_isRegister ? Icons.person_add_rounded : Icons.login_rounded),
              label: Text(_loading ? 'Please wait...' : (_isRegister ? 'Create & Login' : 'Log In')),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loading ? null : _toggleMode,
              child: Text(_isRegister ? 'Already have an account? Log in' : 'No account? Create one'),
            ),
          ],
        ),
      ),
    );
  }
}
