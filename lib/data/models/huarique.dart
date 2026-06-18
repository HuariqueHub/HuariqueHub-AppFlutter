class Huarique {
  final int id;
  final String name;
  final String category;
  final int categoryId;
  final String district;
  final double rating;
  final int reviewCount;
  final double price;
  final String? description;
  final String? address;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final int ownerId;
  final bool hasPromo;

  const Huarique({
    required this.id,
    required this.name,
    required this.category,
    this.categoryId = 0,
    required this.district,
    required this.rating,
    required this.reviewCount,
    required this.price,
    this.description,
    this.address,
    this.imageUrl,
    this.latitude,
    this.longitude,
    required this.ownerId,
    this.hasPromo = false,
  });

  /// True cuando el huarique tiene coordenadas para mostrar en el mapa.
  bool get hasLocation => latitude != null && longitude != null;

  factory Huarique.fromJson(Map<String, dynamic> json) => Huarique(
        id: json['id'] as int,
        name: json['name'] as String,
        category: json['category'] as String? ?? '',
        categoryId: json['categoryId'] as int? ?? 0,
        district: json['district'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: json['reviewCount'] as int? ?? 0,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        description: json['description'] as String?,
        address: json['address'] as String?,
        imageUrl: json['imageUrl'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        ownerId: json['ownerId'] as int? ?? 0,
        hasPromo: json['hasPromo'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'categoryId': categoryId,
        'district': district,
        'price': price,
        'description': description,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'ownerId': ownerId,
      };
}
