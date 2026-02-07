/// Demo data for Settings/Profile page - matches React app's mock data
class SettingsDemo {
  SettingsDemo._();

  /// Default user profile data when auth state is empty
  static Map<String, dynamic> get demoUser => {
    'user_id': 'demo-user-001',
    'name': 'Admin User',
    'username': 'admin',
    'email': 'admin@madhuram.com',
    'phone_number': '+91 99999 99999',
    'role': 'admin',
    'avatar': null,
  };

  /// Demo users list for admin management
  static List<Map<String, dynamic>> get users => [
    {
      'user_id': '1',
      'name': 'Admin User',
      'username': 'admin',
      'email': 'admin@madhuram.com',
      'phone_number': '+91 99999 99999',
      'role': 'admin',
    },
    {
      'user_id': '2',
      'name': 'Rajesh Patel',
      'username': 'rajesh.patel',
      'email': 'rajesh@madhuram.com',
      'phone_number': '+91 98888 88888',
      'role': 'project_manager',
    },
    {
      'user_id': '3',
      'name': 'Priya Sharma',
      'username': 'priya.sharma',
      'email': 'priya@madhuram.com',
      'phone_number': '+91 97777 77777',
      'role': 'operational_manager',
    },
    {
      'user_id': '4',
      'name': 'Amit Singh',
      'username': 'amit.singh',
      'email': 'amit@madhuram.com',
      'phone_number': '+91 96666 66666',
      'role': 'po_officer',
    },
    {
      'user_id': '5',
      'name': 'Vikram Desai',
      'username': 'vikram.desai',
      'email': 'vikram@madhuram.com',
      'phone_number': '+91 95555 55555',
      'role': 'labour',
    },
  ];

  /// App version info
  static const String appVersion = '1.0.0';
  static const String buildNumber = '2026.02.07';
}
