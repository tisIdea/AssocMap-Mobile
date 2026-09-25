import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/registration.dart';
import '../repositories/assoc_repository.dart';

class AppController extends ChangeNotifier {
  final AssocRepository repository;
  Session? session;
  MemberData? data;
  bool loading = false;
  bool refreshing = false;
  bool restoring = false;
  String? error;
  int _generation = 0;
  bool _disposed = false;
  StreamSubscription<bool>? _authSubscription;
  AppController(this.repository) {
    final source = repository;
    if (source is PersistentSessionRepository) {
      _authSubscription = (source as PersistentSessionRepository).sessionChanges
          .listen(
            (signedIn) {
              if (!signedIn) clearSession();
            },
            onError: (Object _) {
              error =
                  'Session refresh failed. Check your connection and retry.';
              _notify();
            },
          );
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void clearSession() {
    _generation++;
    session = null;
    data = null;
    error = null;
    loading = false;
    refreshing = false;
    _notify();
  }

  Future<void> restore() async {
    final source = repository;
    if (source is! PersistentSessionRepository) return;
    restoring = true;
    final generation = _generation;
    try {
      final restored = await (source as PersistentSessionRepository)
          .restoreSession();
      if (generation != _generation || _disposed) return;
      session = restored;
      if (session != null) await refresh();
    } catch (e) {
      error = e is RepositoryException
          ? e.message
          : 'Unable to restore your session. Please sign in again.';
    } finally {
      restoring = false;
      _notify();
    }
  }

  Future<void> login(String email, String password) async {
    final generation = _generation;
    final signedIn = await repository.login(email, password);
    if (_disposed || generation != _generation) return;
    session = signedIn;
    await refresh();
  }

  Future<void> refresh() async {
    if (session == null || refreshing) return;
    final generation = _generation;
    loading = data == null;
    refreshing = true;
    error = null;
    _notify();
    try {
      final fresh = await repository.getMemberData();
      if (generation != _generation || _disposed) return;
      data = fresh;
    } catch (e) {
      if (generation != _generation || _disposed) return;
      if (e is SessionExpiredException || e is AccessRevokedException) {
        clearSession();
        error = (e as RepositoryException).message;
        _notify();
        return;
      }
      error = e is RepositoryException
          ? e.message
          : 'Unable to load association information. Please retry.';
    } finally {
      if (generation == _generation) {
        loading = false;
        refreshing = false;
        _notify();
      }
    }
  }

  Future<Registration> register(Registration input) async {
    final generation = _generation;
    try {
      final saved = await repository.submitRegistration(input);
      if (generation != _generation || session == null) {
        throw const SessionExpiredException();
      }
      final current = data;
      if (current != null) {
        data = MemberData(
          association: current.association,
          members: current.members,
          registrations: [
            saved,
            ...current.registrations.where((r) => r.id != saved.id),
          ],
          projects: current.projects,
          trainings: current.trainings,
        );
      }
      await refresh();
      return saved;
    } on RepositoryException catch (e) {
      if (e is SessionExpiredException || e is AccessRevokedException) {
        clearSession();
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    clearSession();
    try {
      await repository.logout();
    } on SessionExpiredException {
      // An expired token is already unusable.
    }
    clearSession();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _authSubscription?.cancel();
    super.dispose();
  }
}
