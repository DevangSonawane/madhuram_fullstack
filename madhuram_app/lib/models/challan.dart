class Challan {
  final String id;
  final String? projectId;
  final String challanNo;
  final String vendor;
  final String? date;
  final int? itemCount;
  final String status;
  final List<ChallanItem>? items;
  final DateTime? createdAt;

  const Challan({
    required this.id,
    this.projectId,
    required this.challanNo,
    required this.vendor,
    this.date,
    this.itemCount,
    this.status = 'Pending',
    this.items,
    this.createdAt,
  });

  factory Challan.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List?;
    
    return Challan(
      id: (json['challan_id'] ?? json['id'] ?? '').toString(),
      projectId: json['project_id']?.toString(),
      challanNo: json['challan_no'] ?? '',
      vendor: json['vendor'] ?? '',
      date: json['date'],
      itemCount: json['items'] is int ? json['items'] : itemsJson?.length,
      status: json['status'] ?? 'Pending',
      items: itemsJson?.map((e) => ChallanItem.fromJson(e)).toList(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'challan_id': id,
    'project_id': projectId,
    'challan_no': challanNo,
    'vendor': vendor,
    'date': date,
    'items': items?.map((e) => e.toJson()).toList() ?? itemCount,
    'status': status,
  };
}

class ChallanItem {
  final String material;
  final double quantity;
  final String unit;
  final String? remarks;

  const ChallanItem({
    required this.material,
    required this.quantity,
    required this.unit,
    this.remarks,
  });

  factory ChallanItem.fromJson(Map<String, dynamic> json) {
    return ChallanItem(
      material: json['material'] ?? '',
      quantity: json['quantity'] != null ? (json['quantity'] as num).toDouble() : 0,
      unit: json['unit'] ?? '',
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toJson() => {
    'material': material,
    'quantity': quantity,
    'unit': unit,
    'remarks': remarks,
  };
}
