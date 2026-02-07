/// Demo data for remaining modules: POs, Challans, Stock Transfers,
/// Consumption, Returns, Billing — matches React app's mock data
class PurchaseOrdersDemo {
  PurchaseOrdersDemo._();

  static List<Map<String, dynamic>> get orders => [
    {'po_id': '1', 'order_no': 'PO-2024-001', 'po_date': '2024-01-20', 'vendor_name': 'ABC Suppliers Pvt Ltd', 'total_amount': '₹50,000', 'status': 'Submitted', 'items_count': 5},
    {'po_id': '2', 'order_no': 'PO-2024-002', 'po_date': '2024-01-25', 'vendor_name': 'XYZ Traders', 'total_amount': '₹1,25,000', 'status': 'Draft', 'items_count': 8},
    {'po_id': '3', 'order_no': 'PO-2024-003', 'po_date': '2024-02-01', 'vendor_name': 'Metro Steel Works', 'total_amount': '₹2,80,000', 'status': 'Approved', 'items_count': 3},
    {'po_id': '4', 'order_no': 'PO-2024-004', 'po_date': '2024-02-05', 'vendor_name': 'Reliable Electricals', 'total_amount': '₹75,000', 'status': 'Submitted', 'items_count': 12},
    {'po_id': '5', 'order_no': 'PO-2024-005', 'po_date': '2024-02-10', 'vendor_name': 'Sunrise Plumbing Solutions', 'total_amount': '₹45,000', 'status': 'Completed', 'items_count': 6},
  ];
}

class ChallansDemo {
  ChallansDemo._();

  static List<Map<String, dynamic>> get challans => [
    {'challan_id': '1', 'challan_no': 'DC-2024-001', 'vendor': 'ABC Suppliers Pvt Ltd', 'date': '2024-01-20', 'items': 5, 'status': 'Received', 'po_ref': 'PO-2024-001'},
    {'challan_id': '2', 'challan_no': 'DC-2024-002', 'vendor': 'Metro Steel Works', 'date': '2024-01-25', 'items': 3, 'status': 'Pending', 'po_ref': 'PO-2024-003'},
    {'challan_id': '3', 'challan_no': 'DC-2024-003', 'vendor': 'XYZ Traders', 'date': '2024-02-01', 'items': 8, 'status': 'Inspecting', 'po_ref': 'PO-2024-002'},
    {'challan_id': '4', 'challan_no': 'DC-2024-004', 'vendor': 'Reliable Electricals', 'date': '2024-02-05', 'items': 12, 'status': 'Received', 'po_ref': 'PO-2024-004'},
  ];
}

class StockTransfersDemo {
  StockTransfersDemo._();

  static List<Map<String, dynamic>> get transfers => [
    {'transfer_id': '1', 'from_area': 'Main Warehouse', 'to_area': 'Secondary Store', 'material': 'Cement OPC 53', 'quantity': 50, 'date': '2024-01-20', 'status': 'Completed'},
    {'transfer_id': '2', 'from_area': 'Main Warehouse', 'to_area': 'Overflow Storage', 'material': 'Steel TMT 12mm', 'quantity': 200, 'date': '2024-01-22', 'status': 'Completed'},
    {'transfer_id': '3', 'from_area': 'Secondary Store', 'to_area': 'Main Warehouse', 'material': 'PVC Pipe 4"', 'quantity': 100, 'date': '2024-01-25', 'status': 'In Transit'},
    {'transfer_id': '4', 'from_area': 'Main Warehouse', 'to_area': 'Secondary Store', 'material': 'Electrical Cable 2.5mm', 'quantity': 300, 'date': '2024-02-01', 'status': 'Pending'},
  ];
}

class ConsumptionDemo {
  ConsumptionDemo._();

  static List<Map<String, dynamic>> get consumptions => [
    {'consumption_id': '1', 'material': 'Cement OPC 53', 'quantity': 100, 'unit': 'Bags', 'date': '2024-01-20', 'floor': 'Ground'},
    {'consumption_id': '2', 'material': 'Steel TMT 12mm', 'quantity': 500, 'unit': 'KG', 'date': '2024-01-21', 'floor': '1st'},
    {'consumption_id': '3', 'material': 'PVC Pipe 4"', 'quantity': 80, 'unit': 'Meters', 'date': '2024-01-22', 'floor': 'Ground'},
    {'consumption_id': '4', 'material': 'River Sand', 'quantity': 50, 'unit': 'CFT', 'date': '2024-01-23', 'floor': 'Ground'},
    {'consumption_id': '5', 'material': 'Electrical Cable 2.5mm', 'quantity': 150, 'unit': 'Meters', 'date': '2024-01-25', 'floor': '1st'},
    {'consumption_id': '6', 'material': 'CPVC Pipe 1"', 'quantity': 60, 'unit': 'Meters', 'date': '2024-02-01', 'floor': '2nd'},
  ];
}

class ReturnsDemo {
  ReturnsDemo._();

  static List<Map<String, dynamic>> get returns => [
    {'return_id': '1', 'material': 'PVC Pipe 4"', 'quantity': 20, 'reason': 'Damaged in transit', 'date': '2024-01-22', 'status': 'Processed'},
    {'return_id': '2', 'material': 'Cement OPC 53', 'quantity': 10, 'reason': 'Expired stock', 'date': '2024-01-25', 'status': 'Pending'},
    {'return_id': '3', 'material': 'Steel TMT 12mm', 'quantity': 50, 'reason': 'Quality mismatch', 'date': '2024-02-01', 'status': 'Approved'},
    {'return_id': '4', 'material': 'GI Wire 16 Gauge', 'quantity': 15, 'reason': 'Excess quantity', 'date': '2024-02-03', 'status': 'Pending'},
  ];
}

class BillingDemo {
  BillingDemo._();

  static List<Map<String, dynamic>> get bills => [
    {'bill_id': '1', 'invoice_no': 'INV-2024-001', 'amount': '₹1,50,000', 'date': '2024-01-25', 'status': 'Pending', 'vendor': 'ABC Suppliers Pvt Ltd'},
    {'bill_id': '2', 'invoice_no': 'INV-2024-002', 'amount': '₹2,80,000', 'date': '2024-01-28', 'status': 'Paid', 'vendor': 'Metro Steel Works'},
    {'bill_id': '3', 'invoice_no': 'INV-2024-003', 'amount': '₹75,000', 'date': '2024-02-01', 'status': 'Overdue', 'vendor': 'Reliable Electricals'},
    {'bill_id': '4', 'invoice_no': 'INV-2024-004', 'amount': '₹45,000', 'date': '2024-02-05', 'status': 'Pending', 'vendor': 'Sunrise Plumbing Solutions'},
    {'bill_id': '5', 'invoice_no': 'INV-2024-005', 'amount': '₹1,25,000', 'date': '2024-02-10', 'status': 'Paid', 'vendor': 'XYZ Traders'},
  ];
}
