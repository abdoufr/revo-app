import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// To determine if user is Admin and get their live status
final userDocStreamProvider =
    StreamProvider.family<DocumentSnapshot<Map<String, dynamic>>, String>((
      ref,
      uid,
    ) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots();
    });

final authControllerProvider = Provider((ref) => AuthController(ref));

class AuthController {
  final Ref ref;
  AuthController(this.ref);

  FirebaseAuth get _auth => ref.read(firebaseAuthProvider);

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Erreur de connexion';
    }
  }

  Future<void> signUpWithEmail(
    String email,
    String password, {
    String? phone,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _createUserDoc(
        _auth.currentUser!,
        isEmailSignup: true,
        providedPhone: phone,
      );
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Erreur d\'inscription';
    }
  }

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      GoogleAuthProvider authProvider = GoogleAuthProvider();
      final UserCredential userCredential = await _auth.signInWithPopup(
        authProvider,
      );
      if (userCredential.user != null) {
        await _createUserDoc(userCredential.user!);
      }
    } else {
      throw Exception(
        "La connexion Google n'est actuellement configurée que pour le Web.",
      );
    }
  }

  Future<void> _createUserDoc(
    User user, {
    bool isEmailSignup = false,
    String? providedPhone,
  }) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'name':
            user.displayName ??
            user.email?.split('@')[0] ??
            user.phoneNumber ??
            providedPhone ??
            'Client',
        'email': user.email,
        'phone': user.phoneNumber ?? providedPhone,
        'role': 'client',
        'status': isEmailSignup ? 'pending' : 'active',
        'loyalty_points': 0,
        'lifetime_points': 0,
        'is_public': false,
        'created_at': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<ConfirmationResult> verifyPhoneNumber(String phoneNumber) async {
    // For web, Firebase automatically handles reCAPTCHA
    return await _auth.signInWithPhoneNumber(phoneNumber);
  }

  Future<void> verifyOTP(
    ConfirmationResult confirmationResult,
    String otp,
  ) async {
    final UserCredential userCredential = await confirmationResult.confirm(otp);
    if (userCredential.user != null) {
      await _createUserDoc(userCredential.user!);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
