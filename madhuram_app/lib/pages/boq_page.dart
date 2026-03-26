import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../store/app_state.dart';
import '../services/api_client.dart';
import '../services/pdf_service.dart';
import '../services/excel_service.dart';
import '../services/boq_extractor.dart';
import '../models/boq.dart';
import '../components/ui/mad_card.dart';
import '../components/ui/mad_button.dart';
import '../components/ui/mad_badge.dart';
import '../components/ui/mad_input.dart';
import '../components/layout/main_layout.dart';
import '../utils/error_handler.dart';
import '../components/ui/mad_skeleton.dart';
import '../utils/responsive.dart';

/// BOQ Management page matching React's BOQ.jsx
class BOQPage extends StatefulWidget {
  const BOQPage({super.key});

  @override
  State<BOQPage> createState() => _BOQPageState();
}

class _AddBOQItemPage extends StatefulWidget {
  final String projectId;

  const _AddBOQItemPage({required this.projectId});

  @override
  State<_AddBOQItemPage> createState() => _AddBOQItemPageState();
}

class _AddBOQItemPageState extends State<_AddBOQItemPage> {
  final _itemCodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _rateController = TextEditingController();
  final _floorController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _itemCodeController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _rateController.dispose();
    _floorController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final quantity = double.tryParse(_quantityController.text.trim()) ?? 0;
    final rate = double.tryParse(_rateController.text.trim()) ?? 0;
    final amount = quantity * rate;

    final data = {
      'project_id': widget.projectId,
      'item_code': _itemCodeController.text.trim(),
      'description': _descriptionController.text.trim(),
      'category': _categoryController.text.trim(),
      'floor': _floorController.text.trim(),
      'quantity': quantity.toString(),
      'unit': _unitController.text.trim(),
      'rate': rate.toString(),
      'amount': amount.toString(),
    };

