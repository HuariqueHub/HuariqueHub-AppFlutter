import 'package:dio/dio.dart';
import '../models/promo.dart';
import '../../core/network/api_client.dart';

class PromoService {
  final Dio _dio = ApiClient.instance;

  Future<List<Promo>> getAll({int? huariqueId}) async {
    final params = <String, dynamic>{};
    if (huariqueId != null) params['huariqueId'] = huariqueId;
    final response = await _dio.get('/promos', queryParameters: params);
    final list = response.data as List<dynamic>;
    return list.map((e) => Promo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Promo> getById(int id) async {
    final response = await _dio.get('/promos/$id');
    return Promo.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Promo> create(Map<String, dynamic> data) async {
    final response = await _dio.post('/promos', data: data);
    return Promo.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Promo> update(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/promos/$id', data: data);
    return Promo.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _dio.delete('/promos/$id');
  }

  /// Canjea (usa) una promoción incrementando su contador (US26 lado cliente).
  Future<Promo> use(int id) async {
    final response = await _dio.post('/promos/$id/use');
    return Promo.fromJson(response.data as Map<String, dynamic>);
  }
}
