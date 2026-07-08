import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../../core/network/api_client.dart';

class AuthService {
  final Dio _dio = ApiClient.instance;

  Future<AppUser> login(String email, String password) async {
    // POST /auth/login → returns { id, name, email, role, token }
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = response.data as Map<String, dynamic>;
    if (data['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', data['token'] as String);
    }
    return AppUser.fromJson(data);
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    await _dio.post('/users', data: {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    });
    // POST /users no devuelve token; iniciamos sesión automáticamente para
    // obtener y persistir el JWT y así habilitar las llamadas autenticadas.
    return login(email, password);
  }

  /// Inicia la recuperación de contraseña (US16). Devuelve el mensaje del backend.
  Future<String> forgotPassword(String email) async {
    final response =
        await _dio.post('/auth/forgot-password', data: {'email': email});
    return (response.data as Map<String, dynamic>)['message'] as String? ?? '';
  }

  /// Restablece la contraseña (US16).
  Future<String> resetPassword(String email, String newPassword) async {
    final response = await _dio.post('/auth/reset-password',
        data: {'email': email, 'newPassword': newPassword});
    return (response.data as Map<String, dynamic>)['message'] as String? ?? '';
  }

  Future<List<AppUser>> getUsers() async {
    final response = await _dio.get('/users');
    final list = response.data as List<dynamic>;
    return list.map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_role');
    await prefs.remove('user_name');
  }

  Future<void> saveSession(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', user.id);
    await prefs.setString('user_role', user.role.name);
    await prefs.setString('user_name', user.name);
  }
  /// Actualiza el nombre del perfil (PATCH /auth/users/{id}).
  Future<AppUser> updateProfile(int id, String name) async {
    final response = await _dio.patch('/auth/users/$id', data: {'name': name});
    return AppUser.fromJson(response.data as Map<String, dynamic>);
  }

  /// Elimina la cuenta del usuario (DELETE /auth/users/{id}).
  Future<void> deleteAccount(int id) async {
    await _dio.delete('/auth/users/$id');
  }

  Future<Map<String, dynamic>?> getSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('user_id');
    if (id == null) return null;
    return {
      'id': id,
      'role': prefs.getString('user_role') ?? 'consumer',
      'name': prefs.getString('user_name') ?? '',
    };

  }
}