    final result = await ApiClient.createBOQ(data);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result['success'] == true) {
      Navigator.of(context).pop(true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ErrorHandler.getMessage(result['error'] ?? 'Failed to add item'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add BOQ Item'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(responsive.value(mobile: 16, tablet: 20, desktop: 24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MadCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        MadInput(
                          controller: _itemCodeController,
                          labelText: 'Item Code',
                          hintText: 'Enter item code',
                        ),
                        const SizedBox(height: 16),
                        MadInput(
                          controller: _descriptionController,
                          labelText: 'Description',
                          hintText: 'Enter description',
                        ),
                        const SizedBox(height: 16),
                        MadInput(
                          controller: _categoryController,
                          labelText: 'Category',
                          hintText: 'Enter category',
                        ),
                        const SizedBox(height: 16),
                        MadInput(
                          controller: _floorController,
                          labelText: 'Floor',
                          hintText: 'Enter floor',
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: MadInput(
                                controller: _quantityController,
                                labelText: 'Quantity',
                                hintText: '0',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: MadInput(
                                controller: _unitController,
                                labelText: 'Unit',
                                hintText: 'e.g. KG',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        MadInput(
                          controller: _rateController,
                          labelText: 'Rate',
                          hintText: '0.00',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: MadButton(
                        text: 'Cancel',
                        variant: ButtonVariant.outline,
                        onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MadButton(
                        text: _saving ? 'Saving...' : 'Add Item',
                        icon: LucideIcons.plus,
                        disabled: _saving,
                        onPressed: _save,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BOQPageState extends State<BOQPage> {
  bool _isLoading = true;
  String? _error;
  List<BOQItem> _items = [];
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  final _searchController = TextEditingController();
  final Set<String> _selectedIds = {};
  bool _bulkDeleting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBOQItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBOQItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final store = StoreProvider.of<AppState>(context);
    final projectId = store.state.project.selectedProjectId ?? '';
    
    if (projectId.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _items = [];
          _error = 'No project selected';
        });
      }
      return;
    }
    
    try {
      final result = await ApiClient.getBOQsByProject(projectId);
      if (!mounted) return;
      if (result['success'] == true) {
        final data = result['data'];
        final List<dynamic> rows;
        if (data is List) {
          rows = data;
        } else if (data is Map && data['boqs'] is List) {
          rows = List<dynamic>.from(data['boqs'] as List);
        } else {
          rows = const [];
        }
        final loaded = rows
            .whereType<Map>()
            .map((e) => BOQItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        setState(() {
          _items = loaded;
          _isLoading = false;
          _selectedIds.removeWhere(
            (id) => !_items.any((item) => item.id == id),
          );
        });
      } else {
        setState(() {
          _items = [];
          _isLoading = false;
          _error = result['error']?.toString() ?? 'Failed to load BOQ items';
        });
      }
    } catch (e) {
      debugPrint('[BOQ] API error: $e');
      if (!mounted) return;
      setState(() {
        _items = [];
        _isLoading = false;
        _error = 'Failed to load BOQ items';
      });
    }
  }

  List<BOQItem> get _filteredItems {
    if (_searchQuery.isEmpty) return _items;
    final query = _searchQuery.toLowerCase();
    return _items.where((item) {
      return item.description.toLowerCase().contains(query) ||
          (item.itemCode?.toLowerCase().contains(query) ?? false) ||
          item.category.toLowerCase().contains(query);
    }).toList();
  }

  List<BOQItem> get _paginatedItems {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;
    final filtered = _filteredItems;
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end > filtered.length ? filtered.length : end);
  }

  int get _totalPages => (_filteredItems.length / _itemsPerPage).ceil();

  double get _totalAmount => _filteredItems.fold<double>(
        0,
        (sum, item) => sum + (item.amount ?? (item.quantity * (item.rate ?? 0))),
      );

  bool get _hasSelection => _selectedIds.isNotEmpty;

  bool get _isPageFullySelected {
    if (_paginatedItems.isEmpty) return false;
    return _paginatedItems.every((item) => _selectedIds.contains(item.id));
  }

  bool get _isPagePartiallySelected {
    if (_paginatedItems.isEmpty) return false;
    final anySelected = _paginatedItems.any((item) => _selectedIds.contains(item.id));
    return anySelected && !_isPageFullySelected;
  }

  void _toggleItemSelection(String id, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
    });
  }

  void _togglePageSelection(bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.addAll(_paginatedItems.map((item) => item.id));
      } else {
        for (final item in _paginatedItems) {
          _selectedIds.remove(item.id);
        }
      }
    });
  }

  Future<void> _confirmDeleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete selected BOQ items'),
        content: Text(
          'Delete $count selected item(s)? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _deleteSelected();
  }

  Future<void> _deleteSelected() async {
    if (_bulkDeleting || _selectedIds.isEmpty) return;
    setState(() => _bulkDeleting = true);
    int deleted = 0;
    int failed = 0;
    final ids = _selectedIds.toList();

    for (final id in ids) {
      final result = await ApiClient.deleteBOQ(id);
      if (result['success'] == true) {
        deleted++;
      } else {
        failed++;
      }
    }

    if (!mounted) return;
    setState(() {
      _bulkDeleting = false;
      _selectedIds.clear();
    });
    await _loadBOQItems();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failed > 0
              ? '$deleted deleted, $failed failed.'
              : '$deleted item(s) deleted.',
        ),
        backgroundColor: failed > 0 ? Colors.red : null,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final responsive = Responsive(context);
    final selectedProjectId = StoreProvider.of<AppState>(context).state.project.selectedProjectId ?? '';
    final hasProjectSelected = selectedProjectId.isNotEmpty;

    return ProtectedRoute(
      title: 'BOQ Management',
      route: '/boq',
      child: SingleChildScrollView(
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
                      'BOQ Management',
                      style: TextStyle(
                        fontSize: responsive.value(mobile: 22, tablet: 26, desktop: 28),
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage Bill of Quantities for projects.',
                      style: TextStyle(
                        color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 24),
          _buildQuickActions(isDark, responsive, hasProjectSelected),
          const SizedBox(height: 16),

          // Responsive, swipeable table
          _isLoading
              ? MadCard(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: MadTableSkeleton(rows: 8, columns: 8),
                  ),
                )
              : _error != null
                  ? _buildErrorState(isDark, _error!)
                  : _filteredItems.isEmpty
                      ? _buildEmptyState(isDark, hasProjectSelected)
                      : _buildResponsiveTable(isDark, responsive),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isDark, Responsive responsive, bool hasProjectSelected) {
    final isMobile = responsive.isMobile;
    final buttons = [
      MadButton(
        text: 'Import BOQ PDF',
        icon: LucideIcons.fileUp,
        variant: ButtonVariant.outline,
        onPressed: _importFromPdf,
      ),
      MadButton(
        text: 'Export',
        icon: LucideIcons.download,
        variant: ButtonVariant.outline,
        onPressed: _showExportOptionsSheet,
      ),
      MadButton(
        text: 'Add Item',
        icon: LucideIcons.plus,
        disabled: !hasProjectSelected,
        onPressed: hasProjectSelected ? _openAddItemPage : null,
      ),
      MadButton(
        text: _hasSelection
            ? 'Delete Selected (${_selectedIds.length})'
            : 'Delete Selected',
        icon: LucideIcons.trash2,
        variant: ButtonVariant.destructive,
        disabled: !hasProjectSelected || !_hasSelection || _bulkDeleting,
        onPressed: _confirmDeleteSelected,
      ),
      MadButton(
        text: _isLoading ? 'Loading…' : 'Refresh',
        icon: LucideIcons.refreshCw,
        variant: ButtonVariant.outline,
        disabled: _isLoading,
        onPressed: _loadBOQItems,
      ),
    ];

    return MadCard(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 14),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final button in buttons) ...[
                    SizedBox(
                      width: double.infinity,
                      child: button,
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              )
            : Wrap(
                spacing: 10,
                runSpacing: 10,
                children: buttons,
              ),
      ),
    );
  }

  

  void _showExportOptionsSheet() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Export PDF'),
              onTap: () {
                Navigator.pop(sheetContext);
                _exportToPdf();
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('Export Excel'),
              onTap: () {
                Navigator.pop(sheetContext);
                _exportToExcel();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveTable(bool isDark, Responsive responsive) {
    final isMobile = responsive.isMobile;
    const checkboxWidth = 48.0;
    const categoryWidth = 140.0;
    const itemCodeWidth = 120.0;
    const descriptionWidth = 320.0;
    const floorWidth = 110.0;
    const unitWidth = 90.0;
    const qtyWidth = 110.0;
    const rateWidth = 130.0;
    const amountWidth = 140.0;
    const actionsWidth = 80.0;
    const horizontalCellPadding = 24.0; // 12 left + 12 right in header/rows/total rows
    const tableWidth = checkboxWidth +
        categoryWidth +
        itemCodeWidth +
        descriptionWidth +
        floorWidth +
        unitWidth +
        qtyWidth +
        rateWidth +
        amountWidth +
        actionsWidth +
        horizontalCellPadding;

    return MadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isMobile) ...[
                  Text(
                    'BOQ Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.darkForeground
                          : AppTheme.lightForeground,
                    ),
                  ),
                  const SizedBox(height: 10),
                  MadSearchInput(
                    controller: _searchController,
                    hintText: 'Search by section, code, description...',
                    onChanged: (value) => setState(() {
                      _searchQuery = value;
                      _currentPage = 1;
                    }),
                    onClear: () => setState(() {
                      _searchQuery = '';
                      _currentPage = 1;
                    }),
                  ),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'BOQ Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppTheme.darkForeground
                                : AppTheme.lightForeground,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 280,
                        child: MadSearchInput(
                          controller: _searchController,
                          hintText: 'Search by section, code, description...',
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
                    ],
                  ),
                if (_searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Showing ${_filteredItems.length} of ${_items.length} item(s)',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkMutedForeground
                          : AppTheme.lightMutedForeground,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: (isDark ? AppTheme.darkMuted : AppTheme.lightMuted)
                    .withOpacity(0.35),
                border: Border(
                  bottom: BorderSide(
                    color:
                        (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.swipe,
                    size: 16,
                    color: isDark
                        ? AppTheme.darkMutedForeground
                        : AppTheme.lightMutedForeground,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Swipe horizontally to view all columns',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.darkMutedForeground
                            : AppTheme.lightMutedForeground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            height: responsive.value(
              mobile: 420.0,
              tablet: 470.0,
              desktop: 520.0,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Column(
                  children: [
                    _buildTableHeader(isDark),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _paginatedItems.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: (isDark ? Colors.white : Colors.black)
                              .withOpacity(0.06),
                        ),
                        itemBuilder: (context, index) =>
                            _buildTableDataRow(_paginatedItems[index], isDark),
                      ),
                    ),
                    _buildTableTotalRow(isDark),
                  ],
                ),
              ),
            ),
          ),
          if (_totalPages > 1) _buildTablePagination(isDark, isMobile),
        ],
      ),
    );
  }


  Widget _buildTableHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.darkMuted : AppTheme.lightMuted).withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Checkbox(
              value: _isPageFullySelected
                  ? true
                  : _isPagePartiallySelected
                      ? null
                      : false,
              tristate: true,
              onChanged: _paginatedItems.isEmpty
                  ? null
                  : (value) => _togglePageSelection(value == true),
            ),
          ),
          _buildSizedHeaderCell('Section', 140, isDark),
          _buildSizedHeaderCell('Item Code', 120, isDark),
          _buildSizedHeaderCell('Description', 320, isDark),
          _buildSizedHeaderCell('Floor', 110, isDark),
          _buildSizedHeaderCell('Unit', 90, isDark),
          _buildSizedHeaderCell('Quantity', 110, isDark, align: TextAlign.right),
          _buildSizedHeaderCell('Rate (Est.)', 130, isDark, align: TextAlign.right),
          _buildSizedHeaderCell('Amount', 140, isDark, align: TextAlign.right),
          _buildSizedHeaderCell('Action', 80, isDark, align: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSizedHeaderCell(String label, double width, bool isDark, {TextAlign align = TextAlign.left}) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        textAlign: align,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
        ),
      ),
    );
  }

  Widget _buildTableDataRow(BOQItem item, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Checkbox(
              value: _selectedIds.contains(item.id),
              onChanged: (value) =>
                  _toggleItemSelection(item.id, value == true),
            ),
          ),
          SizedBox(
            width: 140,
            child: Align(
              alignment: Alignment.centerLeft,
              child: MadBadge(text: item.category, variant: BadgeVariant.secondary),
            ),
          ),
          _buildSizedValueCell(item.itemCode?.isNotEmpty == true ? item.itemCode! : '-', 120),
          _buildSizedValueCell(item.description, 320, maxLines: 2),
          _buildSizedValueCell(item.floor?.isNotEmpty == true ? item.floor! : '-', 110),
          _buildSizedValueCell(item.unit, 90),
          _buildSizedValueCell(item.quantity.toString(), 110, align: TextAlign.right),
          _buildSizedValueCell('₹${item.rate?.toStringAsFixed(2) ?? '-'}', 130, align: TextAlign.right),
          _buildSizedValueCell('₹${item.amount?.toStringAsFixed(2) ?? '-'}', 140, align: TextAlign.right),
          SizedBox(
            width: 80,
            child: Align(
              alignment: Alignment.center,
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(
                  Icons.more_vert,
                  size: 18,
                  color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditItemDialog(item);
                  } else if (value == 'delete') {
                    _showDeleteConfirmDialog(item);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizedValueCell(String value, double width, {int maxLines = 1, TextAlign align = TextAlign.left}) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        textAlign: align,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTableTotalRow(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.12),
          ),
        ),
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
      ),
      child: Row(
        children: [
          const SizedBox(width: 48),
          const SizedBox(width: 140),
          const SizedBox(width: 120),
          SizedBox(
            width: 320,
            child: Text(
              'Total',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
              ),
            ),
          ),
          const SizedBox(width: 110 + 90 + 110 + 130),
          SizedBox(
            width: 140,
            child: Text(
              '₹${_totalAmount.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
              ),
            ),
          ),
          const SizedBox(width: 80),
        ],
      ),
    );
  }

  Widget _buildTablePagination(bool isDark, bool isMobile) {
    final summary = 'Showing ${(_currentPage - 1) * _itemsPerPage + 1}-'
        '${_currentPage * _itemsPerPage > _filteredItems.length ? _filteredItems.length : _currentPage * _itemsPerPage} '
        'of ${_filteredItems.length}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
          ),
        ),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  summary,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MadButton(
                      icon: LucideIcons.chevronLeft,
                      variant: ButtonVariant.outline,
                      size: ButtonSize.icon,
                      disabled: _currentPage == 1,
                      onPressed: () => setState(() => _currentPage--),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('$_currentPage / $_totalPages', style: const TextStyle(fontSize: 14)),
                    ),
                    MadButton(
                      icon: LucideIcons.chevronRight,
                      variant: ButtonVariant.outline,
                      size: ButtonSize.icon,
                      disabled: _currentPage == _totalPages,
                      onPressed: () => setState(() => _currentPage++),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  summary,
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
                      size: ButtonSize.icon,
                      disabled: _currentPage == 1,
                      onPressed: () => setState(() => _currentPage--),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('$_currentPage of $_totalPages', style: const TextStyle(fontSize: 14)),
                    ),
                    MadButton(
                      icon: LucideIcons.chevronRight,
                      variant: ButtonVariant.outline,
                      size: ButtonSize.icon,
                      disabled: _currentPage == _totalPages,
                      onPressed: () => setState(() => _currentPage++),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(bool isDark, bool hasProjectSelected) {
    String title;
    String subtitle;

    if (!hasProjectSelected) {
      title = 'Select a project to load BOQ items.';
      subtitle = 'Choose a project to view and manage BOQ items.';
    } else if (_searchQuery.isNotEmpty) {
      title = 'No items found matching your search.';
      subtitle = 'Try a different search term.';
    } else {
      title = 'No BOQ items. Import a PDF or add items manually.';
      subtitle = 'Start by importing a BOQ PDF or adding a new item.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.clipboardList,
              size: 64,
              color: (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground).withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty && hasProjectSelected) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MadButton(
                    text: 'Import PDF',
                    icon: LucideIcons.fileUp,
                    variant: ButtonVariant.outline,
                    onPressed: () => _showImportDialog(),
                  ),
                  const SizedBox(width: 12),
                  MadButton(
                    text: 'Add Item',
                    icon: LucideIcons.plus,
                    onPressed: _openAddItemPage,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load BOQ items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            MadButton(
              text: 'Retry',
              icon: LucideIcons.refreshCw,
              onPressed: _loadBOQItems,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToPdf() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items to export')),
      );
      return;
    }

    final store = StoreProvider.of<AppState>(context);
    final projectName = store.state.project.selectedProjectName ?? 'Project';

    try {
      final items = _items.map((item) => {
        'item_code': item.itemCode ?? '',
        'description': item.description,
        'unit': item.unit,
        'quantity': item.quantity,
        'rate': item.rate ?? 0,
        'amount': item.amount ?? 0,
      }).toList();

      final doc = await PdfService.generateBOQReport(
        projectName: projectName,
        items: items,
      );

      await PdfService.sharePdf(doc, 'BOQ_${projectName.replaceAll(' ', '_')}.pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorHandler.getMessage(e))),
      );
    }
  }

  Future<void> _exportToExcel() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items to export')),
      );
      return;
    }

    final store = StoreProvider.of<AppState>(context);
    final projectName = store.state.project.selectedProjectName ?? 'Project';

    try {
      final items = _items.map((item) => {
        'item_code': item.itemCode ?? '',
        'description': item.description,
        'unit': item.unit,
        'quantity': item.quantity,
        'rate': item.rate ?? 0,
        'amount': item.amount ?? 0,
      }).toList();

      final excel = await ExcelService.exportBOQToExcel(
        projectName: projectName,
        items: items,
      );

      await ExcelService.shareExcel(excel, 'BOQ_${projectName.replaceAll(' ', '_')}.xlsx');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorHandler.getMessage(e))),
      );
    }
  }

  Future<void> _importFromExcel() async {
    try {
      final excel = await ExcelService.importExcel();
      if (excel == null) return;

      final items = ExcelService.parseBOQFromExcel(excel);
      if (items == null || items.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid BOQ items found in file')),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${items.length} items')),
      );
      _loadBOQItems();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorHandler.getMessage(e))),
      );
    }
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          title: const Text('Import BOQ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select a file to import BOQ items',
                style: TextStyle(color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _importFromExcel();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Icon(LucideIcons.fileSpreadsheet, size: 32, color: const Color(0xFF22C55E)),
                            const SizedBox(height: 8),
                            const Text('Excel File', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text('.xlsx, .xls', style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _importFromPdf();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Icon(LucideIcons.fileText, size: 32, color: const Color(0xFFEF4444)),
                            const SizedBox(height: 8),
                            const Text('PDF File', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text('.pdf', style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _importFromPdf() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final result = await BOQExtractor.pickAndExtract(context);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (result.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error!), backgroundColor: Colors.red),
        );
        return;
      }

      if (result.items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No BOQ items found in the PDF')),
        );
        return;
      }

      // Show preview dialog
      _showPdfImportPreview(result);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorHandler.getMessage(e)), backgroundColor: Colors.red),
      );
    }
  }

  void _showPdfImportPreview(BOQExtractionResult result) {
    final items = BOQExtractor.mapToTableRows(result.items);
    
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 600),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Import Preview',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${items.length} items found${result.projectName.isNotEmpty ? ' • Project: ${result.projectName}' : ''}',
                            style: TextStyle(
                              fontSize: 13,
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
                // Table
                Expanded(
                  child: SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 24,
                        columns: const [
                          DataColumn(label: Text('Code')),
                          DataColumn(label: Text('Description')),
                          DataColumn(label: Text('Category')),
                          DataColumn(label: Text('Unit')),
                          DataColumn(label: Text('Quantity'), numeric: true),
                        ],
                        rows: items.take(50).map((item) {
                          return DataRow(cells: [
                            DataCell(Text(item['item_code']?.toString() ?? '-')),
                            DataCell(ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 300),
                              child: Text(
                                item['description']?.toString() ?? '-',
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                            DataCell(Text(item['category']?.toString() ?? '-')),
                            DataCell(Text(item['unit']?.toString() ?? '-')),
                            DataCell(Text(item['quantity']?.toString() ?? '0')),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                if (items.length > 50)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Showing first 50 of ${items.length} items',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                      ),
                    ),
                  ),
                // Footer
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      MadButton(
                        text: 'Cancel',
                        variant: ButtonVariant.outline,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      MadButton(
                        text: 'Replace Existing',
                        variant: ButtonVariant.outline,
                        onPressed: () {
                          Navigator.pop(context);
                          _savePdfImport(items, replace: true);
                        },
                      ),
                      const SizedBox(width: 12),
                      MadButton(
                        text: 'Add to BOQ',
                        onPressed: () {
                          Navigator.pop(context);
                          _savePdfImport(items, replace: false);
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

  Future<void> _savePdfImport(List<Map<String, dynamic>> items, {required bool replace}) async {
    final store = StoreProvider.of<AppState>(context);
    final projectId = store.state.project.selectedProjectId ?? '';

    if (projectId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a project first')),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Importing ${items.length} items...'),
            ],
          ),
        ),
      ),
    );

    try {
      // If replace, delete existing items first
      if (replace && _items.isNotEmpty) {
        for (final item in _items) {
          await ApiClient.deleteBOQ(item.id);
        }
      }

      // Create new items
      int successCount = 0;
      for (final item in items) {
        final data = {
          'project_id': projectId,
          'item_code': item['item_code'] ?? '',
          'description': item['description'] ?? '',
          'category': item['category'] ?? 'General',
          'floor': item['floor'] ?? 'All',
          'quantity': (item['quantity'] ?? 0).toString(),
          'unit': item['unit'] ?? 'Nos',
          'rate': (item['rate'] ?? 0).toString(),
          'amount': (item['amount'] ?? 0).toString(),
        };

        final result = await ApiClient.createBOQ(data);
        if (result['success'] == true) {
          successCount++;
        }
      }

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully imported $successCount of ${items.length} items'),
          backgroundColor: Colors.green,
        ),
      );

      _loadBOQItems(); // Refresh list
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorHandler.getMessage(e)), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _openAddItemPage() async {
    final store = StoreProvider.of<AppState>(context);
    final projectId = store.state.project.selectedProjectId ?? '';
    if (projectId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a project first')),
      );
      return;
    }

    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _AddBOQItemPage(projectId: projectId),
      ),
    );

    if (added == true && mounted) {
      _loadBOQItems();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('BOQ item added successfully')),
      );
    }
  }

  void _showEditItemDialog(BOQItem item) {
    final itemCodeController = TextEditingController(text: item.itemCode ?? '');
    final descriptionController = TextEditingController(text: item.description);
    final categoryController = TextEditingController(text: item.category);
    final quantityController = TextEditingController(text: item.quantity.toString());
    final unitController = TextEditingController(text: item.unit);
    final rateController = TextEditingController(text: item.rate?.toString() ?? '');
    final floorController = TextEditingController(text: item.floor ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit BOQ Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MadInput(
                controller: itemCodeController,
                labelText: 'Item Code',
                hintText: 'Enter item code',
              ),
              const SizedBox(height: 16),
              MadInput(
                controller: descriptionController,
                labelText: 'Description',
                hintText: 'Enter description',
              ),
              const SizedBox(height: 16),
              MadInput(
                controller: categoryController,
                labelText: 'Category',
                hintText: 'Enter category',
              ),
              const SizedBox(height: 16),
              MadInput(
                controller: floorController,
                labelText: 'Floor',
                hintText: 'Enter floor',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: MadInput(
                      controller: quantityController,
                      labelText: 'Quantity',
                      hintText: '0',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: MadInput(
                      controller: unitController,
                      labelText: 'Unit',
                      hintText: 'e.g. KG',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: MadInput(
                      controller: rateController,
                      labelText: 'Rate',
                      hintText: '0.00',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final quantity = double.tryParse(quantityController.text) ?? 0;
              final rate = double.tryParse(rateController.text) ?? 0;
              final amount = quantity * rate;

              final data = {
                'item_code': itemCodeController.text,
                'description': descriptionController.text,
                'category': categoryController.text,
                'floor': floorController.text,
                'quantity': quantity.toString(),
                'unit': unitController.text,
                'rate': rate.toString(),
                'amount': amount.toString(),
              };

              Navigator.pop(dialogContext);

              final result = await ApiClient.updateBOQ(item.id, data);
              if (!mounted) return;

              if (result['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('BOQ item updated successfully')),
                );
                _loadBOQItems();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ErrorHandler.getMessage(result['error'] ?? 'Failed to update item'))),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BOQItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete BOQ Item'),
        content: Text(
          'Are you sure you want to delete "${item.description}"? This action cannot be undone.',
          style: TextStyle(
            color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final result = await ApiClient.deleteBOQ(item.id);
              if (!mounted) return;
              if (result['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('BOQ item deleted')),
                );
                _loadBOQItems();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ErrorHandler.getMessage(result['error'] ?? 'Failed to delete'))),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
