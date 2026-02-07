import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../store/app_state.dart';
import '../components/ui/components.dart';
import '../components/layout/main_layout.dart';
import '../utils/responsive.dart';

/// Purchase request model
class PurchaseRequest {
  final String id;
  final String requestNo;
  final String material;
  final double quantity;
  final String unit;
  final String? requestedBy;
  final String? date;
  final String status;
  final String? priority;
  final String? remarks;

  const PurchaseRequest({
    required this.id,
    required this.requestNo,
    required this.material,
    required this.quantity,
    required this.unit,
    this.requestedBy,
    this.date,
    this.status = 'Pending',
    this.priority,
    this.remarks,
  });

  factory PurchaseRequest.fromJson(Map<String, dynamic> json) {
    return PurchaseRequest(
      id: (json['request_id'] ?? json['id'] ?? '').toString(),
      requestNo: json['request_no'] ?? '',
      material: json['material'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] ?? '',
      requestedBy: json['requested_by'],
      date: json['date'],
      status: json['status'] ?? 'Pending',
      priority: json['priority'],
      remarks: json['remarks'],
    );
  }
}

/// Data for one line item in the purchase request wizard
class _PRWizardItem {
  String materialName = '';
  String quantity = '';
  String unit = 'Nos';
  String estimatedRate = '';
  String remarks = '';

  _PRWizardItem();
}

/// One editable row for Items step in PR wizard
class _PRItemRow extends StatefulWidget {
  final _PRWizardItem item;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;

