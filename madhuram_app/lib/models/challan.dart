class Challan {
  final String id;
  final String? projectId;
  final String challanNumber;
  final String? poId;
  final String? poNumber;
  final String? challanDate;
  final String? workOrderNumber;
  final String? orderDate;
  final int? totalPoItems;
  final int? totalChallanItems;
  final String status;
  final List<ChallanItem> items;
  final DateTime? createdAt;

  const Challan({
    required this.id,
    this.projectId,
    required this.challanNumber,
    this.poId,
    this.poNumber,
    this.challanDate,
    this.workOrderNumber,
    this.orderDate,
    this.totalPoItems,
    this.totalChallanItems,
    this.status = 'incomplete',
    this.items = const [],
    this.createdAt,
  });

  factory Challan.fromJson(Map<String, dynamic> json) {
    final dynamic rawItems = json['items'];
    final List<dynamic> itemsJson = rawItems is List ? rawItems : <dynamic>[];
    final int? totalChallanItems = json['total_challan_items'] is int
        ? json['total_challan_items'] as int
        : (rawItems is List ? rawItems.length : null);

    return Challan(
      id: (json['dc_id'] ?? json['challan_id'] ?? json['id'] ?? '').toString(),
      projectId: json['project_id']?.toString(),
      challanNumber: json['challan_number'] ?? json['challan_no'] ?? '',
      poId: json['po_id']?.toString(),
      poNumber: json['po_number']?.toString(),
      challanDate: json['challan_date']?.toString() ?? json['date']?.toString(),
      workOrderNumber: json['work_order_number']?.toString(),
      orderDate: json['order_date']?.toString(),
      totalPoItems: json['total_po_items'] is int ? json['total_po_items'] as int : int.tryParse(json['total_po_items']?.toString() ?? ''),
      totalChallanItems: totalChallanItems,
      status: json['status'] ?? 'incomplete',
      items: itemsJson.map((e) => ChallanItem.fromJson(e as Map<String, dynamic>)).toList(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'dc_id': id,
    'project_id': projectId,
    'challan_number': challanNumber,
    'po_id': poId,
    'po_number': poNumber,
    'challan_date': challanDate,
    'work_order_number': workOrderNumber,
    'order_date': orderDate,
    'total_po_items': totalPoItems,
    'total_challan_items': totalChallanItems,
    'items': items.map((e) => e.toJson()).toList(),
    'status': status,
  };

  String get displayChallanDate => challanDate ?? orderDate ?? '';
}

class ChallanItem {
  final String name;
  final String description;
  final String width;
  final String length;
  final String quantity;
  final String price;

  const ChallanItem({
    required this.name,
    required this.description,
    required this.width,
    required this.length,
    required this.quantity,
    required this.price,
  });

  factory ChallanItem.fromJson(Map<String, dynamic> json) {
    return ChallanItem(
      name: json['name']?.toString() ?? json['material']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      width: json['width']?.toString() ?? '',
      length: json['length']?.toString() ?? '',
      quantity: json['quantity']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'width': double.tryParse(width) ?? 0,
    'length': double.tryParse(length) ?? 0,
    'quantity': double.tryParse(quantity) ?? 0,
    'price': double.tryParse(price) ?? 0,
  };
}
