import 'package:dio/dio.dart';
import '../models/plan.dart';
import '../models/subscription.dart';
import '../../core/network/api_client.dart';

class SubscriptionService {
  final Dio _dio = ApiClient.instance;

  Future<List<Plan>> getPlans() async {
    final response = await _dio.get('/plans');
    final list = response.data as List<dynamic>;
    return list.map((e) => Plan.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Subscription?> getActiveSubscription(int userId) async {
    try {
      final response = await _dio
          .get('/subscriptions/active', queryParameters: {'userId': userId});
      return Subscription.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<List<Subscription>> getUserSubscriptions(int userId) async {
    final response = await _dio
        .get('/subscriptions', queryParameters: {'userId': userId});
    final list = response.data as List<dynamic>;
    return list
        .map((e) => Subscription.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Subscription> subscribe(int userId, String planId) async {
    final response = await _dio.post('/subscriptions', data: {
      'userId': userId,
      'planId': planId,
    });
    return Subscription.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> cancel(int subscriptionId) async {
    await _dio.post('/subscriptions/$subscriptionId/cancel');
  }
}
