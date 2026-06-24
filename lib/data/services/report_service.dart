import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

/// Reportes de información incorrecta de huariques (US21).
class ReportService {
  final Dio _dio = ApiClient.instance;

  Future<void> createReport(int huariqueId, int userId, String reason) async {
    await _dio.post('/reports', data: {
      'huariqueId': huariqueId,
      'userId': userId,
      'reason': reason,
    });
  }
}
