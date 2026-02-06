import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../components/ui/components.dart';
import '../components/layout/main_layout.dart';

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

/// Purchase Requests page matching React's PurchaseRequests page
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return ProtectedRoute(
      title: 'Purchase Requests',
      route: '/purchase-requests',
      child: Column(
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
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                      ),
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
                width: 150,
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
                                  return _buildTableRow(_paginatedRequests[index], isDark, isMobile);
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

  Widget _buildTableRow(PurchaseRequest request, bool isDark, bool isMobile) {
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

    BadgeVariant priorityVariant;
    switch (request.priority) {
      case 'High':
        priorityVariant = BadgeVariant.destructive;
        break;
      case 'Medium':
        priorityVariant = BadgeVariant.secondary;
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
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.material, style: const TextStyle(fontWeight: FontWeight.w500)),
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
              child: Text('${request.quantity.toStringAsFixed(0)} ${request.unit}'),
            ),
            Expanded(
              flex: 1,
              child: Text(request.requestedBy ?? '-'),
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
              if (request.status == 'Pending') ...[
                MadMenuItem(label: 'Approve', icon: LucideIcons.circleCheck, onTap: () {}),
                MadMenuItem(label: 'Reject', icon: LucideIcons.circleX, destructive: true, onTap: () {}),
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
      maxWidth: 500,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MadSelect<String>(
            labelText: 'Material',
            placeholder: 'Select material',
            searchable: true,
            options: const [
              MadSelectOption(value: 'cement', label: 'Cement OPC 53'),
              MadSelectOption(value: 'pvc', label: 'PVC Pipe 4"'),
              MadSelectOption(value: 'steel', label: 'Steel Rods 12mm'),
            ],
            onChanged: (value) {},
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MadInput(
                  labelText: 'Quantity',
                  hintText: 'Enter quantity',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MadSelect<String>(
                  labelText: 'Unit',
                  placeholder: 'Select',
                  options: const [
                    MadSelectOption(value: 'bags', label: 'Bags'),
                    MadSelectOption(value: 'meters', label: 'Meters'),
                    MadSelectOption(value: 'kg', label: 'KG'),
                  ],
                  onChanged: (value) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MadSelect<String>(
            labelText: 'Priority',
            placeholder: 'Select priority',
            options: const [
              MadSelectOption(value: 'High', label: 'High'),
              MadSelectOption(value: 'Medium', label: 'Medium'),
              MadSelectOption(value: 'Low', label: 'Low'),
            ],
            onChanged: (value) {},
          ),
          const SizedBox(height: 16),
          MadTextarea(
            labelText: 'Remarks',
            hintText: 'Additional notes...',
            minLines: 2,
          ),
        ],
      ),
      actions: [
        MadButton(
          text: 'Cancel',
          variant: ButtonVariant.outline,
          onPressed: () => Navigator.pop(context),
        ),
        MadButton(
          text: 'Submit Request',
          onPressed: () {
            Navigator.pop(context);
            _loadRequests();
          },
        ),
      ],
    );
  }
}
