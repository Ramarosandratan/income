import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:income_core/income_core.dart';

/// Connexion du maître, ou création d'une nouvelle famille (1er usage).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  final _familyName = TextEditingController();
  bool _createMode = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _fullName.dispose();
    _familyName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = ref.read(authServiceProvider);
    try {
      if (_createMode) {
        await auth.signUpMaster(
          email: _email.text.trim(),
          password: _password.text,
          fullName: _fullName.text.trim(),
          familyName: _familyName.text.trim(),
        );
      } else {
        await auth.signIn(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Income — Espace maître',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    _createMode
                        ? 'Créez votre famille et votre compte maître.'
                        : 'Connectez-vous pour piloter le budget familial.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  if (_createMode) ...[
                    TextField(
                      controller: _familyName,
                      decoration: const InputDecoration(labelText: 'Nom de la famille'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _fullName,
                      decoration: const InputDecoration(labelText: 'Votre nom'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    decoration: const InputDecoration(labelText: 'Mot de passe'),
                    obscureText: true,
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_createMode ? 'Créer la famille' : 'Se connecter'),
                  ),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() => _createMode = !_createMode),
                    child: Text(_createMode
                        ? 'J\'ai déjà un compte'
                        : 'Première utilisation ? Créer une famille'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
