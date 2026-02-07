/// Demo data for Reports page - matches React app's mock data
class ReportsDemo {
  ReportsDemo._();

  static Map<String, dynamic> get reportData => {
    'total_value': '₹42.5L',
    'total_materials': '1,240',
    'out_of_stock': '12',
    'turnover_rate': '4.2',
    'active_orders': '2,350',
    'low_stock_items': '12',
    'consumption_data': consumptionTrend,
  };

  static List<Map<String, dynamic>> get consumptionTrend => [
    {'name': 'Jan', 'total': 1200},
    {'name': 'Feb', 'total': 2100},
    {'name': 'Mar', 'total': 800},
    {'name': 'Apr', 'total': 1600},
    {'name': 'May', 'total': 900},
    {'name': 'Jun', 'total': 1700},
  ];

  static List<Map<String, dynamic>> get inventoryComposition => [
    {'name': 'Civil', 'value': 320.0},
    {'name': 'Plumbing', 'value': 280.0},
    {'name': 'Electrical', 'value': 250.0},
    {'name': 'HVAC', 'value': 180.0},
    {'name': 'Fire Fighting', 'value': 210.0},
  ];

  static List<Map<String, dynamic>> get stockValuation => [
    {'name': 'Civil', 'value': 12.5},
    {'name': 'Plumbing', 'value': 9.2},
    {'name': 'Electrical', 'value': 8.1},
    {'name': 'HVAC', 'value': 5.4},
    {'name': 'Fire Fighting', 'value': 7.3},
  ];

  static List<Map<String, dynamic>> get lowStockItems => [
    {'name': 'Cement OPC 53', 'current': 45, 'reorder': 100, 'status': 'Low'},
    {'name': 'PVC Pipe 4"', 'current': 120, 'reorder': 200, 'status': 'Critical'},
    {'name': 'River Sand', 'current': 80, 'reorder': 150, 'status': 'Low'},
    {'name': 'Steel TMT 12mm', 'current': 25, 'reorder': 80, 'status': 'Critical'},
    {'name': 'Electrical Cable 2.5mm', 'current': 200, 'reorder': 250, 'status': 'Low'},
    {'name': 'Sprinkler Head', 'current': 45, 'reorder': 100, 'status': 'Critical'},
  ];
}
