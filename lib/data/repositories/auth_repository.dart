import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import 'storage_repository.dart';

final firebaseAuthProvider = Provider<fa.FirebaseAuth>(
  (ref) => fa.FirebaseAuth.instance,
);
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

// Auth state (Firebase User)
final authStateChangesProvider = StreamProvider<fa.User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

// Current user's profile stream
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authUser = ref.watch(authStateChangesProvider).value;
  if (authUser == null) return const Stream.empty();
  final fs = ref.watch(firestoreProvider);
  return fs.collection('users').doc(authUser.uid).snapshots().map((doc) {
    if (!doc.exists) return null;
    final data = doc.data()!..['uid'] = doc.id;
    return UserProfile.fromJson(data);
  });
});

// Simple sign-in/sign-out helpers
class AuthRepository {
  AuthRepository(this._auth, this._firestore, this._storageRepository);
  final fa.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final StorageRepository _storageRepository;

  Future<void> signInAnonymously() async {
    await _auth.signInAnonymously();
  }

  Future<void> signOut() => _auth.signOut();

  Future<fa.UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<fa.UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? profession,
    String? niche,
    String? photoUrl,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final profile = UserProfile(
      uid: uid,
      name: name,
      email: email,
      phone: phone,
      profession: profession,
      niche: niche,
      photoUrl: photoUrl,
    );
    await _firestore.collection('users').doc(uid).set(profile.toJson());
    return cred;
  }

  Future<String> uploadAvatar({
    required String uid,
    required String filePath,
  }) async {
    return _storageRepository.uploadUserAvatar(uid: uid, file: File(filePath));
  }

  Future<void> setChatTosAccepted({required String uid}) async {
    await _firestore.collection('users').doc(uid).update({
      'chatTosAccepted': true,
    });
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
    ref.watch(storageRepositoryProvider),
  );
});
