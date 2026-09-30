import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/auth_widgets.dart';
import '../data/auth_repository.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).changePassword(
            currentPassword: _current.text,
            newPassword: _new.text,
            confirmation: _confirm.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed. Your other devices have been signed out.')),
      );
      context.canPop() ? context.pop() : context.go('/home');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.displayMessage);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change password')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[ErrorBanner(_error!), const SizedBox(height: 16)],
                  PasswordField(
                    controller: _current,
                    label: 'Current password',
                    textInputAction: TextInputAction.next,
                    validator: (v) => Validators.notEmpty(v, 'Current password'),
                  ),
                  const SizedBox(height: 16),
                  PasswordField(
                    controller: _new,
                    label: 'New password',
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      final problem = Validators.newPassword(v);
                      if (problem != null) return problem;
                      return v == _current.text ? 'Choose a password different from your current one' : null;
                    },
                  ),
                  const SizedBox(height: 16),
                  PasswordField(
                    controller: _confirm,
                    label: 'Confirm new password',
                    textInputAction: TextInputAction.done,
                    validator: Validators.matches(_new),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 20),
                  LoadingButton(label: 'Change password', loading: _loading, onPressed: _submit),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
