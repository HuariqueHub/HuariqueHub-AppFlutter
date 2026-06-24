import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

/// Preferencias del usuario (US17) y notificaciones (US11).
class PreferenceService {
  final Dio _dio = ApiClient.instance;

  Future<Map<String, dynamic>> getPreferences(int userId) async {
    final response =
        await _dio.get('/preferences', queryParameters: {'userId': userId});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> savePreferences(
    int userId, {
    String? preferredCategory,
    double? maxBudget,
    String? preferredDistrict,
    required bool notificationsEnabled,
  }) async {
    final response = await _dio.put(
      '/preferences',
      queryParameters: {'userId': userId},
      data: {
        'preferredCategory': preferredCategory,
        'maxBudget': maxBudget,
        'preferredDistrict': preferredDistrict,
        'notificationsEnabled': notificationsEnabled,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
