import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/auth_failure.dart';
import '../../domain/entities/sign_up_result.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/login_id.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_profile_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._client);

  static const String _profilesTable = 'profiles';
  static const String _fullNameMetaKey = 'full_name';

  /// Şifre sıfırlama e-postasındaki bağlantının açacağı adres (Android intent filter ile
  /// aynı). Supabase panelinde Auth > URL Configuration > Redirect URLs listesinde olmalı.
  static const String passwordResetRedirect = 'com.turla.app://login-callback';

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  @override
  Stream<void> get authStateChanges => _auth.onAuthStateChange
      .where(
        (state) =>
            state.event == AuthChangeEvent.signedIn ||
            state.event == AuthChangeEvent.signedOut ||
            state.event == AuthChangeEvent.userUpdated,
      )
      .map((_) {});

  @override
  Future<UserProfile?> currentProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _guard(() => _loadProfile(user));
  }

  @override
  Future<UserProfile> signInWithEmail({required String email, required String password}) =>
      _guard(() async {
        final response = await _auth.signInWithPassword(email: email.trim(), password: password);
        return _loadProfile(response.user!);
      });

  @override
  Future<UserProfile> signInWithLoginId({required String loginId, required String password}) =>
      signInWithEmail(email: LoginId.toEmail(loginId), password: password);

  @override
  Future<SignUpResult> signUpCustomer({
    required String fullName,
    required String email,
    required String password,
  }) => _guard(() async {
    final response = await _auth.signUp(
      email: email.trim(),
      password: password,
      data: {_fullNameMetaKey: fullName.trim()},
    );
    final user = response.user;
    // Supabase, kayıtlı bir e-posta ile tekrar kayıt olunduğunda (doğrulama açıkken)
    // hata yerine kimliği boş bir kullanıcı döndürür.
    if (user == null || (user.identities?.isEmpty ?? false)) {
      throw const AuthFailure(AuthFailureReason.userAlreadyExists);
    }
    if (response.session == null) return const SignUpResult.confirmationRequired();
    return SignUpResult.signedIn(await _loadProfile(user));
  });

  @override
  Future<void> signOut() => _guard(_auth.signOut);

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.resetPasswordForEmail(email.trim(), redirectTo: passwordResetRedirect));

  @override
  Stream<void> get passwordRecoveryRequests => _auth.onAuthStateChange
      .where((state) => state.event == AuthChangeEvent.passwordRecovery)
      .map((_) {});

  @override
  Future<void> updatePassword(String newPassword) =>
      _guard(() => _auth.updateUser(UserAttributes(password: newPassword)));

  @override
  Future<void> updateSelectedCity(int cityId) => _guard(() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _client.from(_profilesTable).update({'selected_city_id': cityId}).eq('id', user.id);
  });

  Future<UserProfile> _loadProfile(User user) async {
    final row = await _client
        .from(_profilesTable)
        .select(UserProfileModel.columns)
        .eq('id', user.id)
        .maybeSingle();
    if (row == null) throw const AuthFailure(AuthFailureReason.profileMissing);

    final profile = UserProfileModel.fromRow(row, email: user.email ?? '');
    if (!profile.isActive) {
      await _auth.signOut();
      throw const AuthFailure(AuthFailureReason.accountDisabled);
    }
    return profile;
  }

  /// Supabase / ağ hatalarını [AuthFailure]'a çevirir.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthFailure {
      rethrow;
    } on AuthException catch (error) {
      throw AuthFailure(_mapAuthError(error), error);
    } on ClientException catch (error) {
      throw AuthFailure(AuthFailureReason.network, error);
    } on TimeoutException catch (error) {
      throw AuthFailure(AuthFailureReason.network, error);
    } on PostgrestException catch (error) {
      throw AuthFailure(AuthFailureReason.unknown, error);
    }
  }

  AuthFailureReason _mapAuthError(AuthException error) {
    if (error is AuthRetryableFetchException) return AuthFailureReason.network;
    switch (error.code) {
      case 'invalid_credentials':
        return AuthFailureReason.invalidCredentials;
      case 'email_not_confirmed':
        return AuthFailureReason.emailNotConfirmed;
      case 'user_already_exists':
      case 'email_exists':
        return AuthFailureReason.userAlreadyExists;
      case 'weak_password':
        return AuthFailureReason.weakPassword;
      case 'same_password':
        return AuthFailureReason.samePassword;
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return AuthFailureReason.rateLimited;
      case 'user_banned':
        return AuthFailureReason.accountDisabled;
    }
    return AuthFailureReason.unknown;
  }
}
