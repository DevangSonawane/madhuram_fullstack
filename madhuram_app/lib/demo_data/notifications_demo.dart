/// Demo data for Notifications - matches React app's mock data
class NotificationsDemo {
  NotificationsDemo._();

  static List<Map<String, dynamic>> get notifications => [
    {
      'notification_id': 'notif-001',
      'title': 'New PO Approved',
      'message': 'Purchase order PO-2024-001 for ABC Suppliers has been approved by the project manager.',
      'type': 'success',
      'is_read': false,
      'created_at': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
    },
    {
      'notification_id': 'notif-002',
      'title': 'Low Stock Alert',
      'message': 'Cement OPC 53 stock is below minimum level (45 bags remaining, threshold: 100 bags).',
      'type': 'warning',
      'is_read': false,
      'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
    },
    {
      'notification_id': 'notif-003',
      'title': 'MIR Submitted',
      'message': 'Material inspection request MIR-456 has been submitted for review.',
      'type': 'info',
      'is_read': true,
      'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
    },
    {
      'notification_id': 'notif-004',
      'title': 'Shipment Received',
      'message': 'Shipment for PO-123 received at Main Warehouse. 5 items checked in.',
      'type': 'success',
      'is_read': true,
      'created_at': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
    },
    {
      'notification_id': 'notif-005',
      'title': 'Stock Transfer Complete',
      'message': 'Stock transfer STR-012 from Main Warehouse to Secondary Store completed.',
      'type': 'info',
      'is_read': false,
      'created_at': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
    },
    {
      'notification_id': 'notif-006',
      'title': 'Critical: PVC Pipe Stock',
      'message': 'PVC Pipe 4" is critically low at 120 meters (reorder point: 200 meters).',
      'type': 'warning',
      'is_read': false,
      'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    },
  ];
}
