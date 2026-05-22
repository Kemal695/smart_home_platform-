import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thingsboard_app/constants/app_constants.dart';

class GatewayRegisterPage extends StatefulWidget {
  const GatewayRegisterPage({super.key});
  @override
  State<GatewayRegisterPage> createState() => _GatewayRegisterPageState();
}

class _GatewayRegisterPageState extends State<GatewayRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final host = Uri.tryParse(ThingsboardAppConstants.thingsBoardApiEndpoint)?.host ?? '192.168.1.100';
      final dio = Dio(BaseOptions(baseUrl: 'http://$host:8080'));
      await dio.post('/api/auth/register', data: {
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'password': _pwdCtrl.text,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created. You can now log in.')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Create Gateway Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.home_rounded, size: 56, color: cs.primary),
              const SizedBox(height: 8),
              Text('Smart Home Gateway', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('Create an account to sync with your smart home', textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_rounded), border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_rounded), border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pwdCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_rounded),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscure = !_obscure)),
                ),
                validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm password', prefixIcon: Icon(Icons.lock_rounded), border: OutlineInputBorder()),
                validator: (v) => v != _pwdCtrl.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loading ? null : _register,
                icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.person_add_rounded),
                label: Text(_loading ? 'Creating...' : 'Create Account'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
