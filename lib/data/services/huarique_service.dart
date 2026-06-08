import 'package:dio/dio.dart';
import '../models/huarique.dart';
import '../models/review.dart';
import '../../core/network/api_client.dart';

class HuariqueService {
  final Dio _dio = ApiClient.instance;

  Future<List<Huarique>> getAll({String? category, String? district}) async {
    final params = <String, dynamic>{};
    if (category != null && category != 'Todos') params['category'] = category;
    if (district != null) params['district'] = district;
    final response = await _dio.get('/huariques', queryParameters: params);
    final list = response.data as List<dynamic>;
    return list
        .map((e) => Huarique.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Huarique> getById(int id) async {
    final response = await _dio.get('/huariques/$id');
    return Huarique.fromJson(response.data as Map<String, dynamic>);
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
    final response = await _dio.put('/huariques/$id', data: data);
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
