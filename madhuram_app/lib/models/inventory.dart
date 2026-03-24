class InventoryItem {
  final String id;
  final String projectId;
  final String brand;
  final String name;
  final double quantity;
  final double price;
  final String unit;
  final double width;
  final double height;
  final bool stockIn;
  final bool billing;

  const InventoryItem({
    required this.id,
    required this.projectId,
    required this.brand,
    required this.name,
    required this.quantity,
    required this.price,
    required this.unit,
    required this.width,
    required this.height,
    required this.stockIn,
    required this.billing,
  });

  double get value => quantity * price;

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final id = json['inventory_id']?.toString() ?? json['id']?.toString() ?? '';
    final projectId = json['project_id']?.toString() ?? '';
    return InventoryItem(
      id: id,
      projectId: projectId,
      brand: (json['brand'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      quantity: (json['quantity'] is num)
          ? (json['quantity'] as num).toDouble()
          : double.tryParse(json['quantity']?.toString() ?? '') ?? 0.0,
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      unit: (json['units'] ?? json['unit'] ?? '').toString(),
      width: (json['width'] is num)
          ? (json['width'] as num).toDouble()
          : double.tryParse(json['width']?.toString() ?? '') ?? 0.0,
      height: (json['height'] is num)
          ? (json['height'] as num).toDouble()
          : double.tryParse(json['height']?.toString() ?? '') ?? 0.0,
      stockIn: json['stockin'] == true || json['stockin']?.toString() == 'true',
      billing: json['billing'] == true || json['billing']?.toString() == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inventory_id': id,
      'project_id': projectId,
      'brand': brand,
      'name': name,
      'quantity': quantity,
      'price': price,
      'units': unit,
      'width': width,
      'height': height,
      'stockin': stockIn,
      'billing': billing,
    };
  }
}
