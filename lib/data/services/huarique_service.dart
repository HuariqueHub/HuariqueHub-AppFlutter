import 'package:dio/dio.dart';
import '../models/huarique.dart';
import '../models/review.dart';
import '../../core/network/api_client.dart';

/// Acceso a los endpoints REST de huariques y sus reseñas.
///
/// Encapsula las llamadas HTTP contra `/huariques` y `/reviews`, y traduce
/// las respuestas JSON del backend a los modelos [Huarique] y [Review].
class HuariqueService {
  final Dio _dio = ApiClient.instance;

  /// Lista los huariques disponibles.
  ///
  /// Cuando [near] es `true` solicita al backend el filtro por cercanía.
  /// Un 404 se interpreta como "sin resultados" y devuelve una lista vacía.
  Future<List<Huarique>> getAll({bool near = false}) async {
    final params = <String, dynamic>{};
    // El backend solo filtra por q/near/ownerId; el resto se filtra en cliente.
    if (near) params['near'] = true;
    try {
      final response = await _dio.get('/huariques', queryParameters: params);
      final list = response.data as List<dynamic>;
      return list
          .map((e) => Huarique.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      // El backend responde 404 cuando un filtro no arroja resultados (US19).
      if (e.response?.statusCode == 404) return [];
      rethrow;
    }
  }

  /// Obtiene el detalle de un huarique por su [id].
  Future<Huarique> getById(int id) async {
    final response = await _dio.get('/huariques/$id');
    return Huarique.fromJson(response.data as Map<String, dynamic>);
  }

  /// Sugerencias personalizadas para el usuario (US18).
  Future<List<Huarique>> getSuggestions(int userId) async {
    try {
      final response = await _dio
          .get('/huariques/suggestions', queryParameters: {'userId': userId});
      final list = response.data as List<dynamic>;
      return list
          .map((e) => Huarique.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      rethrow;
    }
  }

  /// Lista los huariques que pertenecen al dueño [ownerId].
  Future<List<Huarique>> getByOwner(int ownerId) async {
    final response =
        await _dio.get('/huariques', queryParameters: {'ownerId': ownerId});
    final list = response.data as List<dynamic>;
    return list
        .map((e) => Huarique.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Crea un huarique con los campos indicados en [data].
  Future<Huarique> create(Map<String, dynamic> data) async {
    final response = await _dio.post('/huariques', data: data);
    return Huarique.fromJson(response.data as Map<String, dynamic>);
  }

  /// Actualiza parcialmente el huarique [id] con los campos de [data].
  Future<Huarique> update(int id, Map<String, dynamic> data) async {
    // El backend expone PATCH (no PUT) para la actualización parcial.
    final response = await _dio.patch('/huariques/$id', data: data);
    return Huarique.fromJson(response.data as Map<String, dynamic>);
  }

  /// Elimina el huarique con el [id] indicado.
  Future<void> delete(int id) async {
    await _dio.delete('/huariques/$id');
  }

  // ── Reviews ──────────────────────────────────────────────────────────────

  /// Devuelve las reseñas asociadas al huarique [huariqueId].
  Future<List<Review>> getReviews(int huariqueId) async {
    final response = await _dio.get('/reviews?huariqueId=$huariqueId');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => Review.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Publica una nueva reseña con los datos de [data].
  Future<Review> addReview(Map<String, dynamic> data) async {
    final response = await _dio.post('/reviews', data: data);
    return Review.fromJson(response.data as Map<String, dynamic>);
  }
}
