class Plan {
  final String id;
  final String name;
  final double price;
  final List<String> features;

  const Plan({
    required this.id,
    required this.name,
    required this.price,
    required this.features,
  });

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
        id: json['id'] as String,
        name: json['name'] as String,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        features: (json['features'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );
}
