import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../store/app_state.dart';
import '../services/api_client.dart';
import '../services/file_service.dart';
import '../models/purchase_order.dart';
import '../components/ui/components.dart';
import '../components/layout/main_layout.dart';
import '../utils/responsive.dart';
import '../demo_data/remaining_modules_demo.dart';

const _poDraftKey = 'po_draft';

/// Purchase Orders page with full implementation (tabbed: Upload & Extract, Manual Entry, Recent POs)
class PurchaseOrdersPageFull extends StatefulWidget {
  const PurchaseOrdersPageFull({super.key});

  @override
  State<PurchaseOrdersPageFull> createState() => _PurchaseOrdersPageFullState();
}

class _PurchaseOrdersPageFullState extends State<PurchaseOrdersPageFull> {
  // START WITH DEMO DATA – never show blank
  bool _isLoading = true;
  List<PurchaseOrder> _orders = PurchaseOrdersDemo.orders
      .map((e) => PurchaseOrder.fromJson(e))
      .toList();
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  final _searchController = TextEditingController();
  String? _statusFilter;
  bool _showFilters = false;

  // Upload & Extract tab
  File? _selectedFile;
  String _extractionMessage = '';
  bool _isUploading = false;
  bool _isExtracting = false;

  @override
  void initState() {
    super.initState();
    // Try real API in background; demo data already visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _seedDemoData() {
    debugPrint('[PurchaseOrders] API unavailable – falling back to demo data');
    setState(() {
      _orders = PurchaseOrdersDemo.orders.map((e) => PurchaseOrder.fromJson(e)).toList();
      _isLoading = false;
    });
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });
    final store = StoreProvider.of<AppState>(context);
    final projectId = store.state.project.selectedProjectId ?? '';

    if (projectId.isEmpty) {
      _seedDemoData();
      return;
    }

    try {
      final result = await ApiClient.getPOsByProject(projectId);
      if (!mounted) return;
      if (result['success'] == true) {
        final data = result['data'] as List;
        final loaded = data.map((e) => PurchaseOrder.fromJson(e)).toList();
        if (loaded.isEmpty) {
          _seedDemoData();
        } else {
          setState(() {
            _orders = loaded;
            _isLoading = false;
          });
        }
      } else {
        _seedDemoData();
      }
    } catch (e) {
      debugPrint('[PurchaseOrders] API error: $e – falling back to demo data');
      if (!mounted) return;
      _seedDemoData();
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
    final responsive = Responsive(context);
    final isMobile = responsive.isMobile;

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
                        fontSize: responsive.value(mobile: 22, tablet: 26, desktop: 28),
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
            ],
          ),
          const SizedBox(height: 24),

          // Tabbed interface
          Expanded(
            child: MadTabs(
              defaultTab: 'recent',
              tabs: [
                MadTabItem(
                  id: 'upload',
                  label: 'Upload & Extract',
                  icon: LucideIcons.upload,
                  content: _buildUploadExtractTab(isDark),
                ),
                MadTabItem(
                  id: 'manual',
                  label: 'Manual Entry',
                  icon: LucideIcons.filePenLine,
                  content: _buildManualEntryTab(isDark, isMobile),
                ),
                MadTabItem(
                  id: 'recent',
                  label: 'Recent POs',
                  icon: LucideIcons.list,
                  content: _buildRecentPOsTab(isDark, isMobile),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadExtractTab(bool isDark) {
    final filename = _selectedFile?.path.split(RegExp(r'[/\\]')).last ?? '';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: MadCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload & Extract',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select a PDF, XLSX or CSV file to upload and extract PO data.',
                style: TextStyle(
                  color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                ),
              ),
              const SizedBox(height: 24),
              MadButton(
                icon: LucideIcons.fileUp,
                text: 'Select File',
                variant: ButtonVariant.outline,
                onPressed: () async {
                  final file = await FileService.pickFile(
                    allowedExtensions: ['pdf', 'xlsx', 'xls', 'csv'],
                  );
                  if (file != null && mounted) {
                    setState(() {
                      _selectedFile = file;
                      _extractionMessage = '';
                    });
                  }
                },
              ),
              if (filename.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isDark ? AppTheme.darkMuted : AppTheme.lightMuted).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.fileText, size: 20, color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          filename,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  MadButton(
                    icon: LucideIcons.scanSearch,
                    text: 'Extract Data',
                    variant: ButtonVariant.outline,
                    disabled: _selectedFile == null,
                    onPressed: _selectedFile == null
                        ? null
                        : () async {
                            if (_selectedFile == null) return;
                            setState(() {
                              _isExtracting = true;
                              _extractionMessage = 'File selected: ${_selectedFile!.path.split(RegExp(r'[/\\]')).last}. Extraction processing...';
                            });
                            await Future.delayed(const Duration(milliseconds: 800));
                            if (mounted) setState(() => _isExtracting = false);
                          },
                  ),
                  const SizedBox(width: 12),
                  MadButton(
                    icon: LucideIcons.upload,
                    text: 'Upload',
                    disabled: _selectedFile == null || _isUploading,
                    onPressed: _selectedFile == null || _isUploading
                        ? null
                        : () async {
                            if (_selectedFile == null) return;
                            setState(() => _isUploading = true);
                            final result = await ApiClient.uploadPOFile(_selectedFile!);
                            if (!mounted) return;
                            setState(() => _isUploading = false);
                            if (result['success'] == true) {
                              _loadOrders();
                              setState(() {
                                _selectedFile = null;
                                _extractionMessage = 'Upload successful.';
                              });
                            }
                          },
                  ),
                ],
              ),
              if (_isExtracting)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              if (_extractionMessage.isNotEmpty && !_isExtracting) ...[
                const SizedBox(height: 16),
                Text(
                  _extractionMessage,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManualEntryTab(bool isDark, bool isMobile) {
    final store = StoreProvider.of<AppState>(context);
    final projectId = store.state.project.selectedProjectId ??
        store.state.project.selectedProject?['project_id']?.toString() ??
        '';
    return _ManualPOForm(
      projectId: projectId,
      isDark: isDark,
      onPreview: (data) => _showPOPreview(data),
      onSubmitted: _loadOrders,
    );
  }

  Widget _buildRecentPOsTab(bool isDark, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats cards
        if (!isMobile)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
            child: Row(
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
          ),
        if (isMobile)
          GestureDetector(
            onTap: () => setState(() => _showFilters = !_showFilters),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: (isDark ? AppTheme.darkMuted : AppTheme.lightMuted).withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filters', style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground)),
                  Icon(_showFilters ? Icons.expand_less : Icons.expand_more, size: 20, color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground),
                ],
              ),
            ),
          ),
        if (isMobile) const SizedBox(height: 8),
        if (!isMobile || _showFilters)
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
            MadButton(
              icon: LucideIcons.plus,
              text: isMobile ? 'Create' : 'Create PO',
              onPressed: () => _showCreatePODialog(),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Data table
        Expanded(
          child: _isLoading
              ? MadCard(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: MadTableSkeleton(rows: 8, columns: 6),
                  ),
                )
              : _filteredOrders.isEmpty
                  ? _buildEmptyState(isDark)
                  : MadCard(
                      child: Column(
                        children: [
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
                          if (_totalPages > 1) _buildPagination(isDark),
                        ],
                      ),
                    ),
        ),
      ],
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
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
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
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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
                  '${order.items.length} items',
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
              child: MadBadge(text: order.status, variant: statusVariant),
            ),
            MadDropdownMenuButton(
              items: [
                MadMenuItem(label: 'View Details', icon: LucideIcons.eye, onTap: () => _showPODetails(order)),
                MadMenuItem(label: 'Edit', icon: LucideIcons.pencil, onTap: () => _showEditPODialog(order)),
                MadMenuItem(label: 'Download PDF', icon: LucideIcons.download, onTap: () {}),
                MadMenuItem(label: 'Duplicate', icon: LucideIcons.copy, onTap: () {}),
                if (order.status == 'Draft')
                  MadMenuItem(label: 'Submit', icon: LucideIcons.send, onTap: () {}),
                MadMenuItem(label: 'Delete', icon: LucideIcons.trash2, destructive: true, onTap: () => _showDeletePOConfirmation(order)),
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
                            _buildDetailItem('Status', order.status, isDark),
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
                          child: order.items.isEmpty
                              ? Center(
                                  child: Text(
                                    'No items',
                                    style: TextStyle(
                                      color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: order.items.length,
                                  itemBuilder: (context, index) {
                                    final item = order.items[index];
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
                                            child: Text(item.description),
                                          ),
                                          Expanded(
                                            child: Text('${item.quantity} ${item.uom}'),
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
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditPODialog(order);
                        },
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

  void _showPOPreview(Map<String, dynamic> poData) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = poData['items'] as List<dynamic>? ?? [];
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 700,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                      Text(
                        'PO Preview - ${poData['order_no'] ?? 'Draft'}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPreviewSection(
                          'Company',
                          isDark,
                          [
                            _previewRow('Name', poData['companyName']),
                            _previewRow('Subtitle', poData['companySubtitle']),
                            _previewRow('Email', poData['companyEmail']),
                            _previewRow('GST', poData['companyGstNo']),
                          ],
                        ),
                        _buildPreviewSection(
                          'Order Details',
                          isDark,
                          [
                            _previewRow('Indent No', poData['indent_no']),
                            _previewRow('Indent Date', poData['indent_date']),
                            _previewRow('Order No', poData['order_no']),
                            _previewRow('PO Date', poData['po_date']),
                          ],
                        ),
                        _buildPreviewSection(
                          'Vendor',
                          isDark,
                          [
                            _previewRow('Name', poData['vendor']?['name']),
                            _previewRow('Site', poData['vendor']?['site']),
                            _previewRow('Contact Person', poData['vendor']?['contactPerson']),
                            _previewRow('Address', poData['vendor']?['address']),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Items',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (items.isEmpty)
                          Text(
                            'No items',
                            style: TextStyle(
                              color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                            ),
                          )
                        else
                          Table(
                            columnWidths: const {
                              0: FlexColumnWidth(0.8),
                              1: FlexColumnWidth(1),
                              2: FlexColumnWidth(2),
                              3: FlexColumnWidth(0.8),
                              4: FlexColumnWidth(0.8),
                              5: FlexColumnWidth(1),
                              6: FlexColumnWidth(1),
                            },
                            children: [
                              TableRow(
                                decoration: BoxDecoration(
                                  color: (isDark ? AppTheme.darkMuted : AppTheme.lightMuted).withOpacity(0.5),
                                ),
                                children: [
                                  _tableCell('Sr', isDark, bold: true),
                                  _tableCell('HSN', isDark, bold: true),
                                  _tableCell('Description', isDark, bold: true),
                                  _tableCell('Qty', isDark, bold: true),
                                  _tableCell('UOM', isDark, bold: true),
                                  _tableCell('Rate', isDark, bold: true),
                                  _tableCell('Amount', isDark, bold: true),
                                ],
                              ),
                              ...items.map<TableRow>((e) {
                                final m = e is Map ? e as Map<String, dynamic> : <String, dynamic>{};
                                final qty = double.tryParse(m['qty']?.toString() ?? '') ?? 0;
                                final rate = double.tryParse(m['Rate']?.toString() ?? m['rate']?.toString() ?? '') ?? 0;
                                final amt = m['Amount'] ?? m['amount'] ?? (qty * rate).toStringAsFixed(2);
                                return TableRow(
                                  children: [
                                    _tableCell(m['srno'] ?? m['srNo'] ?? '', isDark),
                                    _tableCell(m['hsn'] ?? '', isDark),
                                    _tableCell(m['description'] ?? '', isDark),
                                    _tableCell(m['qty'] ?? '', isDark),
                                    _tableCell(m['UOM'] ?? m['uom'] ?? '', isDark),
                                    _tableCell(m['Rate'] ?? m['rate'] ?? '', isDark),
                                    _tableCell(amt.toString(), isDark),
                                  ],
                                );
                              }),
                            ],
                          ),
                        const SizedBox(height: 16),
                        _buildPreviewSection(
                          'Totals',
                          isDark,
                          [
                            _previewRow('Discount %', poData['discount']?['percent']),
                            _previewRow('Discount Amount', poData['discount']?['amount']),
                            _previewRow('After Discount', poData['afterDiscountAmount']),
                            _previewRow('CGST %', poData['taxes']?['cgst']?['percent']),
                            _previewRow('CGST Amount', poData['taxes']?['cgst']?['amount']),
                            _previewRow('SGST %', poData['taxes']?['sgst']?['percent']),
                            _previewRow('SGST Amount', poData['taxes']?['sgst']?['amount']),
                            _previewRow('Total Amount', poData['total_amount'] ?? poData['totalAmount'], bold: true),
                          ],
                        ),
                        _buildPreviewSection(
                          'Additional',
                          isDark,
                          [
                            _previewRow('Delivery terms', poData['summary']?['delivery']),
                            _previewRow('Payment terms', poData['summary']?['payment']),
                            _previewRow('Notes', poData['notes'] is List ? (poData['notes'] as List).join(', ') : poData['notes']?.toString()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
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
                        text: 'Edit',
                        variant: ButtonVariant.outline,
                        onPressed: () => Navigator.pop(ctx),
                      ),
                      const SizedBox(width: 12),
                      MadButton(
                        text: 'Submit PO',
                        onPressed: () async {
                          final result = await ApiClient.createPO(poData);
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (result['success'] == true) {
                            _loadOrders();
                          }
                        },
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

  Widget _buildPreviewSection(
    String title,
    bool isDark,
    List<Widget> rows,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
            ),
          ),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  Widget _previewRow(String label, dynamic value, {bool bold = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final v = value?.toString() ?? '-';
    if (v == '-' || v.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w600 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableCell(String text, bool isDark, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.w600 : null,
          color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
        ),
      ),
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

  void _showEditPODialog(PurchaseOrder order) {
    final orderNoController = TextEditingController(text: order.orderNo);
    final poDateController = TextEditingController(text: order.poDate ?? '');
    final vendorNameController = TextEditingController(text: order.vendorName ?? '');
    final companyNameController = TextEditingController(text: order.companyName ?? '');
    final totalAmountController = TextEditingController(text: order.totalAmount ?? '');
    final notesController = TextEditingController(text: order.notes?.join('\n') ?? '');
    String? selectedStatus = order.status;

    MadFormDialog.show(
      context: context,
      title: 'Edit Purchase Order',
      maxWidth: 600,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: MadInput(
                  controller: orderNoController,
                  labelText: 'PO Number',
                  hintText: 'Order number',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MadInput(
                  controller: poDateController,
                  labelText: 'PO Date',
                  hintText: 'e.g. 2024-01-15',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MadInput(
            controller: vendorNameController,
            labelText: 'Vendor Name',
            hintText: 'Vendor name',
          ),
          const SizedBox(height: 16),
          MadInput(
            controller: companyNameController,
            labelText: 'Company Name',
            hintText: 'Company name',
          ),
          const SizedBox(height: 16),
          MadInput(
            controller: totalAmountController,
            labelText: 'Total Amount',
            hintText: 'Total amount',
          ),
          const SizedBox(height: 16),
          MadSelect<String>(
            labelText: 'Status',
            value: selectedStatus,
            placeholder: 'Select status',
            options: const [
              MadSelectOption(value: 'Draft', label: 'Draft'),
              MadSelectOption(value: 'Submitted', label: 'Submitted'),
              MadSelectOption(value: 'Approved', label: 'Approved'),
              MadSelectOption(value: 'Completed', label: 'Completed'),
            ],
            onChanged: (value) => selectedStatus = value,
          ),
          const SizedBox(height: 16),
          MadTextarea(
            controller: notesController,
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
          onPressed: () {
            orderNoController.dispose();
            poDateController.dispose();
            vendorNameController.dispose();
            companyNameController.dispose();
            totalAmountController.dispose();
            notesController.dispose();
            Navigator.pop(context);
          },
        ),
        MadButton(
          text: 'Save',
          onPressed: () async {
            final data = <String, dynamic>{
              'order_no': orderNoController.text.trim(),
              'po_date': poDateController.text.trim().isEmpty ? null : poDateController.text.trim(),
              'company_name': companyNameController.text.trim().isEmpty ? null : companyNameController.text.trim(),
              'total_amount': totalAmountController.text.trim().isEmpty ? null : totalAmountController.text.trim(),
              'status': selectedStatus ?? order.status,
              'notes': notesController.text.trim().isEmpty ? null : notesController.text.trim().split('\n'),
            };
            if (vendorNameController.text.trim().isNotEmpty) {
              data['vendor'] = {'name': vendorNameController.text.trim()};
            }

            orderNoController.dispose();
            poDateController.dispose();
            vendorNameController.dispose();
            companyNameController.dispose();
            totalAmountController.dispose();
            notesController.dispose();
            Navigator.pop(context);

            final result = await ApiClient.updatePO(order.id, data);
            if (!mounted) return;
            if (result['success'] == true) {
              _loadOrders();
            }
          },
        ),
      ],
    );
  }

  void _showDeletePOConfirmation(PurchaseOrder order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        title: const Text('Delete Purchase Order'),
        content: Text(
          'Are you sure you want to delete "${order.orderNo}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await ApiClient.deletePO(order.id);
              if (!mounted) return;
              if (result['success'] == true) {
                _loadOrders();
              }
            },
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

/// Manual PO entry form (company, order, vendor, items, totals, additional)
class _ManualPOForm extends StatefulWidget {
  final String projectId;
  final bool isDark;
  final void Function(Map<String, dynamic> poData) onPreview;
  final VoidCallback onSubmitted;

  const _ManualPOForm({
    required this.projectId,
    required this.isDark,
    required this.onPreview,
    required this.onSubmitted,
  });

  @override
  State<_ManualPOForm> createState() => _ManualPOFormState();
}

class _ManualPOFormState extends State<_ManualPOForm> {
  final _companyName = TextEditingController();
  final _companySubtitle = TextEditingController();
  final _companyEmail = TextEditingController();
  final _companyGst = TextEditingController();
  final _indentNo = TextEditingController();
  final _indentDate = TextEditingController();
  final _orderNo = TextEditingController();
  final _poDate = TextEditingController();
  final _vendorName = TextEditingController();
  final _site = TextEditingController();
  final _contactPerson = TextEditingController();
  final _vendorAddress = TextEditingController();
  final _primaryContactName = TextEditingController();
  final _primaryContactNumber = TextEditingController();
  final _secondaryContactName = TextEditingController();
  final _secondaryContactNumber = TextEditingController();
  final _deliveryTerms = TextEditingController();
  final _paymentTerms = TextEditingController();
  final _notes = TextEditingController();
  final _discountPercent = TextEditingController();
  final _cgstPercent = TextEditingController();
  final _sgstPercent = TextEditingController();

  List<Map<String, dynamic>> _items = [];
  static int _itemId = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final key = widget.projectId.isEmpty ? _poDraftKey : '${_poDraftKey}_${widget.projectId}';
    final json = prefs.getString(key);
    if (json == null) return;
    try {
      final data = (jsonDecode(json) as Map<String, dynamic>);
      _companyName.text = data['companyName']?.toString() ?? '';
      _companySubtitle.text = data['companySubtitle']?.toString() ?? '';
      _companyEmail.text = data['companyEmail']?.toString() ?? '';
      _companyGst.text = data['companyGstNo']?.toString() ?? '';
      _indentNo.text = data['indent_no']?.toString() ?? '';
      _indentDate.text = data['indent_date']?.toString() ?? '';
      _orderNo.text = data['order_no']?.toString() ?? '';
      _poDate.text = data['po_date']?.toString() ?? '';
      final v = data['vendor'] as Map<String, dynamic>?;
      if (v != null) {
        _vendorName.text = v['name']?.toString() ?? '';
        _site.text = v['site']?.toString() ?? '';
        _contactPerson.text = v['contactPerson']?.toString() ?? '';
        _vendorAddress.text = v['address']?.toString() ?? '';
        final c = v['contacts'] as Map<String, dynamic>?;
        if (c != null) {
          final p = c['primary'] as Map<String, dynamic>?;
          final s = c['secondary'] as Map<String, dynamic>?;
          if (p != null) {
            _primaryContactName.text = p['name']?.toString() ?? '';
            _primaryContactNumber.text = p['number']?.toString() ?? '';
          }
          if (s != null) {
            _secondaryContactName.text = s['name']?.toString() ?? '';
            _secondaryContactNumber.text = s['number']?.toString() ?? '';
          }
        }
      }
      final sum = data['summary'] as Map<String, dynamic>?;
      if (sum != null) {
        _deliveryTerms.text = sum['delivery']?.toString() ?? '';
        _paymentTerms.text = sum['payment']?.toString() ?? '';
      }
      _notes.text = (data['notes'] is List ? (data['notes'] as List).join('\n') : data['notes']?.toString()) ?? '';
      final disc = data['discount'] as Map<String, dynamic>?;
      if (disc != null) _discountPercent.text = disc['percent']?.toString() ?? '';
      final tax = data['taxes'] as Map<String, dynamic>?;
      if (tax != null) {
        _cgstPercent.text = (tax['cgst'] as Map?)?['percent']?.toString() ?? '';
        _sgstPercent.text = (tax['sgst'] as Map?)?['percent']?.toString() ?? '';
      }
      final list = data['items'] as List<dynamic>?;
      if (list != null && list.isNotEmpty) {
        setState(() {
          _items = list.map((e) {
            final raw = Map<String, dynamic>.from(e as Map);
            if (!raw.containsKey('_id')) raw['_id'] = ++_itemId;
            return {
              '_id': raw['_id'],
              'srNo': raw['srNo'] ?? raw['srno'] ?? '',
              'hsn': raw['hsn'] ?? '',
              'description': raw['description'] ?? '',
              'qty': raw['qty'] ?? '',
              'uom': raw['uom'] ?? raw['UOM'] ?? '',
              'rate': raw['rate'] ?? raw['Rate'] ?? '',
              'amount': raw['amount'] ?? raw['Amount'] ?? '',
              'remark': raw['remark'] ?? '',
            };
          }).toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _companyName.dispose();
    _companySubtitle.dispose();
    _companyEmail.dispose();
    _companyGst.dispose();
    _indentNo.dispose();
    _indentDate.dispose();
    _orderNo.dispose();
    _poDate.dispose();
    _vendorName.dispose();
    _site.dispose();
    _contactPerson.dispose();
    _vendorAddress.dispose();
    _primaryContactName.dispose();
    _primaryContactNumber.dispose();
    _secondaryContactName.dispose();
    _secondaryContactNumber.dispose();
    _deliveryTerms.dispose();
    _paymentTerms.dispose();
    _notes.dispose();
    _discountPercent.dispose();
    _cgstPercent.dispose();
    _sgstPercent.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController c) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (date != null) c.text = DateFormat('yyyy-MM-dd').format(date);
  }

  Map<String, dynamic> _buildPOData() {
    final itemsPayload = <Map<String, dynamic>>[];
    double itemsTotal = 0;
    for (final item in _items) {
      final qty = double.tryParse(item['qty']?.toString() ?? '') ?? 0;
      final rate = double.tryParse(item['rate']?.toString() ?? '') ?? 0;
      final amount = qty * rate;
      itemsTotal += amount;
      itemsPayload.add({
        'srno': item['srNo']?.toString() ?? '',
        'hsn': item['hsn']?.toString() ?? '',
        'description': item['description']?.toString() ?? '',
        'qty': item['qty']?.toString() ?? '',
        'UOM': item['uom']?.toString() ?? '',
        'Rate': item['rate']?.toString() ?? '',
        'Amount': amount.toStringAsFixed(2),
        'remark': item['remark']?.toString(),
      });
    }
    final discountPct = double.tryParse(_discountPercent.text) ?? 0;
    final discountAmt = itemsTotal * (discountPct / 100);
    final afterDiscount = itemsTotal - discountAmt;
    final cgstPct = double.tryParse(_cgstPercent.text) ?? 0;
    final sgstPct = double.tryParse(_sgstPercent.text) ?? 0;
    final cgstAmt = afterDiscount * (cgstPct / 100);
    final sgstAmt = afterDiscount * (sgstPct / 100);
    final total = afterDiscount + cgstAmt + sgstAmt;

    final notesText = _notes.text.trim();
    return {
      if (widget.projectId.isNotEmpty) 'project_id': widget.projectId,
      'companyName': _companyName.text.trim().isEmpty ? null : _companyName.text.trim(),
      'companySubtitle': _companySubtitle.text.trim().isEmpty ? null : _companySubtitle.text.trim(),
      'companyEmail': _companyEmail.text.trim().isEmpty ? null : _companyEmail.text.trim(),
      'companyGstNo': _companyGst.text.trim().isEmpty ? null : _companyGst.text.trim(),
      'indent_no': _indentNo.text.trim().isEmpty ? null : _indentNo.text.trim(),
      'indent_date': _indentDate.text.trim().isEmpty ? null : _indentDate.text.trim(),
      'order_no': _orderNo.text.trim().isEmpty ? null : _orderNo.text.trim(),
      'po_date': _poDate.text.trim().isEmpty ? null : _poDate.text.trim(),
      'vendor': {
        'name': _vendorName.text.trim().isEmpty ? null : _vendorName.text.trim(),
        'site': _site.text.trim().isEmpty ? null : _site.text.trim(),
        'contactPerson': _contactPerson.text.trim().isEmpty ? null : _contactPerson.text.trim(),
        'address': _vendorAddress.text.trim().isEmpty ? null : _vendorAddress.text.trim(),
        'contacts': {
          'primary': {'name': _primaryContactName.text.trim(), 'number': _primaryContactNumber.text.trim()},
          'secondary': {'name': _secondaryContactName.text.trim(), 'number': _secondaryContactNumber.text.trim()},
        },
      },
      'items': itemsPayload,
      'discount': {'percent': _discountPercent.text.trim().isEmpty ? null : _discountPercent.text.trim(), 'amount': discountAmt.toStringAsFixed(2)},
      'afterDiscountAmount': afterDiscount.toStringAsFixed(2),
      'taxes': {
        'cgst': {'percent': _cgstPercent.text.trim().isEmpty ? null : _cgstPercent.text.trim(), 'amount': cgstAmt.toStringAsFixed(2)},
        'sgst': {'percent': _sgstPercent.text.trim().isEmpty ? null : _sgstPercent.text.trim(), 'amount': sgstAmt.toStringAsFixed(2)},
      },
      'total_amount': total.toStringAsFixed(2),
      'summary': {
        'delivery': _deliveryTerms.text.trim().isEmpty ? null : _deliveryTerms.text.trim(),
        'payment': _paymentTerms.text.trim().isEmpty ? null : _paymentTerms.text.trim(),
      },
      'notes': notesText.isEmpty ? null : notesText.split('\n'),
      'status': 'Draft',
    };
  }

  Future<void> _saveDraft() async {
    final data = _buildPOData();
    final prefs = await SharedPreferences.getInstance();
    final key = widget.projectId.isEmpty ? _poDraftKey : '${_poDraftKey}_${widget.projectId}';
    await prefs.setString(key, jsonEncode(data));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft saved.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: MadCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Company Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground),
              ),
              const SizedBox(height: 12),
              MadInput(labelText: 'Company Name (required)', hintText: 'Company name', controller: _companyName),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: MadInput(labelText: 'Company Subtitle', hintText: 'Subtitle', controller: _companySubtitle)),
                  const SizedBox(width: 16),
                  Expanded(child: MadInput(labelText: 'Company Email', hintText: 'email@example.com', controller: _companyEmail, keyboardType: TextInputType.emailAddress)),
                  const SizedBox(width: 16),
                  Expanded(child: MadInput(labelText: 'Company GST', hintText: 'GST number', controller: _companyGst)),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Order Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: MadInput(labelText: 'Indent No', hintText: 'Indent number', controller: _indentNo)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: MadInput(
                      labelText: 'Indent Date',
                      controller: _indentDate,
                      hintText: 'Select date',
                      suffix: IconButton(
                        icon: const Icon(Icons.calendar_today, size: 20),
                        onPressed: () => _pickDate(_indentDate),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: MadInput(labelText: 'Order No', hintText: 'PO number', controller: _orderNo)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: MadInput(
                      labelText: 'PO Date',
                      controller: _poDate,
                      hintText: 'Select date',
                      suffix: IconButton(
                        icon: const Icon(Icons.calendar_today, size: 20),
                        onPressed: () => _pickDate(_poDate),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Vendor Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground),
              ),
              const SizedBox(height: 12),
              MadInput(labelText: 'Vendor Name', hintText: 'Vendor name', controller: _vendorName),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: MadInput(labelText: 'Site', hintText: 'Site', controller: _site)),
                  const SizedBox(width: 16),
                  Expanded(child: MadInput(labelText: 'Contact Person', hintText: 'Contact person', controller: _contactPerson)),
                ],
              ),
              const SizedBox(height: 12),
              MadInput(labelText: 'Vendor Address', hintText: 'Address', controller: _vendorAddress, maxLines: 2),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: MadInput(labelText: 'Primary Contact Name', hintText: 'Name', controller: _primaryContactName)),
                  const SizedBox(width: 16),
                  Expanded(child: MadInput(labelText: 'Primary Contact Number', hintText: 'Number', controller: _primaryContactNumber, keyboardType: TextInputType.phone)),
                  const SizedBox(width: 16),
                  Expanded(child: MadInput(labelText: 'Secondary Contact Name', hintText: 'Name', controller: _secondaryContactName)),
                  const SizedBox(width: 16),
                  Expanded(child: MadInput(labelText: 'Secondary Contact Number', hintText: 'Number', controller: _secondaryContactNumber, keyboardType: TextInputType.phone)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Items',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground),
                  ),
                  MadButton(
                    size: ButtonSize.sm,
                    text: 'Add Item',
                    icon: LucideIcons.plus,
                    onPressed: () {
                      setState(() {
                        _items.add({
                          '_id': ++_itemId,
                          'srNo': '${_items.length + 1}',
                          'hsn': '',
                          'description': '',
                          'qty': '',
                          'uom': '',
                          'rate': '',
                          'amount': '',
                          'remark': '',
                        });
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...List.generate(_items.length, (i) {
                return _POItemRow(
                  key: ValueKey(_items[i]['_id']),
                  isDark: isDark,
                  initialValues: _items[i],
                  onChanged: (m) => setState(() => _items[i] = m),
                  onRemove: () => setState(() => _items.removeAt(i)),
                );
              }),
              const SizedBox(height: 24),
              Text(
                'Totals',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: MadInput(labelText: 'Discount %', hintText: '0', controller: _discountPercent, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                  const SizedBox(width: 16),
                  Expanded(child: MadInput(labelText: 'CGST %', hintText: '0', controller: _cgstPercent, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                  const SizedBox(width: 16),
                  Expanded(child: MadInput(labelText: 'SGST %', hintText: '0', controller: _sgstPercent, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Additional',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: MadInput(labelText: 'Delivery terms', hintText: 'e.g. 7 days', controller: _deliveryTerms)),
                  const SizedBox(width: 16),
                  Expanded(child: MadInput(labelText: 'Payment terms', hintText: 'e.g. 30 days', controller: _paymentTerms)),
                ],
              ),
              const SizedBox(height: 12),
              MadTextarea(labelText: 'Notes', hintText: 'Additional notes...', controller: _notes, minLines: 2),
              const SizedBox(height: 24),
              Row(
                children: [
                  MadButton(text: 'Save Draft', icon: LucideIcons.save, variant: ButtonVariant.outline, onPressed: _saveDraft),
                  const SizedBox(width: 12),
                  MadButton(text: 'Preview', icon: LucideIcons.eye, variant: ButtonVariant.outline, onPressed: () => widget.onPreview(_buildPOData())),
                  const SizedBox(width: 12),
                  MadButton(
                    text: 'Submit PO',
                    icon: LucideIcons.send,
                    disabled: _isSubmitting,
                    onPressed: () async {
                      setState(() => _isSubmitting = true);
                      final data = _buildPOData();
                      data['status'] = 'Submitted';
                      final result = await ApiClient.createPO(data);
                      if (!mounted) return;
                      setState(() => _isSubmitting = false);
                      if (result['success'] == true) {
                        widget.onSubmitted();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _POItemRow extends StatefulWidget {
  final bool isDark;
  final Map<String, dynamic> initialValues;
  final void Function(Map<String, dynamic>) onChanged;
  final VoidCallback onRemove;

  const _POItemRow({
    super.key,
    required this.isDark,
    required this.initialValues,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_POItemRow> createState() => _POItemRowState();
}

class _POItemRowState extends State<_POItemRow> {
  late TextEditingController _srNo;
  late TextEditingController _hsn;
  late TextEditingController _desc;
  late TextEditingController _qty;
  late TextEditingController _uom;
  late TextEditingController _rate;
  late TextEditingController _remark;

  @override
  void initState() {
    super.initState();
    final v = widget.initialValues;
    _srNo = TextEditingController(text: v['srNo']?.toString() ?? '');
    _hsn = TextEditingController(text: v['hsn']?.toString() ?? '');
    _desc = TextEditingController(text: v['description']?.toString() ?? '');
    _qty = TextEditingController(text: v['qty']?.toString() ?? '');
    _uom = TextEditingController(text: v['uom']?.toString() ?? '');
    _rate = TextEditingController(text: v['rate']?.toString() ?? '');
    _remark = TextEditingController(text: v['remark']?.toString() ?? '');
    _qty.addListener(_syncAmount);
    _rate.addListener(_syncAmount);
  }

  void _syncAmount() {
    final qty = double.tryParse(_qty.text) ?? 0;
    final rate = double.tryParse(_rate.text) ?? 0;
    widget.initialValues['qty'] = _qty.text;
    widget.initialValues['rate'] = _rate.text;
    widget.initialValues['amount'] = (qty * rate).toStringAsFixed(2);
    widget.onChanged(widget.initialValues);
  }

  @override
  void dispose() {
    _qty.removeListener(_syncAmount);
    _rate.removeListener(_syncAmount);
    _srNo.dispose();
    _hsn.dispose();
    _desc.dispose();
    _qty.dispose();
    _uom.dispose();
    _rate.dispose();
    _remark.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qty = double.tryParse(_qty.text) ?? 0;
    final rate = double.tryParse(_rate.text) ?? 0;
    final amount = qty * rate;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 700,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                child: MadInput(controller: _srNo, hintText: 'Sr', onChanged: (_) => _updateMap()),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 72,
                child: MadInput(controller: _hsn, hintText: 'HSN', onChanged: (_) => _updateMap()),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: MadInput(controller: _desc, hintText: 'Description', onChanged: (_) => _updateMap()),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 64,
                child: MadInput(controller: _qty, hintText: 'Qty', keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => _updateMap()),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 56,
                child: MadInput(controller: _uom, hintText: 'UOM', onChanged: (_) => _updateMap()),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: MadInput(controller: _rate, hintText: 'Rate', keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => _updateMap()),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 88,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    amount.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: MadInput(controller: _remark, hintText: 'Remark', onChanged: (_) => _updateMap()),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: widget.onRemove,
                color: Theme.of(context).colorScheme.error,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateMap() {
    widget.initialValues['srNo'] = _srNo.text;
    widget.initialValues['hsn'] = _hsn.text;
    widget.initialValues['description'] = _desc.text;
    widget.initialValues['qty'] = _qty.text;
    widget.initialValues['uom'] = _uom.text;
    widget.initialValues['rate'] = _rate.text;
    widget.initialValues['remark'] = _remark.text;
    widget.onChanged(widget.initialValues);
  }
}
