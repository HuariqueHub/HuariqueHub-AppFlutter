import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/app_notification.dart';

/// Notificaciones del usuario (US12).
class NotificationService {
  final Dio _dio = ApiClient.instance;

  Future<List<AppNotification>> getNotifications(int userId) async {
    final response =
        await _dio.get('/notifications', queryParameters: {'userId': userId});
    final list = response.data as List<dynamic>;
    return list
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAsRead(int id) async {
    await _dio.patch('/notifications/$id/read');
  }
}
