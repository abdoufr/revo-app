import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'client/client_home.dart';
import 'admin/admin_home.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';

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
  
  bool _isPhoneLogin = true;
  bool _isLoading = false;

  void _toggleLoginType() {
    setState(() {
      _isPhoneLogin = !_isPhoneLogin;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Orbs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentPurple.withOpacity(0.5),
                boxShadow: [
                  BoxShadow(color: AppTheme.accentPurple.withOpacity(0.5), blurRadius: 100, spreadRadius: 50),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentCyan.withOpacity(0.4),
                boxShadow: [
                  BoxShadow(color: AppTheme.accentCyan.withOpacity(0.4), blurRadius: 100, spreadRadius: 50),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: GlassCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.stars_rounded,
                          size: 70,
                          color: AppTheme.textWhite,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'REVO',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 36,
                            letterSpacing: 4,
                            foreground: Paint()
                              ..shader = AppTheme.primaryGradient.createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join the next generation of rewards.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // Inputs
                        if (_isPhoneLogin) ...[
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: AppTheme.textWhite),
                            decoration: const InputDecoration(
                              hintText: 'Numéro de téléphone',
                              prefixIcon: Icon(Icons.phone, color: AppTheme.textGrey),
                            ),
                          ),
                        ] else ...[
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: AppTheme.textWhite),
                            decoration: const InputDecoration(
                              hintText: 'Email',
                              prefixIcon: Icon(Icons.email, color: AppTheme.textGrey),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(color: AppTheme.textWhite),
                            decoration: const InputDecoration(
                              hintText: 'Mot de passe',
                              prefixIcon: Icon(Icons.lock, color: AppTheme.textGrey),
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),
                        
                        // Trendy Button
                        GradientButton(
                          text: 'Se Connecter',
                          isLoading: _isLoading,
                          onPressed: () async {
                            if (_isPhoneLogin) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connexion par téléphone en cours de développement, utilisez Email svp.')));
                              return;
                            }
                            if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
                            
                            setState(() => _isLoading = true);
                            try {
                              await ref.read(authControllerProvider).signInWithEmail(_emailController.text, _passwordController.text);
                            } catch (e) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                        ),

                        const SizedBox(height: 24),

                        TextButton(
                          onPressed: _toggleLoginType,
                          child: Text(
                            _isPhoneLogin 
                                ? 'Utiliser l\'Email au lieu' 
                                : 'Utiliser le Numéro au lieu',
                            style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold),
                          ),
                        ),

                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(child: Divider(color: AppTheme.textGrey, thickness: 0.5)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text('OU', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                            ),
                            const Expanded(child: Divider(color: AppTheme.textGrey, thickness: 0.5)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Google Button
                        OutlinedButton.icon(
                          onPressed: () async {
                            setState(() => _isLoading = true);
                            try {
                              await ref.read(authControllerProvider).signInWithGoogle();
                            } catch (e) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: AppTheme.textGrey.withOpacity(0.3), width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: AppTheme.bgLighter.withOpacity(0.5),
                          ),
                          icon: const Icon(Icons.account_circle, color: Colors.white),
                          label: const Text(
                            'Continuer avec Google',
                            style: TextStyle(color: AppTheme.textWhite, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
