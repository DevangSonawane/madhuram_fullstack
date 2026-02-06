class BOQItem {
  final String id;
  final String? projectId;
  final String? itemCode;
  final String category;
  final String description;
  final String? floor;
  final String unit;
  final double quantity;
  final double? rate;
  final double? amount;
  final String? boqFile;
  final DateTime? createdAt;

  const BOQItem({
    required this.id,
    this.projectId,
    this.itemCode,
    required this.category,
    required this.description,
    this.floor,
    required this.unit,
    required this.quantity,
    this.rate,
    this.amount,
    this.boqFile,
    this.createdAt,
  });

  factory BOQItem.fromJson(Map<String, dynamic> json) {
    return BOQItem(
      id: (json['boq_id'] ?? json['id'] ?? '').toString(),
      projectId: json['project_id']?.toString(),
      itemCode: json['item_code'] ?? json['code'],
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      floor: json['floor'],
      unit: json['unit'] ?? '',
      quantity: _parseDouble(json['quantity']),
      rate: json['rate'] != null ? _parseDouble(json['rate']) : null,
      amount: json['amount'] != null ? _parseDouble(json['amount']) : null,
      boqFile: json['boq_file'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'boq_id': id,
    'project_id': projectId,
    'item_code': itemCode,
    'category': category,
    'description': description,
    'floor': floor,
    'unit': unit,
    'quantity': quantity,
    'rate': rate,
    'amount': amount,
    'boq_file': boqFile,
  };

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  BOQItem copyWith({
    String? id,
    String? projectId,
    String? itemCode,
    String? category,
    String? description,
    String? floor,
    String? unit,
    double? quantity,
    double? rate,
    double? amount,
    String? boqFile,
  }) {
    return BOQItem(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      itemCode: itemCode ?? this.itemCode,
      category: category ?? this.category,
      description: description ?? this.description,
      floor: floor ?? this.floor,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      amount: amount ?? this.amount,
      boqFile: boqFile ?? this.boqFile,
      createdAt: createdAt,
    );
  }
}
