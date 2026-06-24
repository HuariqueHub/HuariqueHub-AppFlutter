import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

/// Servicio de favoritos (US03). Consume los endpoints REST `/favorites`
/// del backend desplegado: GET por usuario, POST y DELETE.
class FavoriteService {
  final Dio _dio = ApiClient.instance;

  /// Ids de huariques marcados como favoritos por el usuario.
  Future<Set<int>> getFavoriteIds(int userId) async {
    final response =
        await _dio.get('/favorites', queryParameters: {'userId': userId});
    final list = response.data as List<dynamic>;
    return list
        .map((e) => (e as Map<String, dynamic>)['huariqueId'] as int)
        .toSet();
  }

  /// Agrega a favoritos. Tolera el 409 (ya existía) como éxito idempotente.
  Future<void> add(int userId, int huariqueId) async {
    try {
      await _dio.post('/favorites/$huariqueId',
          queryParameters: {'userId': userId});
    } on DioException catch (e) {
      if (e.response?.statusCode != 409) rethrow;
    }
  }

  /// Quita de favoritos. Tolera el 404 (ya no existía) como éxito idempotente.
  Future<void> remove(int userId, int huariqueId) async {
    try {
      await _dio.delete('/favorites/$huariqueId',
          queryParameters: {'userId': userId});
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) rethrow;
    }
  }
}
