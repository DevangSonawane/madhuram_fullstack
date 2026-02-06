import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../store/app_state.dart';
import '../services/api_client.dart';
import '../models/purchase_order.dart';
import '../components/ui/components.dart';
import '../components/layout/main_layout.dart';

/// Purchase Orders page with full implementation
class PurchaseOrdersPageFull extends StatefulWidget {
  const PurchaseOrdersPageFull({super.key});

  @override
  State<PurchaseOrdersPageFull> createState() => _PurchaseOrdersPageFullState();
}

class _PurchaseOrdersPageFullState extends State<PurchaseOrdersPageFull> {
  bool _isLoading = true;
  List<PurchaseOrder> _orders = [];
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  final _searchController = TextEditingController();
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    final store = StoreProvider.of<AppState>(context);
    final projectId = store.state.project.selectedProjectId ?? '';

    if (projectId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final result = await ApiClient.getPOsByProject(projectId);

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'] as List;
      setState(() {
        _orders = data.map((e) => PurchaseOrder.fromJson(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  List<PurchaseOrder> get _filteredOrders {
    List<PurchaseOrder> result = _orders;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((o) {
        return o.orderNo.toLowerCase().contains(query) ||
            (o.vendorName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    if (_statusFilter != null) {
      result = result.where((o) => o.status == _statusFilter).toList();
    }

    return result;
  }

  List<PurchaseOrder> get _paginatedOrders {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;
    final filtered = _filteredOrders;
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end > filtered.length ? filtered.length : end);
  }

  int get _totalPages => (_filteredOrders.length / _itemsPerPage).ceil();

  double get _totalValue => _orders.fold(0.0, (sum, o) => sum + (o.totalAmountValue ?? 0.0));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return ProtectedRoute(
      title: 'Purchase Orders',
      route: '/purchase-orders',
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
                      'Purchase Orders',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage purchase orders and vendor transactions',
                      style: TextStyle(
                        color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                MadButton(
                  text: 'Create PO',
                  icon: LucideIcons.plus,
                  onPressed: () => _showCreatePODialog(),
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
                    title: 'Total Orders',
                    value: _orders.length.toString(),
                    icon: LucideIcons.shoppingCart,
                    iconColor: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Total Value',
                    value: '₹${(_totalValue / 1000).toStringAsFixed(1)}K',
                    icon: LucideIcons.indianRupee,
                    iconColor: const Color(0xFF22C55E),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Draft',
                    value: _orders.where((o) => o.status == 'Draft').length.toString(),
                    icon: LucideIcons.filePenLine,
                    iconColor: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Submitted',
                    value: _orders.where((o) => o.status == 'Submitted').length.toString(),
                    icon: LucideIcons.circleCheck,
                    iconColor: const Color(0xFF8B5CF6),
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
                  hintText: 'Search purchase orders...',
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
                    MadSelectOption(value: 'Draft', label: 'Draft'),
                    MadSelectOption(value: 'Submitted', label: 'Submitted'),
                    MadSelectOption(value: 'Approved', label: 'Approved'),
                    MadSelectOption(value: 'Completed', label: 'Completed'),
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
                  text: 'Create',
                  onPressed: () => _showCreatePODialog(),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Data table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOrders.isEmpty
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
                                  _buildHeaderCell('PO Number', flex: 1, isDark: isDark),
                                  _buildHeaderCell('Vendor', flex: 2, isDark: isDark),
                                  if (!isMobile) ...[
                                    _buildHeaderCell('Date', flex: 1, isDark: isDark),
                                    _buildHeaderCell('Items', flex: 1, isDark: isDark),
                                    _buildHeaderCell('Amount', flex: 1, isDark: isDark),
                                  ],
                                  _buildHeaderCell('Status', flex: 1, isDark: isDark),
                                  const SizedBox(width: 48),
                                ],
                              ),
                            ),
                            // Table rows
                            Expanded(
                              child: ListView.separated(
                                itemCount: _paginatedOrders.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5),
                                ),
                                itemBuilder: (context, index) {
                                  return _buildTableRow(_paginatedOrders[index], isDark, isMobile);
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

  Widget _buildTableRow(PurchaseOrder order, bool isDark, bool isMobile) {
    BadgeVariant statusVariant;
    switch (order.status) {
      case 'Submitted':
        statusVariant = BadgeVariant.default_;
        break;
      case 'Draft':
        statusVariant = BadgeVariant.secondary;
        break;
      case 'Approved':
        statusVariant = BadgeVariant.outline;
        break;
      case 'Completed':
        statusVariant = BadgeVariant.default_;
        break;
      default:
        statusVariant = BadgeVariant.secondary;
    }

    return InkWell(
      onTap: () => _showPODetails(order),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Text(
                order.orderNo,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.vendorName ?? 'Unknown Vendor',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (isMobile && order.totalAmountValue != null)
                    Text(
                      '₹${order.totalAmountValue!.toStringAsFixed(2)}',
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
                child: Text(
                  order.poDate ?? '-',
                  style: TextStyle(
                    color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '${order.items?.length ?? 0} items',
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  order.totalAmountValue != null ? '₹${order.totalAmountValue!.toStringAsFixed(2)}' : (order.totalAmount ?? '-'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
            Expanded(
              flex: 1,
              child: MadBadge(text: order.status ?? 'Draft', variant: statusVariant),
            ),
            MadDropdownMenuButton(
              items: [
                MadMenuItem(label: 'View Details', icon: LucideIcons.eye, onTap: () => _showPODetails(order)),
                MadMenuItem(label: 'Edit', icon: LucideIcons.pencil, onTap: () {}),
                MadMenuItem(label: 'Download PDF', icon: LucideIcons.download, onTap: () {}),
                MadMenuItem(label: 'Duplicate', icon: LucideIcons.copy, onTap: () {}),
                if (order.status == 'Draft')
                  MadMenuItem(label: 'Submit', icon: LucideIcons.send, onTap: () {}),
                MadMenuItem(label: 'Delete', icon: LucideIcons.trash2, destructive: true, onTap: () {}),
              ],
            ),
          ],
        ),
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
            'Showing ${(_currentPage - 1) * _itemsPerPage + 1}-${_currentPage * _itemsPerPage > _filteredOrders.length ? _filteredOrders.length : _currentPage * _itemsPerPage} of ${_filteredOrders.length}',
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
              LucideIcons.shoppingCart,
              size: 64,
              color: (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground).withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty ? 'No purchase orders yet' : 'No orders found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Create your first purchase order to get started'
                  : 'Try a different search term',
              style: TextStyle(
                color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              MadButton(
                text: 'Create PO',
                icon: LucideIcons.plus,
                onPressed: () => _showCreatePODialog(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPODetails(PurchaseOrder order) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.orderNo,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.vendorName ?? 'Unknown Vendor',
                            style: TextStyle(
                              color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildDetailItem('Date', order.poDate ?? '-', isDark),
                            const SizedBox(width: 32),
                            _buildDetailItem('Status', order.status ?? 'Draft', isDark),
                            const SizedBox(width: 32),
                            _buildDetailItem('Total', '₹${order.totalAmountValue?.toStringAsFixed(2) ?? order.totalAmount ?? '0'}', isDark),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Items',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: order.items == null || order.items!.isEmpty
                              ? Center(
                                  child: Text(
                                    'No items',
                                    style: TextStyle(
                                      color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: order.items!.length,
                                  itemBuilder: (context, index) {
                                    final item = order.items![index];
                                    return Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5),
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Text(item.description ?? '-'),
                                          ),
                                          Expanded(
                                            child: Text('${item.quantity} ${item.uom ?? ''}'),
                                          ),
                                          Expanded(
                                            child: Text('₹${item.rate}'),
                                          ),
                                          Expanded(
                                            child: Text(
                                              '₹${item.amount}',
                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      MadButton(
                        text: 'Download PDF',
                        icon: LucideIcons.download,
                        variant: ButtonVariant.outline,
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                      MadButton(
                        text: 'Edit',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  void _showCreatePODialog() {
    MadFormDialog.show(
      context: context,
      title: 'Create Purchase Order',
      maxWidth: 600,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: MadInput(
                  labelText: 'PO Number',
                  hintText: 'Auto-generated',
                  enabled: false,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MadInput(
                  labelText: 'PO Date',
                  hintText: 'Select date',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MadSelect<String>(
            labelText: 'Vendor',
            placeholder: 'Select vendor',
            searchable: true,
            options: const [
              MadSelectOption(value: 'abc', label: 'ABC Suppliers'),
              MadSelectOption(value: 'xyz', label: 'XYZ Traders'),
              MadSelectOption(value: 'pqr', label: 'PQR Industries'),
            ],
            onChanged: (value) {},
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MadInput(
                  labelText: 'Delivery Terms',
                  hintText: 'e.g. 7 days',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MadInput(
                  labelText: 'Payment Terms',
                  hintText: 'e.g. 30 days',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MadTextarea(
            labelText: 'Notes',
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
          text: 'Create PO',
          onPressed: () {
            Navigator.pop(context);
            _loadOrders();
          },
        ),
      ],
    );
  }
}
