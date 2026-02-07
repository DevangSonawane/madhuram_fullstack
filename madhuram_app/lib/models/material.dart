class Material {
  final String id;
  final String code;
  final String name;
  final String? category;
  final String unit;
  final double? stock;
  final double? minStock;
  final double? maxStock;
  final double? unitPrice;
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
    this.unitPrice,
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
      unitPrice: json['unit_price'] != null ? (json['unit_price'] as num).toDouble() : (json['price'] != null ? (json['price'] as num).toDouble() : null),
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
    'unit_price': unitPrice,
    'location': location,
  };

  bool get isLowStock => stock != null && minStock != null && stock! <= minStock!;

  Material copyWith({
    String? id,
    String? code,
    String? name,
    String? category,
    String? unit,
    double? stock,
    double? minStock,
    double? maxStock,
    double? unitPrice,
    String? location,
    DateTime? createdAt,
  }) {
    return Material(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      maxStock: maxStock ?? this.maxStock,
      unitPrice: unitPrice ?? this.unitPrice,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
