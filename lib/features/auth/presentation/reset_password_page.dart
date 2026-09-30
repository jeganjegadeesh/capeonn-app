import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/auth_widgets.dart';
import '../data/auth_repository.dart';

/// Opened from the email link (/reset-password?token=...&email=...), or by hand:
/// mobile and desktop users type the reset code from the email.
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key, this.token, this.email});

  final String? token;
  final String? email;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email = TextEditingController(text: widget.email);
  late final TextEditingController _token = TextEditingController(text: widget.token);
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _token.dispose();
    _password.dispose();
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
      final message = await ref.read(authRepositoryProvider).resetPassword(
            email: _email.text,
            token: _token.text,
            password: _password.text,
            confirmation: _confirm.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      context.go('/login');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.displayMessage);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Choose a new password',
      subtitle: 'Enter the reset code from your email, then pick a new password.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[ErrorBanner(_error!), const SizedBox(height: 16)],
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.email,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _token,
              textInputAction: TextInputAction.next,
              validator: (v) => Validators.notEmpty(v, 'Reset code'),
              decoration: const InputDecoration(labelText: 'Reset code', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _password,
              label: 'New password',
              textInputAction: TextInputAction.next,
              validator: Validators.newPassword,
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _confirm,
              label: 'Confirm new password',
              textInputAction: TextInputAction.done,
              validator: Validators.matches(_password),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            LoadingButton(label: 'Reset password', loading: _loading, onPressed: _submit),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Back to sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
