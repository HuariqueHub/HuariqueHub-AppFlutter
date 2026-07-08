/// Reseña que un usuario deja sobre un huarique (calificación y comentario).
class Review {
  /// Identificador único de la reseña en el backend.
  final int id;

  /// Id del huarique reseñado.
  final int huariqueId;

  /// Id del usuario autor de la reseña.
  final int userId;

  /// Nombre del autor, cuando el backend lo incluye.
  final String? userName;

  /// Puntuación otorgada (rango 1–5).
  final int rating;

  /// Comentario opcional del usuario.
  final String? comment;

  /// Fecha de creación en formato ISO-8601, si está disponible.
  final String? createdAt;

  const Review({
    required this.id,
    required this.huariqueId,
    required this.userId,
    this.userName,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  /// Construye una [Review] a partir del JSON devuelto por `/reviews`.
  ///
  /// Si el backend no envía `rating`, se asume 5 como valor por defecto.
  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as int,
        huariqueId: json['huariqueId'] as int,
        userId: json['userId'] as int,
        userName: json['userName'] as String?,
        rating: json['rating'] as int? ?? 5,
        comment: json['comment'] as String?,
        createdAt: json['createdAt'] as String?,
      );

  /// Serializa la reseña al formato que espera el backend al crearla.
  Map<String, dynamic> toJson() => {
        'huariqueId': huariqueId,
        'userId': userId,
        'rating': rating,
        'comment': comment,
      };
}
