/// Demo data for Stock Areas page - matches React app's mock data
class StockAreasDemo {
  StockAreasDemo._();

  static List<Map<String, dynamic>> get warehouses => [
    {
      'id': 'wh1',
      'name': 'Main Warehouse',
      'location': 'Site A',
      'status': 'Active',
      'totalCapacity': 10000.0,
      'currentStock': 7200.0,
    },
    {
      'id': 'wh2',
      'name': 'Secondary Store',
      'location': 'Site B',
      'status': 'Active',
      'totalCapacity': 5000.0,
      'currentStock': 2100.0,
    },
    {
      'id': 'wh3',
      'name': 'Overflow Storage',
      'location': 'Site A',
      'status': 'Active',
      'totalCapacity': 3000.0,
      'currentStock': 450.0,
    },
  ];

  static List<Map<String, dynamic>> get zones => [
    {'id': 'zA', 'name': 'Zone A', 'warehouseId': 'wh1', 'rackIds': ['A-1', 'A-2', 'A-3']},
    {'id': 'zB', 'name': 'Zone B', 'warehouseId': 'wh1', 'rackIds': ['B-1', 'B-2']},
    {'id': 'zC', 'name': 'Zone C', 'warehouseId': 'wh2', 'rackIds': ['C-1', 'C-2']},
    {'id': 'zD', 'name': 'Zone D', 'warehouseId': 'wh3', 'rackIds': ['D-1']},
  ];

  static List<Map<String, dynamic>> get racks => [
    {'id': 'A-1', 'name': 'A-1', 'zoneId': 'zA'},
    {'id': 'A-2', 'name': 'A-2', 'zoneId': 'zA'},
    {'id': 'A-3', 'name': 'A-3', 'zoneId': 'zA'},
    {'id': 'B-1', 'name': 'B-1', 'zoneId': 'zB'},
    {'id': 'B-2', 'name': 'B-2', 'zoneId': 'zB'},
    {'id': 'C-1', 'name': 'C-1', 'zoneId': 'zC'},
    {'id': 'C-2', 'name': 'C-2', 'zoneId': 'zC'},
    {'id': 'D-1', 'name': 'D-1', 'zoneId': 'zD'},
  ];
}
