class Material {
  final String id;
  final String code;
  final String name;
  final String? category;
  final String unit;
  final double? stock;
  final double? minStock;
  final double? maxStock;
  final String? location;
  final DateTime? createdAt;

  const Material({
    required this.id,
    required this.code,
    required this.name,
    this.category,
    required this.unit,
    this.stock,
    this.minStock,
    this.maxStock,
    this.location,
    this.createdAt,
  });

  factory Material.fromJson(Map<String, dynamic> json) {
    return Material(
      id: (json['material_id'] ?? json['id'] ?? '').toString(),
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      category: json['category'],
      unit: json['unit'] ?? '',
      stock: json['stock'] != null ? (json['stock'] as num).toDouble() : null,
      minStock: json['min_stock'] != null ? (json['min_stock'] as num).toDouble() : null,
      maxStock: json['max_stock'] != null ? (json['max_stock'] as num).toDouble() : null,
      location: json['location'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'material_id': id,
    'code': code,
    'name': name,
    'category': category,
    'unit': unit,
    'stock': stock,
    'min_stock': minStock,
    'max_stock': maxStock,
    'location': location,
  };

  bool get isLowStock => stock != null && minStock != null && stock! <= minStock!;
}
