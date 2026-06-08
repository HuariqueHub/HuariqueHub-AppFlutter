import 'package:flutter/material.dart';
import '../data/models/user.dart';
import '../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  AppUser? _user;
  bool _loading = false;
  String? _error;

  AppUser? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isOwner => _user?.role == UserRole.owner;

  Future<void> tryAutoLogin() async {
    final session = await _service.getSavedSession();
    if (session == null) return;
    _user = AppUser(
      id: session['id'] as int,
      name: session['name'] as String,
      email: '',
      role: _roleFromString(session['role'] as String),
    );
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _service.login(email, password);
      await _service.saveSession(_user!);
      return true;
    } on Exception catch (e) {
      _error = _extractMessage(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _service.register(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      await _service.saveSession(_user!);
      return true;
    } on Exception catch (e) {
      _error = _extractMessage(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _service.logout();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  UserRole _roleFromString(String s) => switch (s) {
        'owner' => UserRole.owner,
        'admin' => UserRole.admin,
        _ => UserRole.consumer,
      };

  String _extractMessage(Exception e) {
    final str = e.toString();
    if (str.contains('401')) return 'Correo o contraseña incorrectos.';
    if (str.contains('409')) return 'El correo ya está registrado.';
    if (str.contains('SocketException') || str.contains('Connection')) {
      return 'Sin conexión al servidor.';
    }
    return 'Error inesperado. Intenta de nuevo.';
  }
}
