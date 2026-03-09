class Vendor {
  final String id;
  final String? projectId;
  final String name;
  final String? companyName;
  final String? email;
  final String? phone;
  final String? location;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Backward-compatible aliases for older page code.
  String? get contactPerson => null;
  String? get address => location;
  String? get type => null;
  double? get rating => null;
  String? get gstNo => null;
  String? get panNo => null;

  const Vendor({
    required this.id,
    this.projectId,
    required this.name,
    this.companyName,
    this.email,
    this.phone,
    this.location,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: (json['vendor_id'] ?? json['id'] ?? '').toString(),
      projectId: json['project_id']?.toString(),
      name: (json['vendor_name'] ?? json['name'] ?? '').toString(),
      companyName: json['vendor_company_name']?.toString(),
      email: (json['vendor_email'] ?? json['email'])?.toString(),
      phone: (json['mobile_number'] ?? json['phone'])?.toString(),
      location: (json['location'] ?? json['address'])?.toString(),
      status: (json['status'] ?? 'active').toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'vendor_id': id,
    'project_id': projectId,
    'vendor_name': name,
    'vendor_company_name': companyName,
    'vendor_email': email,
    'mobile_number': phone,
    'location': location,
    'status': status,
    // Legacy aliases to support old backend payloads if needed.
    'name': name,
    'email': email,
    'phone': phone,
    'address': location,
  };

  Vendor copyWith({
    String? id,
    String? projectId,
    String? name,
    String? companyName,
    String? email,
    String? phone,
    String? location,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vendor(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      companyName: companyName ?? this.companyName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isActive => status.toLowerCase() == 'active';
}
