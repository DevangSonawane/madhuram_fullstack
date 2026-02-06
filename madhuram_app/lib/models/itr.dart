class ITR {
  final String id;
  final String? projectId;
  final String itrRefNo;
  final String? projectName;
  final String? clientEmployer;
  final String? contractorPart;
  final String? lodhaPmc;
  final String? discipline;
  final Map<String, dynamic>? dynamicField;
  final String? status;
  final DateTime? createdAt;
  // Additional fields from React API
  final String? pmcEngineer;
  final String? contractor;
  final String? vendorCode;
  final String? materialCode;
  final String? wirItrSubmissionDateTime;
  final String? inspectionDateTime;
  final String? submittedTo;
  final String? submittedBy;
  final String? source;
  final String? sourceFileName;
  final Map<String, dynamic>? contractorPartData;
  final Map<String, dynamic>? lodhaPmcData;

  const ITR({
    required this.id,
    this.projectId,
    required this.itrRefNo,
    this.projectName,
    this.clientEmployer,
    this.contractorPart,
    this.lodhaPmc,
    this.discipline,
    this.dynamicField,
    this.status,
    this.createdAt,
    this.pmcEngineer,
    this.contractor,
    this.vendorCode,
    this.materialCode,
    this.wirItrSubmissionDateTime,
    this.inspectionDateTime,
    this.submittedTo,
    this.submittedBy,
    this.source,
    this.sourceFileName,
    this.contractorPartData,
    this.lodhaPmcData,
  });

  factory ITR.fromJson(Map<String, dynamic> json) {
    return ITR(
      id: (json['itr_id'] ?? json['id'] ?? '').toString(),
      projectId: json['project_id']?.toString(),
      itrRefNo: json['itr_ref_no'] ?? '',
      projectName: json['project_name'],
      clientEmployer: json['client_employer'],
      contractorPart: json['contractor_part'] is String ? json['contractor_part'] : null,
      lodhaPmc: json['lodha_pmc'] is String ? json['lodha_pmc'] : null,
      discipline: json['discipline'],
      dynamicField: json['dynamic_field'] as Map<String, dynamic>?,
      status: json['status'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      pmcEngineer: json['pmc_engineer'],
      contractor: json['contractor'],
      vendorCode: json['vendor_code'],
      materialCode: json['material_code'],
      wirItrSubmissionDateTime: json['wir_itr_submission_date_time'],
      inspectionDateTime: json['inspection_date_time'],
      submittedTo: json['submitted_to'],
      submittedBy: json['submitted_by'],
      source: json['source'],
      sourceFileName: json['source_file_name'],
      contractorPartData: json['contractor_part'] is Map ? json['contractor_part'] as Map<String, dynamic> : null,
      lodhaPmcData: json['lodha_pmc'] is Map ? json['lodha_pmc'] as Map<String, dynamic> : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'itr_id': id,
    'project_id': projectId,
    'itr_ref_no': itrRefNo,
    'project_name': projectName,
    'client_employer': clientEmployer,
    'contractor_part': contractorPartData ?? contractorPart,
    'lodha_pmc': lodhaPmcData ?? lodhaPmc,
    'discipline': discipline,
    'dynamic_field': dynamicField,
    'status': status,
    'pmc_engineer': pmcEngineer,
    'contractor': contractor,
    'vendor_code': vendorCode,
    'material_code': materialCode,
    'wir_itr_submission_date_time': wirItrSubmissionDateTime,
    'inspection_date_time': inspectionDateTime,
    'submitted_to': submittedTo,
    'submitted_by': submittedBy,
    'source': source,
    'source_file_name': sourceFileName,
  };

  ITR copyWith({
    String? id,
    String? projectId,
    String? itrRefNo,
    String? projectName,
    String? clientEmployer,
    String? contractorPart,
    String? lodhaPmc,
    String? discipline,
    Map<String, dynamic>? dynamicField,
    String? status,
    String? pmcEngineer,
    String? contractor,
    String? vendorCode,
    String? materialCode,
    String? wirItrSubmissionDateTime,
    String? inspectionDateTime,
    String? submittedTo,
    String? submittedBy,
    String? source,
    String? sourceFileName,
    Map<String, dynamic>? contractorPartData,
    Map<String, dynamic>? lodhaPmcData,
  }) {
    return ITR(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      itrRefNo: itrRefNo ?? this.itrRefNo,
      projectName: projectName ?? this.projectName,
      clientEmployer: clientEmployer ?? this.clientEmployer,
      contractorPart: contractorPart ?? this.contractorPart,
      lodhaPmc: lodhaPmc ?? this.lodhaPmc,
      discipline: discipline ?? this.discipline,
      dynamicField: dynamicField ?? this.dynamicField,
      status: status ?? this.status,
      createdAt: createdAt,
      pmcEngineer: pmcEngineer ?? this.pmcEngineer,
      contractor: contractor ?? this.contractor,
      vendorCode: vendorCode ?? this.vendorCode,
      materialCode: materialCode ?? this.materialCode,
      wirItrSubmissionDateTime: wirItrSubmissionDateTime ?? this.wirItrSubmissionDateTime,
      inspectionDateTime: inspectionDateTime ?? this.inspectionDateTime,
      submittedTo: submittedTo ?? this.submittedTo,
      submittedBy: submittedBy ?? this.submittedBy,
      source: source ?? this.source,
      sourceFileName: sourceFileName ?? this.sourceFileName,
      contractorPartData: contractorPartData ?? this.contractorPartData,
      lodhaPmcData: lodhaPmcData ?? this.lodhaPmcData,
    );
  }
}

// ITR Discipline options matching React app
const itrDisciplines = [
  'Plumbing',
  'Fire Fighting',
  'HVAC',
  'Electrical',
  'Civil',
  'Structural',
];
