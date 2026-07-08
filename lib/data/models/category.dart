/// Categoría de huarique (p. ej. "Cevichería", "Pollería").
///
/// Se usa para clasificar y filtrar los huariques que expone el backend.
class Category {
  /// Identificador único de la categoría en el backend.
  final int id;

  /// Nombre visible de la categoría.
  final String name;

  const Category({required this.id, required this.name});

  /// Construye una [Category] a partir del JSON devuelto por `/categories`.
  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as int,
        name: json['name'] as String,
      );
}
