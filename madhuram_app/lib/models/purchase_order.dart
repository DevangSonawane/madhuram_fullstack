class PurchaseOrderItem {
  final String srNo;
  final String? hsnCode;
  final String description;
  final String quantity;
  final String uom;
  final String rate;
  final String amount;
  final String? remarks;

  const PurchaseOrderItem({
    required this.srNo,
    this.hsnCode,
    required this.description,
    required this.quantity,
    required this.uom,
    required this.rate,
    required this.amount,
    this.remarks,
  });

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderItem(
      srNo: json['srNo']?.toString() ?? '',
      hsnCode: json['hsnCode']?.toString(),
      description: json['description'] ?? '',
      quantity: json['qty']?.toString() ?? json['quantity']?.toString() ?? '',
      uom: json['uom'] ?? '',
      rate: json['rate']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '',
      remarks: json['remarks'],
    );
  }

  /// toJson with correct field names matching React API
  Map<String, dynamic> toJson() => {
    'srno': srNo,
    'hsn': hsnCode,
    'description': description,
    'qty': quantity,
    'UOM': uom,
    'Rate': rate,
    'Amount': amount,
    'remark': remarks,
  };
}

class PurchaseOrderVendor {
  final String name;
  final String? site;
  final String? address;
  final String? contactPerson;
  final Map<String, dynamic>? contacts;

  const PurchaseOrderVendor({
    required this.name,
    this.site,
    this.address,
    this.contactPerson,
    this.contacts,
  });

  factory PurchaseOrderVendor.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderVendor(
      name: json['name'] ?? '',
      site: json['site'],
      address: json['address'],
      contactPerson: json['contactPerson'],
      contacts: json['contacts'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'site': site,
    'address': address,
    'contactPerson': contactPerson,
    'contacts': contacts,
  };
}

class PurchaseOrder {
  final String id;
  final String? projectId;
  final String orderNo;
  final String? poDate;
  final String? indentNo;
  final String? indentDate;
  final String? companyName;
  final String? companySubtitle;
  final String? companyAddress;
  final String? companyEmail;
  final String? companyGstNo;
  final PurchaseOrderVendor? vendor;
  final List<PurchaseOrderItem> items;
  final String? discountPercent;
  final String? discountAmount;
  final String? afterDiscountAmount;
  final String? cgstPercent;
  final String? cgstAmount;
  final String? sgstPercent;
  final String? sgstAmount;
  final String? totalAmount;
  final String? delivery;
  final String? payment;
  final List<String>? notes;
  final List<String>? termsAndConditions;
  final String status;
  final String? source;
  final String? sourceFileName;

  const PurchaseOrder({
    required this.id,
    this.projectId,
    required this.orderNo,
    this.poDate,
    this.indentNo,
    this.indentDate,
    this.companyName,
    this.companySubtitle,
    this.companyAddress,
    this.companyEmail,
    this.companyGstNo,
    this.vendor,
    this.items = const [],
    this.discountPercent,
    this.discountAmount,
    this.afterDiscountAmount,
    this.cgstPercent,
    this.cgstAmount,
    this.sgstPercent,
    this.sgstAmount,
    this.totalAmount,
    this.delivery,
    this.payment,
    this.notes,
    this.termsAndConditions,
    this.status = 'Draft',
    this.source,
    this.sourceFileName,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    final vendorJson = json['vendor'] as Map<String, dynamic>?;
    final itemsJson = json['items'] as List?;
    final discountJson = json['discount'] as Map<String, dynamic>?;
    final taxesJson = json['taxes'] as Map<String, dynamic>?;
    final summaryJson = json['summary'] as Map<String, dynamic>?;

    return PurchaseOrder(
      id: (json['po_id'] ?? json['id'] ?? '').toString(),
      projectId: json['project_id']?.toString(),
      orderNo: json['order_no'] ?? json['orderNo'] ?? '',
      poDate: json['po_date'] ?? json['poDate'],
      indentNo: json['indent_no'] ?? json['indentNo'],
      indentDate: json['indent_date'] ?? json['indentDate'],
      companyName: json['companyName'],
      companySubtitle: json['companySubtitle'],
      companyAddress: json['companyAddress'],
      companyEmail: json['companyEmail'],
      companyGstNo: json['companyGstNo'],
      vendor: vendorJson != null ? PurchaseOrderVendor.fromJson(vendorJson) : null,
      items: itemsJson?.map((e) => PurchaseOrderItem.fromJson(e)).toList() ?? [],
      discountPercent: discountJson?['percent']?.toString(),
      discountAmount: discountJson?['amount']?.toString(),
      afterDiscountAmount: json['afterDiscountAmount']?.toString(),
      cgstPercent: taxesJson?['cgst']?['percent']?.toString(),
      cgstAmount: taxesJson?['cgst']?['amount']?.toString(),
      sgstPercent: taxesJson?['sgst']?['percent']?.toString(),
      sgstAmount: taxesJson?['sgst']?['amount']?.toString(),
      totalAmount: json['total_amount']?.toString() ?? json['totalAmount']?.toString(),
      delivery: summaryJson?['delivery'],
      payment: summaryJson?['payment'],
      notes: json['notes'] != null ? List<String>.from(json['notes']) : null,
      termsAndConditions: json['termsAndConditions'] != null
          ? List<String>.from(json['termsAndConditions'])
          : null,
      status: json['status'] ?? 'Draft',
      source: json['source'],
      sourceFileName: json['sourceFileName'],
    );
  }

  /// Convenience getter for vendor name
  String? get vendorName => vendor?.name;

  /// Parse totalAmount as double for calculations
  double? get totalAmountValue => double.tryParse(totalAmount ?? '');

  Map<String, dynamic> toJson() => {
    'po_id': id,
    'project_id': projectId,
    'order_no': orderNo,
    'po_date': poDate,
    'indent_no': indentNo,
    'indent_date': indentDate,
    'companyName': companyName,
    'companySubtitle': companySubtitle,
    'companyAddress': companyAddress,
    'companyEmail': companyEmail,
    'companyGstNo': companyGstNo,
    'vendor': vendor?.toJson(),
    'items': items.map((e) => e.toJson()).toList(),
    'discount': {
      'percent': discountPercent,
      'amount': discountAmount,
    },
    'afterDiscountAmount': afterDiscountAmount,
    'taxes': {
      'cgst': {'percent': cgstPercent, 'amount': cgstAmount},
      'sgst': {'percent': sgstPercent, 'amount': sgstAmount},
    },
    'total_amount': totalAmount,
    'summary': {
      'delivery': delivery,
      'payment': payment,
    },
    'notes': notes,
    'termsAndConditions': termsAndConditions,
    'status': status,
    'source': source,
    'sourceFileName': sourceFileName,
  };
}
