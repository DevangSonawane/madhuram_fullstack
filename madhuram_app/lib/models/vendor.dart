class Vendor {
  final String id;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final String status;
  final String? type; // Vendor, Customer, Service Provider
  final double? rating;
  final String? gstNo;
  final String? panNo;
  final DateTime? createdAt;

  const Vendor({
    required this.id,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.status = 'Active',
    this.type,
    this.rating,
    this.gstNo,
    this.panNo,
    this.createdAt,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: (json['vendor_id'] ?? json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      contactPerson: json['contact_person'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      status: json['status'] ?? 'Active',
      type: json['type'],
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      gstNo: json['gst_no'],
      panNo: json['pan_no'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'vendor_id': id,
    'name': name,
    'contact_person': contactPerson,
    'phone': phone,
    'email': email,
    'address': address,
    'status': status,
    'type': type,
    'rating': rating,
    'gst_no': gstNo,
    'pan_no': panNo,
  };

  Vendor copyWith({
    String? id,
    String? name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? status,
    String? type,
    double? rating,
    String? gstNo,
    String? panNo,
  }) {
    return Vendor(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      status: status ?? this.status,
      type: type ?? this.type,
      rating: rating ?? this.rating,
      gstNo: gstNo ?? this.gstNo,
      panNo: panNo ?? this.panNo,
      createdAt: createdAt,
    );
  }

  bool get isActive => status == 'Active';
}
