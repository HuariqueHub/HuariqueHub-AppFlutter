/// Estado operativo de un huarique (US20/US22). Se calcula en el cliente a
/// partir de los campos openAt/closeAt ("HH:mm") que expone el backend.
enum OpenStatus {
  open('Abierto ahora'),
  closed('Cerrado'),
  unknown('Estado no confirmado');

  const OpenStatus(this.label);
  final String label;
}

/// Devuelve el estado abierto/cerrado comparando la hora actual con el rango
/// [openAt, closeAt]. Soporta rangos que cruzan medianoche (20:00–02:00).
OpenStatus computeOpenStatus(String? openAt, String? closeAt) {
  final open = _parseMinutes(openAt);
  final close = _parseMinutes(closeAt);
  if (open == null || close == null) return OpenStatus.unknown;

  final now = DateTime.now();
  final nowMinutes = now.hour * 60 + now.minute;

  final isOpen = close > open
      ? (nowMinutes >= open && nowMinutes < close) // mismo día
      : (nowMinutes >= open || nowMinutes < close); // cruza medianoche
  return isOpen ? OpenStatus.open : OpenStatus.closed;
}

/// Convierte "HH:mm" (o "H:mm", "HH:mm:ss") a minutos desde medianoche.
int? _parseMinutes(String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) return null;
  final parts = raw.split(':');
  final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '');
  if (hour == null) return null;
  final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return hour * 60 + minute;
}

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
  // Horario crudo (HH:mm) para calcular el estado Abierto/Cerrado (US20/US22).
  final String? openAt;
  final String? closeAt;

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
    this.openAt,
    this.closeAt,
  });

  /// True cuando el huarique tiene coordenadas para mostrar en el mapa.
  bool get hasLocation => latitude != null && longitude != null;

  /// Estado operativo calculado a partir de openAt/closeAt (US20/US22).
  OpenStatus get openStatus => computeOpenStatus(openAt, closeAt);

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
        openAt: json['openAt'] as String?,
        closeAt: json['closeAt'] as String?,
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
