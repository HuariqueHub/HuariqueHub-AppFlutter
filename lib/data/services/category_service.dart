import 'package:dio/dio.dart';
import '../models/category.dart';
import '../../core/network/api_client.dart';

class CategoryService {
  final Dio _dio = ApiClient.instance;

  /// GET /categories — lista todas las categorías disponibles.
  Future<List<Category>> getAll() async {
    final response = await _dio.get('/categories');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /categories — crea una categoría nueva (p. ej. un tipo de comida
  /// que no estaba contemplado) y devuelve la categoría creada.
  Future<Category> create(String name) async {
    final response = await _dio.post('/categories', data: {'name': name});
    return Category.fromJson(response.data as Map<String, dynamic>);
  }
}
