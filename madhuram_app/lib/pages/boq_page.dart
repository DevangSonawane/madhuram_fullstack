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
import '../components/ui/mad_dropdown_menu.dart';
import '../components/layout/main_layout.dart';

/// BOQ Management page matching React's BOQ.jsx
class BOQPage extends StatefulWidget {
  const BOQPage({super.key});

  @override
  State<BOQPage> createState() => _BOQPageState();
}

class _BOQPageState extends State<BOQPage> {
  bool _isLoading = true;
  List<BOQItem> _items = [];
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  final _searchController = TextEditingController();

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
    final store = StoreProvider.of<AppState>(context);
    final projectId = store.state.project.selectedProjectId ?? '';
    
    if (projectId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    
    final result = await ApiClient.getBOQsByProject(projectId);
    
    if (!mounted) return;
    
    if (result['success'] == true) {
      final data = result['data'] as List;
      setState(() {
        _items = data.map((e) => BOQItem.fromJson(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return ProtectedRoute(
      title: 'BOQ Management',
      route: '/boq',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BOQ Management',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage Bill of Quantities for your project',
                    style: TextStyle(
                      color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                    ),
                  ),
                ],
              ),
              if (!isMobile)
                Row(
                  children: [
                    MadDropdownMenuButton(
                      icon: LucideIcons.download,
                      items: [
                        MadMenuItem(label: 'Export PDF', icon: LucideIcons.fileText, onTap: () => _exportToPdf()),
                        MadMenuItem(label: 'Export Excel', icon: LucideIcons.fileSpreadsheet, onTap: () => _exportToExcel()),
                      ],
                    ),
                    const SizedBox(width: 12),
                    MadButton(
                      text: 'Import',
                      icon: LucideIcons.fileUp,
                      variant: ButtonVariant.outline,
                      onPressed: () => _showImportDialog(),
                    ),
                    const SizedBox(width: 12),
                    MadButton(
                      text: 'Add Item',
                      icon: LucideIcons.plus,
                      onPressed: () => _showAddItemDialog(),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Search and filters
          Row(
            children: [
              Expanded(
                child: MadSearchInput(
                  controller: _searchController,
                  hintText: 'Search BOQ items...',
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
              if (isMobile) ...[
                const SizedBox(width: 12),
                MadButton(
                  icon: LucideIcons.plus,
                  onPressed: () => _showAddItemDialog(),
                  size: ButtonSize.icon,
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // Data table
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredItems.isEmpty
                  ? _buildEmptyState(isDark)
                  : MadCard(
                      child: Column(
                        children: [
                          // Table header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                _buildHeaderCell('Item Code', flex: 1, isDark: isDark),
                                _buildHeaderCell('Description', flex: 3, isDark: isDark),
                                if (!isMobile) ...[
                                  _buildHeaderCell('Category', flex: 1, isDark: isDark),
                                  _buildHeaderCell('Unit', flex: 1, isDark: isDark),
                                  _buildHeaderCell('Quantity', flex: 1, isDark: isDark),
                                  _buildHeaderCell('Rate', flex: 1, isDark: isDark),
                                  _buildHeaderCell('Amount', flex: 1, isDark: isDark),
                                ],
                                const SizedBox(width: 48),
                              ],
                            ),
                          ),
                          // Table rows
                          ..._paginatedItems.map((item) => _buildTableRow(item, isDark, isMobile)),
                          // Pagination
                          if (_totalPages > 1)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Showing ${(_currentPage - 1) * _itemsPerPage + 1}-${_currentPage * _itemsPerPage > _filteredItems.length ? _filteredItems.length : _currentPage * _itemsPerPage} of ${_filteredItems.length}',
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
                                        child: Text(
                                          '$_currentPage of $_totalPages',
                                          style: const TextStyle(fontSize: 14),
                                        ),
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
                            ),
                        ],
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

  Widget _buildTableRow(BOQItem item, bool isDark, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              item.itemCode ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(item.description),
          ),
          if (!isMobile) ...[
            Expanded(
              flex: 1,
              child: MadBadge(
                text: item.category,
                variant: BadgeVariant.secondary,
              ),
            ),
            Expanded(flex: 1, child: Text(item.unit)),
            Expanded(flex: 1, child: Text(item.quantity.toString())),
            Expanded(flex: 1, child: Text('₹${item.rate?.toStringAsFixed(2) ?? '-'}')),
            Expanded(flex: 1, child: Text('₹${item.amount?.toStringAsFixed(2) ?? '-'}')),
          ],
          PopupMenuButton<String>(
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
                // Edit logic
              } else if (value == 'delete') {
                // Delete logic
              }
            },
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
              LucideIcons.clipboardList,
              size: 64,
              color: (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground).withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty ? 'No BOQ items yet' : 'No items found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Add items manually or import from a PDF'
                  : 'Try a different search term',
              style: TextStyle(
                color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
              ),
            ),
            if (_searchQuery.isEmpty) ...[
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
                    onPressed: () => _showAddItemDialog(),
                  ),
                ],
              ),
            ],
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
        SnackBar(content: Text('Error exporting PDF: $e')),
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
        SnackBar(content: Text('Error exporting Excel: $e')),
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
        SnackBar(content: Text('Error importing: $e')),
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
      final result = await BOQExtractor.pickAndExtract();
      
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
        SnackBar(content: Text('Error importing PDF: $e'), backgroundColor: Colors.red),
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
        SnackBar(content: Text('Error saving items: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAddItemDialog() {
    final itemCodeController = TextEditingController();
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController();
    final quantityController = TextEditingController();
    final unitController = TextEditingController();
    final rateController = TextEditingController();
    final floorController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add BOQ Item'),
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
              final store = StoreProvider.of<AppState>(context);
              final projectId = store.state.project.selectedProjectId ?? '';
              
              final quantity = double.tryParse(quantityController.text) ?? 0;
              final rate = double.tryParse(rateController.text) ?? 0;
              final amount = quantity * rate;

              final data = {
                'project_id': projectId,
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

              final result = await ApiClient.createBOQ(data);
              if (!mounted) return;

              if (result['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('BOQ item added successfully')),
                );
                _loadBOQItems();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${result['error'] ?? 'Failed to add item'}')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
