import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/errors/app_failure.dart';
import '../demo/demo_store.dart';
import '../firebase/firestore_paths.dart';
import '../models/app_user.dart';

/// Email/password + Google sign-in, profile docs and admin-claim checks.
class AuthRepository {
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth,
        _db = db;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _db;

  FirebaseAuth get _firebaseAuth {
    final FirebaseAuth? auth = _auth;
    if (auth == null) throw const AppFailure('Firebase غير مهيأ.');
    return auth;
  }

  FirebaseFirestore get _firestore {
    final FirebaseFirestore? db = _db;
    if (db == null) throw const AppFailure('Firebase غير مهيأ.');
    return db;
  }

  // ------------------------------------------------------------------ state

  Stream<AppUser?> authStateChanges() {
    if (DemoStore.enabled) return DemoStore.instance.authStateChanges();
    return _firebaseAuth.authStateChanges().asyncMap((User? user) async {
      if (user == null) return null;
      return ensureUserDocument(user);
    });
  }

  AppUser? get currentAppUser {
    if (DemoStore.enabled) return DemoStore.instance.currentUser;
    final User? user = _auth?.currentUser;
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      displayName: (user.displayName ?? '').trim(),
      email: (user.email ?? '').trim(),
      photoUrl: user.photoURL,
    );
  }

  String? get currentUid {
    if (DemoStore.enabled) return DemoStore.instance.currentUser?.uid;
    return _auth?.currentUser?.uid;
  }

  // --------------------------------------------------------------- sign in

  Future<AppUser> signInWithEmail(String email, String password) async {
    if (DemoStore.enabled) {
      return DemoStore.instance.demoSignIn(email: email.trim());
    }
    final UserCredential cred =
        await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final User? user = cred.user;
    if (user == null) throw const AppFailure('تعذر تسجيل الدخول.');
    return ensureUserDocument(user);
  }

  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    if (DemoStore.enabled) {
      return DemoStore.instance.demoSignIn(email: email.trim(), name: name);
    }
    final UserCredential cred =
        await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final User? user = cred.user;
    if (user == null) throw const AppFailure('تعذر إنشاء الحساب.');
    await user.updateDisplayName(name.trim());
    await user.reload();
    final User refreshed = _firebaseAuth.currentUser ?? user;
    return ensureUserDocument(refreshed);
  }

  Future<AppUser> signInWithGoogle() async {
    if (DemoStore.enabled) {
      return DemoStore.instance.demoSignIn(email: 'demo.user@gmail.com');
    }
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw const AppFailure('تم إلغاء تسجيل الدخول.');
    }
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final UserCredential cred =
        await _firebaseAuth.signInWithCredential(credential);
    final User? user = cred.user;
    if (user == null) throw const AppFailure('تعذر تسجيل الدخول.');
    return ensureUserDocument(user);
  }

  Future<void> sendPasswordReset(String email) async {
    if (DemoStore.enabled) return;
    await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    if (DemoStore.enabled) {
      await DemoStore.instance.demoSignOut();
      return;
    }
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Google session may not exist; ignore.
    }
    await _firebaseAuth.signOut();
  }

  // ------------------------------------------------------------ user docs

  /// Creates the `users/{uid}` profile on first login and refreshes
  /// `lastSeenAt` on every login.
  Future<AppUser> ensureUserDocument(User user) async {
    final DocumentReference<Map<String, dynamic>> ref =
        _firestore.collection(FirestorePaths.users).doc(user.uid);
    try {
      final DocumentSnapshot<Map<String, dynamic>> snap = await ref.get();
      if (!snap.exists) {
        final AppUser created = AppUser(
          uid: user.uid,
          displayName: (user.displayName ?? '').trim().isEmpty
              ? (user.email?.split('@').first ?? 'مستخدم')
              : (user.displayName ?? '').trim(),
          email: (user.email ?? '').trim(),
          photoUrl: user.photoURL,
          createdAt: DateTime.now(),
        );
        await ref.set(created.toMap());
        return created;
      }
      await ref.update(<String, dynamic>{
        'lastSeenAt': FieldValue.serverTimestamp(),
      });
      final Map<String, dynamic>? data = snap.data();
      if (data == null) {
        return AppUser(
          uid: user.uid,
          displayName: (user.displayName ?? '').trim(),
          email: (user.email ?? '').trim(),
          photoUrl: user.photoURL,
        );
      }
      return AppUser.fromMap(user.uid, data);
    } catch (e) {
      debugPrint('ensureUserDocument failed: $e');
      return AppUser(
        uid: user.uid,
        displayName: (user.displayName ?? '').trim(),
        email: (user.email ?? '').trim(),
        photoUrl: user.photoURL,
      );
    }
  }

  Future<AppUser?> getUserDoc(String uid) async {
    if (DemoStore.enabled) {
      return DemoStore.instance.findUser(uid);
    }
    final DocumentSnapshot<Map<String, dynamic>> snap = await _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .get();
    final Map<String, dynamic>? data = snap.data();
    if (!snap.exists || data == null) return null;
    return AppUser.fromMap(uid, data);
  }

  Future<AppUser> updateProfile({String? displayName, String? photoUrl}) async {
    final String? uid = currentUid;
    if (uid == null) throw const AppFailure('سجّل الدخول أولاً.');
    if (DemoStore.enabled) {
      return DemoStore.instance.demoUpdateProfile(
        displayName: displayName,
        photoUrl: photoUrl,
      );
    }
    final Map<String, dynamic> patch = <String, dynamic>{};
    if (displayName != null && displayName.trim().isNotEmpty) {
      patch['displayName'] = displayName.trim();
      await _firebaseAuth.currentUser?.updateDisplayName(displayName.trim());
    }
    if (photoUrl != null) {
      patch['photoUrl'] = photoUrl;
      await _firebaseAuth.currentUser?.updatePhotoURL(photoUrl);
    }
    if (patch.isNotEmpty) {
      await _firestore.collection(FirestorePaths.users).doc(uid).update(patch);
    }
    final AppUser? updated = await getUserDoc(uid);
    return updated ??
        AppUser(uid: uid, displayName: displayName ?? '', email: '');
  }

  // ----------------------------------------------------------------- admin

  /// The ONLY source of truth for admin rights: the `admin` custom claim.
  /// Never trust client-side flags.
  Future<bool> isAdmin({bool forceRefresh = false}) async {
    if (DemoStore.enabled) return DemoStore.instance.isAdminSession;
    final User? user = _auth?.currentUser;
    if (user == null) return false;
    try {
      final IdTokenResult token = await user.getIdTokenResult(forceRefresh);
      return token.claims?['admin'] == true;
    } catch (e) {
      debugPrint('isAdmin check failed: $e');
      return false;
    }
  }

  Future<void> saveFcmToken(String uid, String token) async {
    if (DemoStore.enabled) return;
    try {
      await _firestore.collection(FirestorePaths.users).doc(uid).update(
        <String, dynamic>{'fcmToken': token},
      );
    } catch (e) {
      debugPrint('saveFcmToken failed: $e');
    }
  }

  Future<int> countUsers() async {
    if (DemoStore.enabled) return DemoStore.instance.users.length;
    final AggregateQuerySnapshot snap =
        await _firestore.collection(FirestorePaths.users).count().get();
    return snap.count ?? 0;
  }
}
