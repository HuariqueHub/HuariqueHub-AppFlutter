class Huarique {
  final int id;
  final String name;
  final String category;
  final String district;
  final double rating;
  final int reviewCount;
  final double price;
  final String? description;
  final String? address;
  final String? imageUrl;
  final int ownerId;
  final bool hasPromo;

  const Huarique({
    required this.id,
    required this.name,
    required this.category,
    required this.district,
    required this.rating,
    required this.reviewCount,
    required this.price,
    this.description,
    this.address,
    this.imageUrl,
    required this.ownerId,
    this.hasPromo = false,
  });

  factory Huarique.fromJson(Map<String, dynamic> json) => Huarique(
        id: json['id'] as int,
        name: json['name'] as String,
        category: json['category'] as String? ?? '',
        district: json['district'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: json['reviewCount'] as int? ?? 0,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        description: json['description'] as String?,
        address: json['address'] as String?,
        imageUrl: json['imageUrl'] as String?,
        ownerId: json['ownerId'] as int? ?? 0,
        hasPromo: json['hasPromo'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'district': district,
        'price': price,
        'description': description,
        'address': address,
        'ownerId': ownerId,
      };
}
