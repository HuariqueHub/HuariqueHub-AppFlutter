import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Punto de acceso único al cliente HTTP [Dio] de la aplicación.
///
/// Expone una instancia [Dio] preconfigurada (URL base, timeouts y cabeceras)
/// que comparten todos los servicios, evitando recrear el cliente en cada uno.
class ApiClient {
  /// URL base del backend desplegado de HuariqueHub.
  static const String _baseUrl =
      'https://huariquehub-backend.up.railway.app';

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ))
    ..interceptors.add(_AuthInterceptor());

  /// Instancia compartida de [Dio] ya configurada para consumir la API.
  static Dio get instance => _dio;
}

/// Interceptor que adjunta el token JWT a cada petición saliente.
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Optionally handle 401 → logout here
    handler.next(err);
  }
}
