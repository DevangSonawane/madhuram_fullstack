class User {
  final String id;
  final String name;
  final String? username;
  final String email;
  final String? phoneNumber;
  final String role;
  final List<String>? projectList;
  final String? avatar;

  const User({
    required this.id,
    required this.name,
    this.username,
    required this.email,
    this.phoneNumber,
    required this.role,
    this.projectList,
    this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['user_id'] ?? json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      username: json['username'],
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'],
      role: json['role'] ?? 'labour',
      projectList: json['project_list'] != null
          ? List<String>.from(json['project_list'])
          : null,
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': id,
    'name': name,
    'username': username,
    'email': email,
    'phone_number': phoneNumber,
    'role': role,
    'project_list': projectList,
    'avatar': avatar,
  };

  bool get isAdmin => role == 'admin';
  bool get isProjectManager => role == 'project_manager';
  bool get isPoOfficer => role == 'po_officer';
  
  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : name.length).toUpperCase();
  }
}
