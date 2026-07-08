import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../../core/network/api_client.dart';

/// Maneja la autenticación y la persistencia de la sesión del usuario.
///
/// Se encarga del login/registro contra el backend, del almacenamiento del
/// token JWT y de los datos básicos de sesión en [SharedPreferences].
class AuthService {
  final Dio _dio = ApiClient.instance;

  /// Inicia sesión con [email] y [password].
  ///
  /// Si la respuesta incluye un token, lo persiste para autenticar las
  /// siguientes peticiones. Devuelve el [AppUser] autenticado.
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

  /// Registra un nuevo usuario y lo deja autenticado.
  ///
  /// Como `POST /users` no devuelve token, tras crear la cuenta se hace login
  /// automático para obtener y persistir el JWT.
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

  /// Obtiene la lista de usuarios registrados.
  Future<List<AppUser>> getUsers() async {
    final response = await _dio.get('/users');
    final list = response.data as List<dynamic>;
    return list.map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Cierra la sesión eliminando el token y los datos de usuario guardados.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_role');
    await prefs.remove('user_name');
  }

  /// Persiste los datos básicos de la sesión ([id], rol y nombre) del [user].
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

  /// Recupera la sesión guardada, o `null` si no hay ninguna almacenada.
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
