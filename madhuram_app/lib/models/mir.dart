class MIR {
  final String id;
  final String? projectId;
  final String mirRefNo;
  final String? materialCode;
  final String? clientName;
  final String? pmc;
  final String? contractor;
  final String? vendorCode;
  final List<String>? referenceDocsAttached;
  final Map<String, dynamic>? dynamicField;
  final String? status;
  final DateTime? createdAt;
  // Additional fields from React API
  final String? projectName;
  final String? projectCode;
  final String? inspectionDateTime;
  final String? clientSubmissionDate;
  final bool? mirSubmitted;
  final String? source;
  final String? sourceFileName;

  const MIR({
    required this.id,
    this.projectId,
    required this.mirRefNo,
    this.materialCode,
    this.clientName,
    this.pmc,
    this.contractor,
    this.vendorCode,
    this.referenceDocsAttached,
    this.dynamicField,
    this.status,
    this.createdAt,
    this.projectName,
    this.projectCode,
    this.inspectionDateTime,
    this.clientSubmissionDate,
    this.mirSubmitted,
    this.source,
    this.sourceFileName,
  });

  factory MIR.fromJson(Map<String, dynamic> json) {
    final dynamicFieldJson = json['dynamic_field'] as Map<String, dynamic>?;
    return MIR(
      id: (json['mir_id'] ?? json['id'] ?? '').toString(),
      projectId: json['project_id']?.toString(),
      mirRefNo: json['mir_refrence_no'] ?? json['mir_ref_no'] ?? '',
      materialCode: json['material_code'],
      clientName: json['client_name'],
      pmc: json['pmc'],
      contractor: json['contractor'],
      vendorCode: json['vendor_code'],
      referenceDocsAttached: json['refrence_docs_attached'] != null
          ? List<String>.from(json['refrence_docs_attached'])
          : null,
      dynamicField: dynamicFieldJson,
      status: json['status'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      projectName: json['project_name'],
      projectCode: json['project_code'],
      inspectionDateTime: json['inspection_date_time'],
      clientSubmissionDate: json['client_submission_date'],
      mirSubmitted: json['mir_submited'] == true || json['mir_submited'] == 'true',
      source: json['source'],
      sourceFileName: json['source_file_name'],
    );
  }

  /// Get inspection engineer from dynamic_field
  String? get inspectionEngineer => dynamicField?['inspection_engineer'] as String?;

  /// Get mir submitted to from dynamic_field
  String? get mirSubmittedTo => dynamicField?['mir_submitted_to'] as String?;

  /// Alias for mirRefNo for backward compatibility
  String get mirReferenceNo => mirRefNo;

  Map<String, dynamic> toJson() => {
    'mir_id': id,
    'project_id': projectId,
    'mir_refrence_no': mirRefNo,
    'material_code': materialCode,
    'client_name': clientName,
    'pmc': pmc,
    'contractor': contractor,
    'vendor_code': vendorCode,
    'refrence_docs_attached': referenceDocsAttached,
    'dynamic_field': dynamicField,
    'status': status,
    'project_name': projectName,
    'project_code': projectCode,
    'inspection_date_time': inspectionDateTime,
    'client_submission_date': clientSubmissionDate,
    'mir_submited': mirSubmitted,
    'source': source,
    'source_file_name': sourceFileName,
  };

  MIR copyWith({
    String? id,
    String? projectId,
    String? mirRefNo,
    String? materialCode,
    String? clientName,
    String? pmc,
    String? contractor,
    String? vendorCode,
    List<String>? referenceDocsAttached,
    Map<String, dynamic>? dynamicField,
    String? status,
    String? projectName,
    String? projectCode,
    String? inspectionDateTime,
    String? clientSubmissionDate,
    bool? mirSubmitted,
    String? source,
    String? sourceFileName,
  }) {
    return MIR(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      mirRefNo: mirRefNo ?? this.mirRefNo,
      materialCode: materialCode ?? this.materialCode,
      clientName: clientName ?? this.clientName,
      pmc: pmc ?? this.pmc,
      contractor: contractor ?? this.contractor,
      vendorCode: vendorCode ?? this.vendorCode,
      referenceDocsAttached: referenceDocsAttached ?? this.referenceDocsAttached,
      dynamicField: dynamicField ?? this.dynamicField,
      status: status ?? this.status,
      createdAt: createdAt,
      projectName: projectName ?? this.projectName,
      projectCode: projectCode ?? this.projectCode,
      inspectionDateTime: inspectionDateTime ?? this.inspectionDateTime,
      clientSubmissionDate: clientSubmissionDate ?? this.clientSubmissionDate,
      mirSubmitted: mirSubmitted ?? this.mirSubmitted,
      source: source ?? this.source,
      sourceFileName: sourceFileName ?? this.sourceFileName,
    );
  }
}
