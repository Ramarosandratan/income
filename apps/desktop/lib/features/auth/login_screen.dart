import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:income_core/income_core.dart';

/// Connexion du maître, ou création d'une nouvelle famille (1er usage).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  final _familyName = TextEditingController();
  bool _createMode = false;
  bool _loading = false;
  String? _error;
  String? _info;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _fullName.dispose();
    _familyName.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_email.text.trim().isEmpty) return 'Veuillez saisir un email.';
    if (!_email.text.trim().contains('@')) return "Format d'email invalide.";
    if (_password.text.isEmpty) return 'Veuillez saisir un mot de passe.';
    if (_password.text.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères.';
    }
    if (_createMode) {
      if (_fullName.text.trim().isEmpty) return 'Veuillez saisir votre nom.';
      if (_familyName.text.trim().isEmpty) {
        return 'Veuillez saisir un nom de famille.';
      }
    }
    return null;
  }

  Future<void> _submit() async {
    final validationError = _validate();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
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
        if (!mounted) return;
        setState(() {
          _createMode = false;
          _password.clear();
          _info =
              'Compte créé avec succès ! Vous pouvez maintenant vous connecter.';
        });
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Row(
          children: [
            // Bannière latérale décorative
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary,
                      scheme.primary.withValues(alpha: 0.8),
                      scheme.secondary,
                    ],
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.savings,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Income',
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Gérez le budget de votre famille simplement.',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                        ),
                        const SizedBox(height: 24),
                        _FeatureRow(
                          icon: Icons.account_balance_wallet,
                          text: 'Allouez des budgets par membre',
                        ),
                        const SizedBox(height: 12),
                        _FeatureRow(
                          icon: Icons.receipt_long,
                          text: 'Suivez les dépenses en temps réel',
                        ),
                        const SizedBox(height: 12),
                        _FeatureRow(
                          icon: Icons.bar_chart,
                          text: 'Visualisez les rapports mensuels',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Formulaire de connexion
            Expanded(
              flex: 3,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(48),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _createMode ? 'Créer votre famille' : 'Bon retour !',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _createMode
                              ? 'Créez votre famille et votre compte maître.'
                              : 'Connectez-vous pour piloter le budget familial.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 32),
                        if (_createMode) ...[
                          TextField(
                            controller: _familyName,
                            decoration: const InputDecoration(
                              labelText: 'Nom de la famille',
                              prefixIcon: Icon(Icons.home),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _fullName,
                            decoration: const InputDecoration(
                              labelText: 'Votre nom',
                              prefixIcon: Icon(Icons.person),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextField(
                          controller: _email,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _password,
                          decoration: const InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: Icon(Icons.lock_outlined),
                          ),
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: scheme.errorContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    size: 20, color: scheme.onErrorContainer),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: TextStyle(
                                      color: scheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_info != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle,
                                    size: 20,
                                    color: scheme.onPrimaryContainer),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _info!,
                                    style: TextStyle(
                                      color: scheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        FilledButton(
                          onPressed: _loading ? null : _submit,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  _createMode
                                      ? 'Créer la famille'
                                      : 'Se connecter',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(color: Colors.white),
                                ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _loading
                              ? null
                              : () => setState(() {
                                    _createMode = !_createMode;
                                    _error = null;
                                    _info = null;
                                  }),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _createMode
                                ? "J'ai déjà un compte"
                                : 'Première utilisation ? Créer une famille',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.9)),
        const SizedBox(width: 12),
        Text(text,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9), fontSize: 14)),
      ],
    );
  }
}
