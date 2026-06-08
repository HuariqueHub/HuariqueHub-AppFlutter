class Promo {
  final int id;
  final int? huariqueId;
  final String title;
  final String? note;
  final String type;
  final int? discount;
  final String? code;
  final String? startDate;
  final String? endDate;
  final int? maxUses;
  final bool isActive;

  const Promo({
    required this.id,
    this.huariqueId,
    required this.title,
    this.note,
    required this.type,
    this.discount,
    this.code,
    this.startDate,
    this.endDate,
    this.maxUses,
    this.isActive = true,
  });

  factory Promo.fromJson(Map<String, dynamic> json) => Promo(
        id: json['id'] as int,
        huariqueId: json['huariqueId'] as int?,
        title: json['title'] as String,
        note: json['note'] as String?,
        type: json['type'] as String? ?? 'otro',
        discount: json['discount'] as int?,
        code: json['code'] as String?,
        startDate: json['startDate'] as String?,
        endDate: json['endDate'] as String?,
        maxUses: json['maxUses'] as int?,
        isActive: json['isActive'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'huariqueId': huariqueId,
        'title': title,
        'note': note,
        'type': type,
        'discount': discount,
        'code': code,
        'startDate': startDate,
        'endDate': endDate,
        'maxUses': maxUses,
      };
}
