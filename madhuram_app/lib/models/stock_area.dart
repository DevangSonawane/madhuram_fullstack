class StockArea {
  final String id;
  final String name;
  final String? location;
  final double? capacity;
  final double? currentStock;
  final String? description;
  final DateTime? createdAt;

  const StockArea({
    required this.id,
    required this.name,
    this.location,
    this.capacity,
    this.currentStock,
    this.description,
    this.createdAt,
  });

  factory StockArea.fromJson(Map<String, dynamic> json) {
    return StockArea(
      id: (json['area_id'] ?? json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      location: json['location'],
      capacity: json['capacity'] != null ? (json['capacity'] as num).toDouble() : null,
      currentStock: json['current_stock'] != null ? (json['current_stock'] as num).toDouble() : null,
      description: json['description'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'area_id': id,
    'name': name,
    'location': location,
    'capacity': capacity,
    'current_stock': currentStock,
    'description': description,
  };

  double get utilizationPercent {
    if (capacity == null || capacity == 0 || currentStock == null) return 0;
    return (currentStock! / capacity!) * 100;
  }
}

class StockTransfer {
  final String id;
  final String fromArea;
  final String toArea;
  final String material;
  final double quantity;
  final String? date;
  final String status;

  const StockTransfer({
    required this.id,
    required this.fromArea,
    required this.toArea,
    required this.material,
    required this.quantity,
    this.date,
    this.status = 'Pending',
  });

  factory StockTransfer.fromJson(Map<String, dynamic> json) {
    return StockTransfer(
      id: (json['transfer_id'] ?? json['id'] ?? '').toString(),
      fromArea: json['from_area'] ?? '',
      toArea: json['to_area'] ?? '',
      material: json['material'] ?? '',
      quantity: json['quantity'] != null ? (json['quantity'] as num).toDouble() : 0,
      date: json['date'],
      status: json['status'] ?? 'Pending',
    );
  }

  Map<String, dynamic> toJson() => {
    'transfer_id': id,
    'from_area': fromArea,
    'to_area': toArea,
    'material': material,
    'quantity': quantity,
    'date': date,
    'status': status,
  };
}

class Consumption {
  final String id;
  final String material;
  final double quantity;
  final String unit;
  final String? date;
  final String? floor;
  final String? remarks;

  const Consumption({
    required this.id,
    required this.material,
    required this.quantity,
    required this.unit,
    this.date,
    this.floor,
    this.remarks,
  });

  factory Consumption.fromJson(Map<String, dynamic> json) {
    return Consumption(
      id: (json['consumption_id'] ?? json['id'] ?? '').toString(),
      material: json['material'] ?? '',
      quantity: json['quantity'] != null ? (json['quantity'] as num).toDouble() : 0,
      unit: json['unit'] ?? '',
      date: json['date'],
      floor: json['floor'],
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toJson() => {
    'consumption_id': id,
    'material': material,
    'quantity': quantity,
    'unit': unit,
    'date': date,
    'floor': floor,
    'remarks': remarks,
  };
}

class Return {
  final String id;
  final String material;
  final double quantity;
  final String reason;
  final String? date;
  final String status;

  const Return({
    required this.id,
    required this.material,
    required this.quantity,
    required this.reason,
    this.date,
    this.status = 'Pending',
  });

  factory Return.fromJson(Map<String, dynamic> json) {
    return Return(
      id: (json['return_id'] ?? json['id'] ?? '').toString(),
      material: json['material'] ?? '',
      quantity: json['quantity'] != null ? (json['quantity'] as num).toDouble() : 0,
      reason: json['reason'] ?? '',
      date: json['date'],
      status: json['status'] ?? 'Pending',
    );
  }

  Map<String, dynamic> toJson() => {
    'return_id': id,
    'material': material,
    'quantity': quantity,
    'reason': reason,
    'date': date,
    'status': status,
  };
}
