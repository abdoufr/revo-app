import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/client/client_home.dart';
import 'screens/admin/admin_home.dart';
import 'providers/auth_providers.dart';
import 'providers/theme_provider.dart';
import 'screens/client/pending_approval_screen.dart';

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

class RevoApp extends ConsumerWidget {
  const RevoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Revo App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeState.themeMode,
      locale: themeState.locale,
      supportedLocales: const [
        Locale('fr', ''),
        Locale('en', ''),
        Locale('ar', ''),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange)),
      ),
      error: (e, trace) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: Text('Erreur: $e', style: const TextStyle(color: AppTheme.error))),
      ),
    );
  }
}

class RoleWrapper extends ConsumerWidget {
  final String uid;
  const RoleWrapper({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docState = ref.watch(userDocStreamProvider(uid));

    return docState.when(
      data: (doc) {
        if (!doc.exists || doc.data() == null) {
          // Si le document n'existe pas encore (en cours de création)
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange)),
          );
        }

        final data = doc.data()!;
        final role = data['role'] ?? 'client';
        final status = data['status'] ?? 'active';

        if (role == 'admin') {
          return const AdminHome();
        } else {
          if (status == 'pending') {
            return const PendingApprovalScreen();
          }
          return const ClientHome();
        }
      },
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange)),
      ),
      error: (e, trace) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: Text('Erreur: $e', style: const TextStyle(color: AppTheme.error))),
      ),
    );
  }
}
