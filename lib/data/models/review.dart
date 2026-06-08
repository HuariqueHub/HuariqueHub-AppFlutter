class Review {
  final int id;
  final int huariqueId;
  final int userId;
  final String? userName;
  final int rating;
  final String? comment;
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

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as int,
        huariqueId: json['huariqueId'] as int,
        userId: json['userId'] as int,
        userName: json['userName'] as String?,
        rating: json['rating'] as int? ?? 5,
        comment: json['comment'] as String?,
        createdAt: json['createdAt'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'huariqueId': huariqueId,
        'userId': userId,
        'rating': rating,
        'comment': comment,
      };
}
