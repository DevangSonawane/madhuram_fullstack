/// Demo data for BOQ, MIR, ITR, and Projects modules.
/// Pre-seeds pages so they never show blank screens.

class BOQDemo {
  BOQDemo._();

  static List<Map<String, dynamic>> get items => [
    {'boq_id': '1', 'item_code': 'C-101', 'category': 'Civil', 'description': 'Cement Grade 53', 'unit': 'Bags', 'quantity': 500, 'rate': 350, 'amount': 175000, 'floor': 'Ground'},
    {'boq_id': '2', 'item_code': 'P-201', 'category': 'Plumbing', 'description': 'PVC Pipe 4 inch', 'unit': 'Meters', 'quantity': 200, 'rate': 120, 'amount': 24000, 'floor': '1st'},
    {'boq_id': '3', 'item_code': 'E-301', 'category': 'Electrical', 'description': 'Cable 2.5mm Copper', 'unit': 'Meters', 'quantity': 1000, 'rate': 45, 'amount': 45000, 'floor': '1st'},
    {'boq_id': '4', 'item_code': 'C-102', 'category': 'Civil', 'description': 'TMT Steel 12mm', 'unit': 'KG', 'quantity': 2000, 'rate': 65, 'amount': 130000, 'floor': 'Ground'},
    {'boq_id': '5', 'item_code': 'P-202', 'category': 'Plumbing', 'description': 'CPVC Pipe 1 inch', 'unit': 'Meters', 'quantity': 300, 'rate': 85, 'amount': 25500, 'floor': '2nd'},
    {'boq_id': '6', 'item_code': 'F-401', 'category': 'Fire Fighting', 'description': 'GI Pipe 2 inch', 'unit': 'Meters', 'quantity': 150, 'rate': 210, 'amount': 31500, 'floor': 'All'},
  ];
}

class MIRDemo {
  MIRDemo._();

  static List<Map<String, dynamic>> get mirs => [
    {'mir_id': '1', 'mir_refrence_no': 'MIR-001', 'material_code': 'M-001', 'client_name': 'Oakwood', 'status': 'Pending', 'project_name': 'Oakwood Plumbing', 'created_at': '2024-01-20'},
    {'mir_id': '2', 'mir_refrence_no': 'MIR-002', 'material_code': 'M-002', 'client_name': 'Oakwood', 'status': 'Approved', 'project_name': 'Oakwood Plumbing', 'created_at': '2024-01-22'},
    {'mir_id': '3', 'mir_refrence_no': 'MIR-003', 'material_code': 'M-003', 'client_name': 'NANHI', 'status': 'Submitted', 'project_name': 'Nanhi Trap Jali', 'created_at': '2024-01-25'},
    {'mir_id': '4', 'mir_refrence_no': 'MIR-004', 'material_code': 'M-004', 'client_name': 'Oakwood', 'status': 'Rejected', 'project_name': 'Oakwood Plumbing', 'created_at': '2024-02-01'},
  ];
}

class ITRDemo {
  ITRDemo._();

  static List<Map<String, dynamic>> get itrs => [
    {'itr_id': '1', 'itr_ref_no': 'ITR-001', 'project_name': 'Oakwood Plumbing', 'discipline': 'Plumbing', 'status': 'Pending', 'created_at': '2024-01-18'},
    {'itr_id': '2', 'itr_ref_no': 'ITR-002', 'project_name': 'Oakwood Plumbing', 'discipline': 'Fire Fighting', 'status': 'Completed', 'created_at': '2024-01-20'},
    {'itr_id': '3', 'itr_ref_no': 'ITR-003', 'project_name': 'Nanhi Trap Jali', 'discipline': 'Electrical', 'status': 'In Progress', 'created_at': '2024-01-25'},
    {'itr_id': '4', 'itr_ref_no': 'ITR-004', 'project_name': 'Oakwood Plumbing', 'discipline': 'Civil', 'status': 'Pending', 'created_at': '2024-02-01'},
  ];
}

class ProjectsDemo {
  ProjectsDemo._();

  static List<Map<String, dynamic>> get projects => [
    {
      'project_id': 'PRJ-001',
      'project_name': 'Oakwood Plumbing',
      'client_name': 'Oakwood',
      'location': 'Mumbai',
      'floor': '1-5',
      'estimate_value': '₹1.2 Cr',
      'status': 'Active',
      'start_date': '2024-01-15',
    },
    {
      'project_id': 'PRJ-002',
      'project_name': 'Nanhi Trap Jali',
      'client_name': 'NANHI',
      'location': 'Pune',
      'floor': 'Ground',
      'estimate_value': '₹40 Lakh',
      'status': 'Planning',
      'start_date': '2024-02-01',
    },
    {
      'project_id': 'PRJ-003',
      'project_name': 'Metro Tower HVAC',
      'client_name': 'Metro Corp',
      'location': 'Thane',
      'floor': '1-12',
      'estimate_value': '₹3.5 Cr',
      'status': 'Active',
      'start_date': '2024-03-01',
    },
  ];
}