  const _PRItemRow({
    super.key,
    required this.item,
    required this.index,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  State<_PRItemRow> createState() => _PRItemRowState();
}

class _PRItemRowState extends State<_PRItemRow> {
  late TextEditingController _materialController;
  late TextEditingController _qtyController;
  late TextEditingController _rateController;
  late TextEditingController _remarksController;

  @override
  void initState() {
    super.initState();
    _materialController = TextEditingController(text: widget.item.materialName);
    _qtyController = TextEditingController(text: widget.item.quantity);
    _rateController = TextEditingController(text: widget.item.estimatedRate);
    _remarksController = TextEditingController(text: widget.item.remarks);
  }

  @override
  void dispose() {
    _materialController.dispose();
    _qtyController.dispose();
    _rateController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return MadCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Item ${widget.index + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 18),
                  onPressed: widget.canRemove ? widget.onRemove : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            MadInput(
              labelText: 'Material Name',
              hintText: 'Material',
              controller: _materialController,
              onChanged: (v) => item.materialName = v,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MadInput(
                    labelText: 'Quantity',
                    hintText: '0',
                    keyboardType: TextInputType.number,
                    controller: _qtyController,
                    onChanged: (v) => item.quantity = v,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MadSelect<String>(
                    labelText: 'Unit',
                    placeholder: 'Unit',
                    value: item.unit,
                    options: const [
                      MadSelectOption(value: 'Nos', label: 'Nos'),
                      MadSelectOption(value: 'Bags', label: 'Bags'),
                      MadSelectOption(value: 'Meters', label: 'Meters'),
                      MadSelectOption(value: 'KG', label: 'KG'),
                    ],
                    onChanged: (v) => setState(() => item.unit = v ?? 'Nos'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            MadInput(
              labelText: 'Estimated Rate',
              hintText: '0.00',
              keyboardType: TextInputType.number,
              controller: _rateController,
              onChanged: (v) => item.estimatedRate = v,
            ),
            const SizedBox(height: 12),
            MadInput(
              labelText: 'Remarks',
              hintText: 'Remarks',
              controller: _remarksController,
              onChanged: (v) => item.remarks = v,
            ),
          ],
        ),
      ),
    );
  }
}

/// Purchase Requests page matching React's PurchaseRequests page.
class PurchaseRequestsPageFull extends StatefulWidget {
  const PurchaseRequestsPageFull({super.key});

  @override
  State<PurchaseRequestsPageFull> createState() => _PurchaseRequestsPageFullState();
}

class _PurchaseRequestsPageFullState extends State<PurchaseRequestsPageFull> {
  bool _isLoading = false;
  List<PurchaseRequest> _requests = [];
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  final _searchController = TextEditingController();
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRequests();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    
    // Mock data
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    setState(() {
      _requests = [
        PurchaseRequest(id: '1', requestNo: 'PR-001', material: 'Cement OPC 53', quantity: 500, unit: 'Bags', requestedBy: 'John Doe', date: '2024-01-20', status: 'Pending', priority: 'High'),
        PurchaseRequest(id: '2', requestNo: 'PR-002', material: 'PVC Pipe 4"', quantity: 200, unit: 'Meters', requestedBy: 'Jane Smith', date: '2024-01-22', status: 'Approved', priority: 'Medium'),
        PurchaseRequest(id: '3', requestNo: 'PR-003', material: 'Steel Rods 12mm', quantity: 1000, unit: 'KG', requestedBy: 'Mike Johnson', date: '2024-01-23', status: 'Rejected', priority: 'Low'),
      ];
      _isLoading = false;
    });
  }

  List<PurchaseRequest> get _filteredRequests {
    List<PurchaseRequest> result = _requests;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((r) {
        return r.requestNo.toLowerCase().contains(query) ||
            r.material.toLowerCase().contains(query) ||
            (r.requestedBy?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    if (_statusFilter != null) {
      result = result.where((r) => r.status == _statusFilter).toList();
    }

    return result;
  }

  List<PurchaseRequest> get _paginatedRequests {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;
    final filtered = _filteredRequests;
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end > filtered.length ? filtered.length : end);
  }

  int get _totalPages => (_filteredRequests.length / _itemsPerPage).ceil();

  void _approveRequest(PurchaseRequest request) {
    setState(() {
      final i = _requests.indexWhere((r) => r.id == request.id);
      if (i >= 0) {
        final r = _requests[i];
        _requests[i] = PurchaseRequest(
          id: r.id,
          requestNo: r.requestNo,
          material: r.material,
          quantity: r.quantity,
          unit: r.unit,
          requestedBy: r.requestedBy,
          date: r.date,
          status: 'Approved',
          priority: r.priority,
          remarks: r.remarks,
        );
      }
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request approved')));
  }

  void _rejectRequest(PurchaseRequest request) {
    setState(() {
      final i = _requests.indexWhere((r) => r.id == request.id);
      if (i >= 0) {
        final r = _requests[i];
        _requests[i] = PurchaseRequest(
          id: r.id,
          requestNo: r.requestNo,
          material: r.material,
          quantity: r.quantity,
          unit: r.unit,
          requestedBy: r.requestedBy,
          date: r.date,
          status: 'Rejected',
          priority: r.priority,
          remarks: r.remarks,
        );
      }
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request rejected')));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final responsive = Responsive(context);
    final isMobile = responsive.isMobile;

    return ProtectedRoute(
      title: 'Purchase Requests',
      route: '/purchase-requests',
      child: StoreConnector<AppState, bool>(
        converter: (store) => store.state.auth.isAdmin,
        builder: (context, isAdmin) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Purchase Requests',
                      style: TextStyle(
                        fontSize: responsive.value(mobile: 22, tablet: 26, desktop: 28),
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage material purchase requests',
                      style: TextStyle(
                        color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                MadButton(
                  text: 'New Request',
                  icon: LucideIcons.plus,
                  onPressed: () => _showRequestDialog(),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats cards
          if (!isMobile)
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Total Requests',
                    value: _requests.length.toString(),
                    icon: LucideIcons.fileText,
                    iconColor: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Pending',
                    value: _requests.where((r) => r.status == 'Pending').length.toString(),
                    icon: LucideIcons.clock,
                    iconColor: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Approved',
                    value: _requests.where((r) => r.status == 'Approved').length.toString(),
                    icon: LucideIcons.circleCheck,
                    iconColor: const Color(0xFF22C55E),
                  ),
                ),
              ],
            ),
          if (!isMobile) const SizedBox(height: 24),

          // Search and filters
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: isMobile ? double.infinity : 320,
                child: MadSearchInput(
                  controller: _searchController,
                  hintText: 'Search requests...',
                  onChanged: (value) => setState(() {
                    _searchQuery = value;
                    _currentPage = 1;
                  }),
                  onClear: () => setState(() {
                    _searchQuery = '';
                    _currentPage = 1;
                  }),
                ),
              ),
              SizedBox(
                width: isMobile ? double.infinity : 150,
                child: MadSelect<String>(
                  value: _statusFilter,
                  placeholder: 'All Status',
                  clearable: true,
                  options: const [
                    MadSelectOption(value: 'Pending', label: 'Pending'),
                    MadSelectOption(value: 'Approved', label: 'Approved'),
                    MadSelectOption(value: 'Rejected', label: 'Rejected'),
                  ],
                  onChanged: (value) => setState(() {
                    _statusFilter = value;
                    _currentPage = 1;
                  }),
                ),
              ),
              if (isMobile)
                MadButton(
                  icon: LucideIcons.plus,
                  text: 'New',
                  onPressed: () => _showRequestDialog(),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Data table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRequests.isEmpty
                    ? _buildEmptyState(isDark)
                    : MadCard(
                        child: Column(
                          children: [
                            // Table header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: (isDark ? AppTheme.darkMuted : AppTheme.lightMuted).withOpacity(0.3),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              ),
                              child: Row(
                                children: [
                                  _buildHeaderCell('Request #', flex: 1, isDark: isDark),
                                  _buildHeaderCell('Material', flex: 2, isDark: isDark),
                                  if (!isMobile) ...[
                                    _buildHeaderCell('Quantity', flex: 1, isDark: isDark),
                                    _buildHeaderCell('Requested By', flex: 1, isDark: isDark),
                                    _buildHeaderCell('Priority', flex: 1, isDark: isDark),
                                  ],
                                  _buildHeaderCell('Status', flex: 1, isDark: isDark),
                                  const SizedBox(width: 48),
                                ],
                              ),
                            ),
                            // Table rows
                            Expanded(
                              child: ListView.separated(
                                itemCount: _paginatedRequests.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5),
                                ),
                                itemBuilder: (context, index) {
                                  return _buildTableRow(_paginatedRequests[index], isDark, isMobile, isAdmin);
                                },
                              ),
                            ),
                            // Pagination
                            if (_totalPages > 1) _buildPagination(isDark),
                          ],
                        ),
                      ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, {required int flex, required bool isDark}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
        ),
      ),
    );
  }

  Widget _buildTableRow(PurchaseRequest request, bool isDark, bool isMobile, bool isAdmin) {
    BadgeVariant statusVariant;
    switch (request.status) {
      case 'Approved':
        statusVariant = BadgeVariant.default_;
        break;
      case 'Pending':
        statusVariant = BadgeVariant.secondary;
        break;
      case 'Rejected':
        statusVariant = BadgeVariant.destructive;
        break;
      default:
        statusVariant = BadgeVariant.outline;
    }

    // Priority badges: High = Red, Medium = Amber, Low = Blue
    BadgeVariant priorityVariant;
    switch (request.priority) {
      case 'High':
        priorityVariant = BadgeVariant.destructive;
        break;
      case 'Medium':
        priorityVariant = BadgeVariant.warning;
        break;
      case 'Low':
        priorityVariant = BadgeVariant.primary;
        break;
      default:
        priorityVariant = BadgeVariant.outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              request.requestNo,
              style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.material, style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                if (isMobile)
                  Text(
                    '${request.quantity.toStringAsFixed(0)} ${request.unit}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                    ),
                  ),
              ],
            ),
          ),
          if (!isMobile) ...[
            Expanded(
              flex: 1,
              child: Text('${request.quantity.toStringAsFixed(0)} ${request.unit}', overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 1,
              child: Text(request.requestedBy ?? '-', overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 1,
              child: request.priority != null
                  ? MadBadge(text: request.priority!, variant: priorityVariant)
                  : const Text('-'),
            ),
          ],
          Expanded(
            flex: 1,
            child: MadBadge(text: request.status, variant: statusVariant),
          ),
          MadDropdownMenuButton(
            items: [
              MadMenuItem(label: 'View Details', icon: LucideIcons.eye, onTap: () {}),
              MadMenuItem(label: 'Edit', icon: LucideIcons.pencil, onTap: () {}),
              if (isAdmin && request.status == 'Pending') ...[
                MadMenuItem(label: 'Approve', icon: LucideIcons.circleCheck, onTap: () => _approveRequest(request)),
                MadMenuItem(label: 'Reject', icon: LucideIcons.circleX, destructive: true, onTap: () => _rejectRequest(request)),
              ],
              MadMenuItem(label: 'Delete', icon: LucideIcons.trash2, destructive: true, onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${(_currentPage - 1) * _itemsPerPage + 1}-${_currentPage * _itemsPerPage > _filteredRequests.length ? _filteredRequests.length : _currentPage * _itemsPerPage} of ${_filteredRequests.length}',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
            ),
          ),
          Row(
            children: [
              MadButton(
                icon: LucideIcons.chevronLeft,
                variant: ButtonVariant.outline,
                size: ButtonSize.sm,
                disabled: _currentPage == 1,
                onPressed: () => setState(() => _currentPage--),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('$_currentPage of $_totalPages'),
              ),
              MadButton(
                icon: LucideIcons.chevronRight,
                variant: ButtonVariant.outline,
                size: ButtonSize.sm,
                disabled: _currentPage >= _totalPages,
                onPressed: () => setState(() => _currentPage++),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.fileText,
              size: 64,
              color: (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground).withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty ? 'No purchase requests yet' : 'No requests found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Create a purchase request to get started'
                  : 'Try a different search term',
              style: TextStyle(
                color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              MadButton(
                text: 'New Request',
                icon: LucideIcons.plus,
                onPressed: () => _showRequestDialog(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRequestDialog() {
    MadFormDialog.show(
      context: context,
      title: 'New Purchase Request',
      maxWidth: 640,
      content: _PurchaseRequestWizardContent(
        onSubmitted: (newRequests) {
          Navigator.of(context).pop();
          setState(() => _requests.insertAll(0, newRequests));
          _loadRequests();
        },
        onSaveDraft: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft saved')));
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
      actions: const [],
    );
  }
}

/// 3-step wizard content for New Purchase Request
class _PurchaseRequestWizardContent extends StatefulWidget {
  final void Function(List<PurchaseRequest> newRequests) onSubmitted;
  final VoidCallback onSaveDraft;
  final VoidCallback onCancel;

  const _PurchaseRequestWizardContent({
    required this.onSubmitted,
    required this.onSaveDraft,
    required this.onCancel,
  });

  @override
  State<_PurchaseRequestWizardContent> createState() => _PurchaseRequestWizardContentState();
}

class _PurchaseRequestWizardContentState extends State<_PurchaseRequestWizardContent> {
  int _step = 0;
  final _prNumberController = TextEditingController(text: 'PR-${DateTime.now().millisecondsSinceEpoch % 100000}');
  String? _priority;
  final _requestedByController = TextEditingController();
  final _dateController = TextEditingController();
  final _departmentController = TextEditingController();
  final List<_PRWizardItem> _items = [_PRWizardItem()];
  final _generalRemarksController = TextEditingController();
  String? _bulkFileName;

  @override
  void dispose() {
    _prNumberController.dispose();
    _requestedByController.dispose();
    _dateController.dispose();
    _departmentController.dispose();
    _generalRemarksController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (date != null) _dateController.text = DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _pickBulkFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'pdf'],
    );
    if (result != null && result.files.single.name.isNotEmpty) {
      setState(() => _bulkFileName = result.files.single.name);
    }
  }

  Widget _buildStepIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        _stepChip(0, 'Basic Info', isDark),
        const SizedBox(width: 8),
        _stepChip(1, 'Items', isDark),
        const SizedBox(width: 8),
        _stepChip(2, 'Review', isDark),
      ],
    );
  }

  Widget _stepChip(int step, String label, bool isDark) {
    final active = _step == step;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppTheme.primaryColor : (isDark ? AppTheme.darkMuted : AppTheme.lightMuted),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          color: active ? Colors.white : (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        MadInput(
          controller: _prNumberController,
          labelText: 'PR Number',
          hintText: 'Auto-generated or enter manually',
        ),
        const SizedBox(height: 16),
        MadSelect<String>(
          labelText: 'Priority',
          value: _priority,
          placeholder: 'Select priority',
          options: const [
            MadSelectOption(value: 'High', label: 'High'),
            MadSelectOption(value: 'Medium', label: 'Medium'),
            MadSelectOption(value: 'Low', label: 'Low'),
          ],
          onChanged: (v) => setState(() => _priority = v),
        ),
        const SizedBox(height: 16),
        MadInput(
          controller: _requestedByController,
          labelText: 'Requested By',
          hintText: 'Name',
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _pickDate,
          child: AbsorbPointer(
            child: MadInput(
              controller: _dateController,
              labelText: 'Date',
              hintText: 'Select date',
            ),
          ),
        ),
        const SizedBox(height: 16),
        MadInput(
          controller: _departmentController,
          labelText: 'Department',
          hintText: 'Department',
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: _pickBulkFile,
          icon: const Icon(LucideIcons.upload, size: 18),
          label: Text(_bulkFileName ?? 'Upload file (Excel/PDF) for bulk items'),
        ),
        if (_bulkFileName != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Selected: $_bulkFileName', style: TextStyle(fontSize: 12, color: AppTheme.primaryColor)),
          ),
        const SizedBox(height: 20),
        ...List.generate(_items.length, (i) {
          final item = _items[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _PRItemRow(
              key: ObjectKey(item),
              item: item,
              index: i,
              canRemove: _items.length > 1,
              onRemove: () => setState(() => _items.removeAt(i)),
            ),
          );
        }),
        MadButton(
          text: 'Add Item',
          icon: LucideIcons.plus,
          variant: ButtonVariant.outline,
          onPressed: () => setState(() => _items.add(_PRWizardItem())),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        MadCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Summary', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground)),
                const SizedBox(height: 12),
                _summaryRow('PR Number', _prNumberController.text),
                _summaryRow('Priority', _priority ?? '-'),
                _summaryRow('Requested By', _requestedByController.text),
                _summaryRow('Date', _dateController.text),
                _summaryRow('Department', _departmentController.text),
                const SizedBox(height: 12),
                const Text('Items', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ..._items.asMap().entries.map((e) {
                  final i = e.key + 1;
                  final item = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('$i. ${item.materialName.isNotEmpty ? item.materialName : "(No name)"} - ${item.quantity} ${item.unit}${item.estimatedRate.isNotEmpty ? " @ ${item.estimatedRate}" : ""}'),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        MadTextarea(
          controller: _generalRemarksController,
          labelText: 'General Remarks',
          hintText: 'Additional notes...',
          minLines: 3,
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }

  void _submit() {
    final prNo = _prNumberController.text.trim().isEmpty ? 'PR-${DateTime.now().millisecondsSinceEpoch % 100000}' : _prNumberController.text.trim();
    final baseId = 'pr-${DateTime.now().millisecondsSinceEpoch}';
    final newRequests = <PurchaseRequest>[];
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      final mat = item.materialName.trim().isEmpty ? 'Item ${i + 1}' : item.materialName;
      final qty = (double.tryParse(item.quantity) ?? 0);
      newRequests.add(PurchaseRequest(
        id: '$baseId-$i',
        requestNo: prNo,
        material: mat,
        quantity: qty,
        unit: item.unit,
        requestedBy: _requestedByController.text.trim().isEmpty ? null : _requestedByController.text.trim(),
        date: _dateController.text.trim().isEmpty ? null : _dateController.text.trim(),
        status: 'Pending',
        priority: _priority,
        remarks: _generalRemarksController.text.trim().isEmpty ? null : _generalRemarksController.text.trim(),
      ));
    }
    if (newRequests.isEmpty) {
      newRequests.add(PurchaseRequest(
        id: baseId,
        requestNo: prNo,
        material: 'Draft',
        quantity: 0,
        unit: 'Nos',
        requestedBy: _requestedByController.text.trim().isEmpty ? null : _requestedByController.text.trim(),
        date: _dateController.text.trim().isEmpty ? null : _dateController.text.trim(),
        status: 'Draft',
        priority: _priority,
        remarks: _generalRemarksController.text.trim().isEmpty ? null : _generalRemarksController.text.trim(),
      ));
    }
    widget.onSubmitted(newRequests);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepIndicator(),
        const SizedBox(height: 24),
        Flexible(
          child: SingleChildScrollView(
            child: _step == 0 ? _buildStep1() : _step == 1 ? _buildStep2() : _buildStep3(),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            MadButton(text: 'Cancel', variant: ButtonVariant.outline, onPressed: widget.onCancel),
            const SizedBox(width: 12),
            if (_step > 0)
              MadButton(
                text: 'Back',
                variant: ButtonVariant.outline,
                onPressed: () => setState(() => _step--),
              ),
            if (_step > 0) const SizedBox(width: 12),
            if (_step == 2) ...[
              MadButton(text: 'Save Draft', variant: ButtonVariant.secondary, onPressed: widget.onSaveDraft),
              const SizedBox(width: 12),
              MadButton(text: 'Submit', onPressed: _submit),
            ] else
              MadButton(
                text: _step == 0 ? 'Next' : 'Next',
                onPressed: () => setState(() => _step++),
              ),
          ],
        ),
      ],
    );
  }
}
