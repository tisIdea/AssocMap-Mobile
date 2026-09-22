import 'package:flutter/foundation.dart';
import '../models/registration.dart';
import '../repositories/assoc_repository.dart';

class AppController extends ChangeNotifier {
  final AssocRepository repository;
  Session? session;
  MemberData? data;
  bool loading = false;
  String? error;
  AppController(this.repository);

  Future<void> login(String email, String password) async {
    session = await repository.login(email, password);
    await refresh();
  }

  Future<void> refresh() async {
    loading = data == null;
    error = null;
    notifyListeners();
    try {
      data = await repository.getMemberData();
    } catch (e) {
      error = e is RepositoryException
          ? e.message
          : 'Unable to load association information. Please retry.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<Registration> register(Registration input) async {
    final saved = await repository.submitRegistration(input);
    await refresh();
    return saved;
  }

  Future<void> logout() async {
    await repository.logout();
    session = null;
    data = null;
    error = null;
    notifyListeners();
  }
}
