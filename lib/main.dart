import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/client/client_home.dart';
import 'screens/admin/admin_home.dart';
import 'providers/auth_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  runApp(
    const ProviderScope(
      child: RevoApp(),
    ),
  );
}

class RevoApp extends StatelessWidget {
  const RevoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Revo App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.trendyTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }
        // User is logged in, check role
        return RoleWrapper(uid: user.uid);
      },
      loading: () => const Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(child: CircularProgressIndicator(color: AppTheme.accentCyan)),
      ),
      error: (e, trace) => Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(child: Text('Erreur: $e', style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}

class RoleWrapper extends ConsumerWidget {
  final String uid;
  const RoleWrapper({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleState = ref.watch(isAdminProvider(uid));

    return roleState.when(
      data: (isAdmin) {
        if (isAdmin) {
          return const AdminHome();
        } else {
          return const ClientHome();
        }
      },
      loading: () => const Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(child: CircularProgressIndicator(color: AppTheme.accentCyan)),
      ),
      error: (e, trace) => const Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(child: Text('Erreur lors du chargement du rôle', style: TextStyle(color: Colors.red))),
      ),
    );
  }
}
