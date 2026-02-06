/// Alias for backward compatibility
typedef Bill = BillingRecord;

class BillingRecord {
  final String id;
  final String? projectId;
  final String invoiceNo;
  final String amount;
  final String? date;
  final String status;
  final String? description;
  final String? vendor;
  final DateTime? createdAt;

  const BillingRecord({
    required this.id,
    this.projectId,
    required this.invoiceNo,
    required this.amount,
    this.date,
    this.status = 'Pending',
    this.description,
    this.vendor,
    this.createdAt,
  });

  factory BillingRecord.fromJson(Map<String, dynamic> json) {
    return BillingRecord(
      id: (json['bill_id'] ?? json['id'] ?? '').toString(),
      projectId: json['project_id']?.toString(),
      invoiceNo: json['invoice_no'] ?? '',
      amount: json['amount']?.toString() ?? '',
      date: json['date'],
      status: json['status'] ?? 'Pending',
      description: json['description'],
      vendor: json['vendor'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'bill_id': id,
    'project_id': projectId,
    'invoice_no': invoiceNo,
    'amount': amount,
    'date': date,
    'status': status,
    'description': description,
    'vendor': vendor,
  };

  bool get isPending => status == 'Pending';
  bool get isPaid => status == 'Paid';
}
