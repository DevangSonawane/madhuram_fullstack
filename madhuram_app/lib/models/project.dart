/// Project model - Matching React app project structure
class Project {
  final String id;
  final String name;
  final String? client;
  final String? location;
  final String? status;
  final String? startDate;
  final String? endDate;
  final String? estimateValue;
  final String? description;
  final Map<String, dynamic>? rawData;

  const Project({
    required this.id,
    required this.name,
    this.client,
    this.location,
    this.status,
    this.startDate,
    this.endDate,
    this.estimateValue,
    this.description,
    this.rawData,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id']?.toString() ?? json['project_id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['project_name']?.toString() ?? 'Unnamed Project',
      client: json['client']?.toString() ?? json['client_name']?.toString(),
      location: json['location']?.toString(),
      status: json['status']?.toString() ?? 'Planning',
      startDate: json['start_date']?.toString() ?? json['startDate']?.toString(),
      endDate: json['end_date']?.toString() ?? json['endDate']?.toString(),
      estimateValue: json['estimate_value']?.toString() ?? json['estimateValue']?.toString(),
      description: json['description']?.toString(),
      rawData: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'client': client,
      'location': location,
      'status': status,
      'start_date': startDate,
      'end_date': endDate,
      'estimate_value': estimateValue,
      'description': description,
    };
  }

  /// Convert to Map for Redux state (maintains compatibility with existing Map<String, dynamic> storage)
  Map<String, dynamic> toMap() => toJson();

  /// Create from Redux state Map
  static Project fromMap(Map<String, dynamic> map) => Project.fromJson(map);

  @override
  String toString() => 'Project(id: $id, name: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Project && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
