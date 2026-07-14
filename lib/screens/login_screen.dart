import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'client/client_home.dart';
import 'admin/admin_home.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isPhoneLogin =
      false; // Par défaut, on met Email pour coller à la maquette Purxx
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _otpSent = false;
  ConfirmationResult? _confirmationResult;

  void _toggleLoginType() {
    setState(() {
      _isPhoneLogin = !_isPhoneLogin;
      _isSignUp = false;
      _otpSent = false;
      _confirmationResult = null;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: SoftCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo and Title
                    Icon(
                      Icons.fastfood_rounded, // Icône plus dans le thème food
                      size: 70,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isSignUp ? 'Créer un compte' : 'Bienvenue sur REVO',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 28,
                        color: Theme.of(context).primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rejoignez la prochaine génération de fidélité.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Inputs
                    if (_isPhoneLogin) ...[
                      if (!_otpSent)
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: Theme.of(context).textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: 'Numéro de téléphone (ex: +213...)',
                            prefixIcon: Icon(
                              Icons.phone,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        )
                      else
                        TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          style: Theme.of(context).textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: 'Code SMS à 6 chiffres',
                            prefixIcon: Icon(
                              Icons.message,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                    ] else ...[
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: Theme.of(context).textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          prefixIcon: Icon(
                            Icons.email,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: Theme.of(context).textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: 'Mot de passe',
                          prefixIcon: Icon(
                            Icons.lock,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Primary Button
                    PrimaryButton(
                      text: _isPhoneLogin
                          ? (_otpSent
                                ? 'Confirmer le Code'
                                : 'Envoyer le Code SMS')
                          : (_isSignUp ? 'Créer mon compte' : 'Se Connecter'),
                      isLoading: _isLoading,
                      onPressed: () async {
                        if (_isPhoneLogin) {
                          if (!_otpSent) {
                            String phone = _phoneController.text.trim();
                            if (phone.isEmpty) return;

                            // Auto-format for Algeria if starts with 0
                            if (phone.startsWith('0')) {
                              phone = '+213${phone.substring(1)}';
                            } else if (!phone.startsWith('+')) {
                              phone = '+$phone';
                            }

                            setState(() => _isLoading = true);
                            try {
                              _confirmationResult = await ref
                                  .read(authControllerProvider)
                                  .verifyPhoneNumber(phone);
                              setState(() => _otpSent = true);
                            } catch (e) {
                              if (mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Erreur: $e')),
                                );
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          } else {
                            if (_otpController.text.isEmpty ||
                                _confirmationResult == null)
                              return;
                            setState(() => _isLoading = true);
                            try {
                              await ref
                                  .read(authControllerProvider)
                                  .verifyOTP(
                                    _confirmationResult!,
                                    _otpController.text.trim(),
                                  );
                            } catch (e) {
                              if (mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Code invalide ou expiré'),
                                  ),
                                );
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          }
                        } else {
                          if (_emailController.text.isEmpty ||
                              _passwordController.text.isEmpty)
                            return;
                          setState(() => _isLoading = true);
                          try {
                            if (_isSignUp) {
                              await ref
                                  .read(authControllerProvider)
                                  .signUpWithEmail(
                                    _emailController.text.trim(),
                                    _passwordController.text.trim(),
                                  );
                            } else {
                              await ref
                                  .read(authControllerProvider)
                                  .signInWithEmail(
                                    _emailController.text.trim(),
                                    _passwordController.text.trim(),
                                  );
                            }
                          } catch (e) {
                            if (mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur: $e')),
                              );
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    if (!_isPhoneLogin)
                      TextButton(
                        onPressed: () => setState(() => _isSignUp = !_isSignUp),
                        child: Text(
                          _isSignUp
                              ? 'Déjà un compte ? Se connecter'
                              : 'Pas de compte ? S\'inscrire',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    if (!_otpSent)
                      TextButton(
                        onPressed: _toggleLoginType,
                        child: Text(
                          _isPhoneLogin
                              ? 'Utiliser l\'Email au lieu'
                              : 'Utiliser le Numéro au lieu',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    if (!_otpSent) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Theme.of(context).dividerColor,
                              thickness: 0.5,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OU',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Theme.of(context).dividerColor,
                              thickness: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Google Button
                    OutlinedButton.icon(
                      onPressed: () async {
                        setState(() => _isLoading = true);
                        try {
                          await ref
                              .read(authControllerProvider)
                              .signInWithGoogle();
                        } catch (e) {
                          if (mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur: $e')),
                            );
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      ),
                      icon: Icon(
                        Icons.account_circle,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      label: Text(
                        'Continuer avec Google',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
