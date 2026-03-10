class VendorPriceList {
  final String id;
  final String vendorId;
  final String versionName;
  final String status;
  final String? filePath;
  final String? filename;
  final int itemsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VendorPriceList({
    required this.id,
    required this.vendorId,
    required this.versionName,
    required this.status,
    this.filePath,
    this.filename,
    this.itemsCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory VendorPriceList.fromJson(Map<String, dynamic> json) {
    return VendorPriceList(
      id: (json['price_list_id'] ?? json['id'] ?? '').toString(),
      vendorId: (json['vendor_id'] ?? '').toString(),
      versionName: (json['version_name'] ?? 'Untitled').toString(),
      status: (json['status'] ?? 'active').toString(),
      filePath: (json['file_path'] ?? json['path'] ?? json['url'])?.toString(),
      filename: json['filename']?.toString(),
      itemsCount: int.tryParse('${json['items_count'] ?? 0}') ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}
