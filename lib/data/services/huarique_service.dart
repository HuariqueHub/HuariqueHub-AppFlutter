import 'package:dio/dio.dart';
import '../models/huarique.dart';
import '../models/review.dart';
import '../../core/network/api_client.dart';

class HuariqueService {
  final Dio _dio = ApiClient.instance;

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

  Future<List<Huarique>> getByOwner(int ownerId) async {
    final response =
        await _dio.get('/huariques', queryParameters: {'ownerId': ownerId});
    final list = response.data as List<dynamic>;
    return list
        .map((e) => Huarique.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Huarique> create(Map<String, dynamic> data) async {
    final response = await _dio.post('/huariques', data: data);
    return Huarique.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Huarique> update(int id, Map<String, dynamic> data) async {
    // El backend expone PATCH (no PUT) para la actualización parcial.
    final response = await _dio.patch('/huariques/$id', data: data);
    return Huarique.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _dio.delete('/huariques/$id');
  }

  // ── Reviews ──────────────────────────────────────────────────────────────
  Future<List<Review>> getReviews(int huariqueId) async {
    final response = await _dio.get('/reviews?huariqueId=$huariqueId');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => Review.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Review> addReview(Map<String, dynamic> data) async {
    final response = await _dio.post('/reviews', data: data);
    return Review.fromJson(response.data as Map<String, dynamic>);
  }
}
