/// Demo data for Dashboard page - matches React app's mock data
class DashboardDemo {
  DashboardDemo._();

  static Map<String, dynamic> get stats => {
    'total_value': '₹45,231.89',
    'total_value_change': 20.1,
    'active_orders': '2,350',
    'active_orders_change': -4.0,
    'low_stock_items': '12',
    'total_materials': '573',
    'warehouses': 4,
  };

  static List<Map<String, dynamic>> get consumptionChart => [
    {'name': 'Jan', 'total': 1200},
    {'name': 'Feb', 'total': 2100},
    {'name': 'Mar', 'total': 800},
    {'name': 'Apr', 'total': 1600},
    {'name': 'May', 'total': 900},
    {'name': 'Jun', 'total': 1700},
  ];

  static List<Map<String, dynamic>> get recentActivity => [
    {
      'user': 'John Doe',
      'action': 'Created purchase order PO-2024-001',
      'time': '2 mins ago',
      'status': 'success',
      'initials': 'JD',
    },
    {
      'user': 'Jane Smith',
      'action': 'Approved material request MR-045',
      'time': '1 hour ago',
      'status': 'success',
      'initials': 'JS',
    },
    {
      'user': 'System',
      'action': 'Low stock alert: Cement OPC 53 below threshold',
      'time': '2 hours ago',
      'status': 'warning',
      'initials': 'SY',
    },
    {
      'user': 'Mike Johnson',
      'action': 'Received shipment for PO-123 at Main Warehouse',
      'time': '4 hours ago',
      'status': 'info',
      'initials': 'MJ',
    },
    {
      'user': 'Sarah Wilson',
      'action': 'Completed stock transfer STR-012 to Site B',
      'time': '6 hours ago',
      'status': 'success',
      'initials': 'SW',
    },
  ];
}
