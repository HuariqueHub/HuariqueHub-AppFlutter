class Subscription {
  final int id;
  final int userId;
  final String planId;
  final String? planName;
  final double? planPrice;
  final String status;
  final bool isActive;
  final String startDate;
  final String? endDate;

  const Subscription({
    required this.id,
    required this.userId,
    required this.planId,
    this.planName,
    this.planPrice,
    required this.status,
    required this.isActive,
    required this.startDate,
    this.endDate,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        id: json['id'] as int,
        userId: json['userId'] as int,
        planId: json['planId'] as String,
        planName: json['planName'] as String?,
        planPrice: (json['planPrice'] as num?)?.toDouble(),
        status: json['status'] as String? ?? 'active',
        isActive: json['isActive'] as bool? ?? false,
        startDate: json['startDate'] as String? ?? '',
        endDate: json['endDate'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'planId': planId,
        'endDate': endDate,
      };
}
